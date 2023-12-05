# TODO: we should handle the case where multiple pods are trying
# to update the replica count of the deployment at the same time.
# IDEA: we can an annotation in the deployment as a lock, and use a retry mechanism here.

if [[ $SEMAPHORE_AGENT_SHUTDOWN_REASON == "IDLE" ]]; then
  KUBERNETES_DEPLOYMENT_NAME=$(kubectl get -o template pod/$KUBERNETES_POD_NAME --template={{.metadata.labels.app}})
  KUBERNETES_DEPLOYMENT_REPLICAS=$(kubectl get -o template deployment/$KUBERNETES_DEPLOYMENT_NAME --template={{.status.replicas}})

  kubectl annotate pod $KUBERNETES_POD_NAME controller.kubernetes.io/pod-deletion-cost=-1
  kubectl scale --replicas=$((KUBERNETES_DEPLOYMENT_REPLICAS - 1)) deployment/$KUBERNETES_DEPLOYMENT_NAME
fi