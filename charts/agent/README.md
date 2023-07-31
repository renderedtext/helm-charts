Install one or multiple [Semaphore agent](https://github.com/semaphoreci/agent) pools in a Kubernetes cluster.

- [Installation](#installation)
  - [Using multiple agent type pools](#using-multiple-agent-type-pools)
- [Autoscaling](#autoscaling)
  - [Configure agent pool size](#configure-agent-pool-size)
  - [Disable autoscaling](#disable-autoscaling)
  - [Configure autoscaling policies](#configure-autoscaling-policies)
- [Using a pre-job hook](#using-a-pre-job-hook)
  - [Disabling the pre-job hook](#disabling-the-pre-job-hook)
  - [Using a custom pre-job hook](#using-a-custom-pre-job-hook)

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

### Configure agent pool size

By default, the agent pool will have a minimum of 1 agent and a maximum of 10 agents. However, you can configure it with the `agent.autoscaling.min` and `agent.autoscaling.max` values. For example, to create an agent pool that has between 5 and 25 agents:

```
helm install semaphore-agent charts/agent \
  --namespace semaphore \
  --create-namespace \
  --set agent.endpoint=<your-organization>.semaphoreci.com \
  --set agent.token=<your-agent-type-registration-token> \
  --set agent.autoscaling.min=5 \
  --set agent.autoscaling.max=25
```

### Disable autoscaling

If you don't want the agent deployment to automatically scale, you can disable it with the `agent.autoscaling.enabled` value. Also, if autoscaling is not enabled, the number of agents is configured with the `agent.replicas` value. For example, you can install a static agent pool of 25 agents with the following:

```
helm install semaphore-agent charts/agent \
  --namespace semaphore \
  --create-namespace \
  --set agent.endpoint=<your-organization>.semaphoreci.com \
  --set agent.token=<your-agent-type-registration-token> \
  --set agent.autoscaling.enabled=false \
  --set agent.replicas=25
```

### Configure autoscaling policies

By default, the HPA will behave the following way:
- If jobs are in the queue, the number of agents will be increased by 200% or by 10, whichever is greatest, every 30s.
- If some agents are idle, the number of agents will be decreased by 1, every 5 minutes.

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

## Using a pre-job hook

By default, a pre-job hook is used to install the Semaphore toolbox. However, we recommend pre-installing the Semaphore toolbox (and any other required tools for your builds) in the images used during the jobs, to avoid wasting job running time to install dependencies.

### Disabling the pre-job hook

If you do not want to use the default pre-job hook, you can disable it with the `jobs.preJobHook.enabled` value:

```
helm upgrade --install brand-new-type charts/agent \
  --namespace semaphore \
  --create-namespace \
  --set agent.endpoint=<your-organization>.semaphoreci.com \
  --set agent.token=<your-agent-type-registration-token> \
  --set jobs.preJobHook.enabled=false
```

### Using a custom pre-job hook

If the default pre-job hook does not fit your needs, you can use a custom one with the `jobs.preJobHook.customScript` value:

```
helm upgrade --install brand-new-type charts/agent \
  --namespace semaphore \
  --create-namespace \
  --set agent.endpoint=<your-organization>.semaphoreci.com \
  --set agent.token=<your-agent-type-registration-token> \
  --set jobs.preJobHook.customScript=$(cat my-custom-script.sh | base64)
```
