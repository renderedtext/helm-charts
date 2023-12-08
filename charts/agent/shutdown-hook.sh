# If the agent is shutting down for any other reason other than 'IDLE',
# we don't decrease the deployment's replica count, and just let k8s restart the pod.
if [[ $SEMAPHORE_AGENT_SHUTDOWN_REASON != "IDLE" ]]; then
  echo "Agent disconnected due to $SEMAPHORE_AGENT_SHUTDOWN_REASON - not doing anything."
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
  echo "[$KUBERNETES_POD_NAME | $(date --utc +%FT%T.%3NZ)] : $1"
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

# Exit code 0 -> successful, no need to retry
# Exit code 1 -> failure, retry
# Exit code 2 -> failure, but should not retry
retry_cmd() {
  local __cmd__=$1
  local __result__=0
  local __max_retries__=60
  local __sleep__=1

  for __i__ in $(seq 1 $__max_retries__); do
    __output__=$(eval "$__cmd__")
    __result__="$?"

    if [ $__result__ -eq "0" ]; then
      echo "$__output__"
      return 0
    fi

    if [ $__result__ -eq "2" ]; then
      echo "$__output__"
      exit 2
    fi

    if [[ $__i__ == $__max_retries__ ]]; then
      return $__result__
    else
      __sleep__=$(echo "$(($(shuf -i 1000-3000 -n 1) / 1000))")
      echo "$__output__"
      log "Trying again after $__sleep__..."
      sleep $__sleep__
    fi
  done
}

lock_deployment() {
  output=$(kubectl get \
    -n $KUBERNETES_NAMESPACE \
    -o jsonpath='{.metadata.resourceVersion}{" "}{.metadata.annotations.semaphoreci\.com/handle}' \
    deployment/$KUBERNETES_DEPLOYMENT_NAME 2>&1
  )

  if [ $? != 0 ]; then
    log "Error getting deployment metadata for $KUBERNETES_DEPLOYMENT_NAME: $output"
    return 2
  fi

  annotation_and_version=($output)

  # Two values returned => annotation is already set.
  if [[ ${#annotation_and_version[@]} -eq 2 ]]; then
    log "Deployment $KUBERNETES_DEPLOYMENT_NAME is already locked by '${annotation_and_version[1]}'"
    return 1
  fi

  # Only one value is returned => annotation is not set.
  resource_version=${annotation_and_version[0]}
  log "Deployment $KUBERNETES_DEPLOYMENT_NAME is not locked - acquiring lock with v=$resource_version..."

  output=$(kubectl annotate \
    -n $KUBERNETES_NAMESPACE \
    --resource-version=$resource_version \
    deployment/$KUBERNETES_DEPLOYMENT_NAME \
    semaphoreci.com/handle=$KUBERNETES_POD_NAME 2>&1
  )

  if [ $? -eq 0 ]; then
    log "Deployment $KUBERNETES_DEPLOYMENT_NAME locked."
    return 0
  else
    log "Deployment $KUBERNETES_DEPLOYMENT_NAME could not be annotated - $output."
    return 1
  fi
}

retry_cmd "lock_deployment $KUBERNETES_DEPLOYMENT_NAME $KUBERNETES_POD_NAME"
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
else
  log "Could not lock deployment - giving up."
fi
