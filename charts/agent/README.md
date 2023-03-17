Install one or multiple [Semaphore agent](https://github.com/semaphoreci/agent) pools in a Kubernetes cluster.

- [Installation](#installation)
  - [Using multiple agent type pools](#using-multiple-agent-type-pools)
- [Autoscaling](#autoscaling)
  - [Disable autoscaling](#disable-autoscaling)
  - [Configure autoscaling policies](#configure-autoscaling-policies)

## Installation

<b>1. Create a Semaphore self-hosted agent type.</b>

You can follow the guide [here](https://docs.semaphoreci.com/ci-cd-environment/self-hosted-agent-types/).

<b>2. Install chart.</b>

Using the registration token generated for the agent type you created, install the chart:

```bash
helm upgrade --install my-agent-type-pool charts/agent \
  --namespace semaphore \
  --create-namespace \
  --set agent.endpoint=<your-organization>.semaphoreci.com \
  --set agent.token=<your-agent-type-registration-token>
```

### Using multiple agent type pools

You can create multiple agent type pools, by installing the chart multiple times:

```bash
helm upgrade --install my-first-agent-type-pool charts/agent \
  --namespace semaphore \
  --create-namespace \
  --set agent.endpoint=<your-organization>.semaphoreci.com \
  --set agent.token=<my-first-agent-type-pool-token>

helm upgrade --install my-second-agent-type-pool charts/agent \
  --namespace semaphore \
  --create-namespace \
  --set agent.endpoint=<your-organization>.semaphoreci.com \
  --set agent.token=<my-second-agent-type-pool-token>
```

## Autoscaling

By default, the Semaphore agent deployment will scale up and down, based on the metrics exposed by the Semaphore API. It relies on the [custom Semaphore metrics server](https://github.com/renderedtext/k8s-metrics-apiserver) to be installed in the same namespace. You can use the [external-metrics-server](../external-metrics-server) chart to install it on your Kubernetes cluster.

### Disable autoscaling

If you don't want the agent deployment to automatically scale, you can disable it:

```
helm install semaphore-agent charts/agent \
  --namespace semaphore \
  --create-namespace \
  --set agent.endpoint=<your-organization>.semaphoreci.com \
  --set agent.token=<your-agent-type-registration-token> \
  --set autoscaling.enabled=false
```

### Configure autoscaling policies

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
          value: 50
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