# If the agent is shutting down for any other reason other than 'IDLE',
# we don't decrease the deployment's replica count, and just let k8s restart the pod.
if [[ $SEMAPHORE_AGENT_SHUTDOWN_REASON != "IDLE" ]]; then
  exit 0
fi

if [[ -z $KUBERNETES_DEPLOYMENT_NAME || -z $KUBERNETES_NAMESPACE || -z $KUBERNETES_POD_NAME || -z $KUBERNETES_DEPLOYMENT_MIN_SIZE ]]; then
  echo "Some environment variables were not specified."
  echo "KUBERNETES_NAMESPACE: $KUBERNETES_NAMESPACE"
  echo "KUBERNETES_DEPLOYMENT_NAME: $KUBERNETES_DEPLOYMENT_NAME"
  echo "KUBERNETES_POD_NAME: $KUBERNETES_POD_NAME"
  echo "KUBERNETES_DEPLOYMENT_MIN_SIZE: $KUBERNETES_DEPLOYMENT_MIN_SIZE"
  exit 1
fi

log() {
  echo "[$(date --utc +%FT%T.%3NZ)] : $1"
}

# We trap the script exit to ensure we always
# release the lock (if needed) after the scripts exits.
on_exit() {
  local __lock_value__=$(kubectl get -n $KUBERNETES_NAMESPACE deployment/$KUBERNETES_DEPLOYMENT_NAME -o jsonpath='{.metadata.annotations.semaphoreci\.com/handle}')
  if [[ "$__lock_value__" == "$KUBERNETES_POD_NAME" ]]; then
    log "Removing lock from deployment $KUBERNETES_DEPLOYMENT_NAME..."
    kubectl annotate -n $KUBERNETES_NAMESPACE deployment/$KUBERNETES_DEPLOYMENT_NAME semaphoreci.com/handle-
  else
    log "Deployment lock ($__lock_value__) does not match $KUBERNETES_POD_NAME."
  fi
}

trap 'on_exit $?' EXIT

# Retry a command for a while, with random sleeps (1-5s) after failures.
retry_cmd() {
  local __cmd__=$1
  local __result__=0
  local __max_retries__=30
  local __sleep__=1

  for __i__ in $(seq 1 $__max_retries__); do
    __output__=$(eval "$__cmd__")
    __result__="$?"

    if [ $__result__ -eq "0" ]; then
      log $__output__
      return 0
    fi

    if [[ $__i__ == $__max_retries__ ]]; then
      return $__result__
    else
      __sleep__=$(echo "$(($(shuf -i 1000-5000 -n 1) / 1000))")
      sleep $__sleep__
    fi
  done
}

# If the agent is idle, we:
# 1. Synchronouly lock the deployment. If another shutdown hook has already locked it, we retry for a while, and eventually give up.
# 2. Annotate the agent pod with a pod deletion cost.
# 3. Decrease the deployment replica count.
# 4. Release the deployment lock.

lock_deployment() {
  retry_cmd "kubectl annotate -n $KUBERNETES_NAMESPACE deployment/$KUBERNETES_DEPLOYMENT_NAME semaphoreci.com/handle=$KUBERNETES_POD_NAME"
  if [ $? -eq 0 ]; then
    log "Deployment locked."
    return 0
  else
    log "Could not lock deployment."
    return 1
  fi
}

lock_deployment $KUBERNETES_DEPLOYMENT_NAME $KUBERNETES_POD_NAME
if [ $? -eq 0 ]; then
  KUBERNETES_DEPLOYMENT_REPLICAS=$(kubectl get -n $KUBERNETES_NAMESPACE deployment/$KUBERNETES_DEPLOYMENT_NAME -o jsonpath='{.status.replicas}')
  log "Current replica count: $KUBERNETES_DEPLOYMENT_REPLICAS"
  KUBERNETES_DEPLOYMENT_NEW_REPLICAS=$((KUBERNETES_DEPLOYMENT_REPLICAS - 1))
  log "New replica count: $KUBERNETES_DEPLOYMENT_NEW_REPLICAS"

  # We don't scale down if we are already at the minimum.
  # However, we still delete the pod.
  # Deleting the pod avoids potentially getting into a 'CrashLoopBackOff' sitation,
  # depending on how long the agent's idle timeout is.
  if [[ "$KUBERNETES_DEPLOYMENT_NEW_REPLICAS" -lt "$KUBERNETES_DEPLOYMENT_MIN_SIZE" ]]; then
    log "New replica count is below minimum allowed - not scaling down."
    kubectl delete -n $KUBERNETES_NAMESPACE pod/$KUBERNETES_POD_NAME --wait=false
    exit 0
  fi

  log "Annotating pod $KUBERNETES_POD_NAME..."
  kubectl annotate pod $KUBERNETES_POD_NAME controller.kubernetes.io/pod-deletion-cost=-1

  log "Scaling down deployment $KUBERNETES_DEPLOYMENT_NAME..."
  kubectl scale -n $KUBERNETES_NAMESPACE --replicas=$KUBERNETES_DEPLOYMENT_NEW_REPLICAS deployment/$KUBERNETES_DEPLOYMENT_NAME
fi
