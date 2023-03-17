## Semaphore agent

Install one or multiple [Semaphore agent](https://github.com/semaphoreci/agent) pools in a Kubernetes cluster.

- [Semaphore agent](#semaphore-agent)
  - [Installation](#installation)
  - [Autoscaling](#autoscaling)
    - [Disabling autoscaling](#disabling-autoscaling)
    - [Configuring autoscaling policies](#configuring-autoscaling-policies)

### Installation

```bash
helm upgrade --install semaphore-agent charts/agent \
  --namespace semaphore \
  --create-namespace \
  --set agent.endpoint=<your-organization>.semaphoreci.com \
  --set agent.token=<your-agent-type-registration-token>
```

### Autoscaling

By default, the Semaphore agent deployment will scale up and down, based on the metrics exposed by the Semaphore API. It relies on the [custom Semaphore metrics server](https://github.com/renderedtext/k8s-metrics-apiserver) to be installed in the same namespace.

#### Disabling autoscaling

If you don't want the agent deployment to automatically scale, you can disable it:

```
helm install semaphore-agent charts/agent \
  --namespace semaphore \
  --create-namespace \
  --set agent.endpoint=<your-organization>.semaphoreci.com \
  --set agent.token=<your-agent-type-registration-token> \
  --set autoscaling.enabled=false
```

#### Configuring autoscaling policies

By default, the HPA will behave the following way:
- When scaling up, the number of agents will be either doubled, or increased by 2, whichever is greatest, every 30s.
- When scaling down, the number of agents will be decreased by 1, every 60s.

However, you can configure both behaviors by overriding the default values. For example, here's an example `values.yml` to override the default behaviors:

```yaml
agent:
  endpoint: "..."
  token: "..."
  autoscaling:

    # The number of agents will be either increased by 50%, or increased by 5,
    # whichever is greatest, every 60s.
    scaleUp:
      selectPolicy: Max
      stabilizationWindowSeconds: 60
      policies:
        - type: Pods
          value: 5
          periodSeconds: 60
        - type: Percent
          value: 5
          periodSeconds: 60

    # The number of agents will be decreased by 25%, every 120s.
    scaleDown:
      selectPolicy: Max
      stabilizationWindowSeconds: 60
      policies:
        - type: Percent
          value: 25
          periodSeconds: 120
```

You can apply that when installing/upgrading the agent installation:

```bash
helm upgrade --install semaphore-agent charts/agent \
  --namespace semaphore \
  --create-namespace \
  -f values.yml
```