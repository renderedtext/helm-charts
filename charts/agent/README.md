## Semaphore agent chart

This is a Helm chart to install the [Semaphore agent](https://github.com/semaphoreci/agent) in a Kubernetes cluster.

### Installation

```bash
helm install semaphore-agent charts/agent \
  --namespace semaphore \
  --create-namespace \
  --set agent.endpoint=<your-organization>.semaphoreci.com \
  --set agent.token=<your-agent-type-registration-token>
```

### Autoscaling

By default, the deployment will configure the Semaphore agent deployment to scale up and down, based on the demand for the agent type being used.

It uses the [custom Semaphore metrics server](https://github.com/renderedtext/k8s-metrics-apiserver) to fetch metrics from Semaphore and expose them to the Kubernetes `HorizontalPodAutoscaler`s.

If you don't want the agent deployment to automatically scale, you can disable it:

```
helm install semaphore-agent charts/agent \
  --namespace semaphore \
  --create-namespace \
  --set agent.endpoint=<your-organization>.semaphoreci.com \
  --set agent.token=<your-agent-type-registration-token> \
  --set autoscaling.enabled=false
```
