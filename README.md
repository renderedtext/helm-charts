# Semaphore Helm charts

## Installation

```bash
helm install semaphore-agent charts/agent \
  --create-namespace \
  --namespace semaphore \
  -f custom-values.yaml
```
