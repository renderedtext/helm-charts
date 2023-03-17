Installs an [external metrics server](https://github.com/renderedtext/k8s-metrics-apiserver) that exposes self-hosted agent types metrics through the Kubernetes external metrics API.

### Installation

```bash
helm install semaphore-metrics-server charts/external-metrics-server \
  --namespace semaphore \
  --create-namespace
```
