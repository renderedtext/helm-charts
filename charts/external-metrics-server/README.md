## Semaphore external metrics server

This is a Helm chart to install the [metrics server](https://github.com/renderedtext/k8s-metrics-apiserver) to expose the self-hosted agent types metrics through a Kubernetes external metrics server.

### Installation

```bash
helm install semaphore-metrics-server charts/external-metrics-server \
  --namespace semaphore \
  --create-namespace
```
