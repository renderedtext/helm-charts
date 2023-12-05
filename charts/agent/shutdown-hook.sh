# TODO: we should handle the case where multiple pods are trying
# to update the replica count of the deployment at the same time.
# IDEA: we can an annotation in the deployment as a lock, and use a retry mechanism here.

if [[ $SEMAPHORE_AGENT_SHUTDOWN_REASON == "IDLE" ]]; then
  KUBERNETES_DEPLOYMENT_NAME=$(kubectl get -n $KUBERNETES_NAMESPACE pod/$KUBERNETES_POD_NAME -o jsonpath='{.metadata.labels.app\.kubernetes\.io/name}')
  echo "Found deployment: $KUBERNETES_DEPLOYMENT_NAME"
  KUBERNETES_DEPLOYMENT_REPLICAS=$(kubectl get -n $KUBERNETES_NAMESPACE deployment/$KUBERNETES_DEPLOYMENT_NAME -o jsonpath='{.status.replicas}')
  echo "Current replica count: $KUBERNETES_DEPLOYMENT_REPLICAS"
  KUBERNETES_DEPLOYMENT_NEW_REPLICAS=$((KUBERNETES_DEPLOYMENT_REPLICAS - 1))
  echo "New replica count: $KUBERNETES_DEPLOYMENT_NEW_REPLICAS"

  kubectl annotate pod $KUBERNETES_POD_NAME controller.kubernetes.io/pod-deletion-cost=-1
  kubectl scale -n $KUBERNETES_NAMESPACE --replicas=$KUBERNETES_DEPLOYMENT_NEW_REPLICAS deployment/$KUBERNETES_DEPLOYMENT_NAME
fi
