Installs an [external metrics server](https://github.com/renderedtext/k8s-metrics-apiserver) that exposes self-hosted agent types metrics through the Kubernetes external metrics API.

### Installation

```bash
helm repo add renderedtext https://renderedtext.github.io/helm-charts
helm install semaphore-metrics-server renderedtext/external-metrics-server \
  --namespace semaphore \
  --create-namespace
```
