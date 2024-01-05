Run Semaphore jobs for one or multiple [Semaphore agent type](https://github.com/semaphoreci/agent) pools in a Kubernetes cluster.

- [Installation](#installation)
- [Start jobs for an agent type](#start-jobs-for-an-agent-type)
- [Using multiple agent types](#using-multiple-agent-types)
- [Default pod spec](#default-pod-spec)
  - [The pre-job hook](#the-pre-job-hook)
  - [Disabling the pre-job hook](#disabling-the-pre-job-hook)
  - [Using a custom pre-job hook](#using-a-custom-pre-job-hook)
  - [Do not specify a default pod spec](#do-not-specify-a-default-pod-spec)
  - [Overriding the default pod spec values](#overriding-the-default-pod-spec-values)
  - [Overriding the default pod spec for a single agent type](#overriding-the-default-pod-spec-for-a-single-agent-type)
- [Logging](#logging)
- [Configuration](#configuration)

## Installation

Using the Semaphore API token, install the chart:

```bash
helm upgrade --install semaphore-controller charts/controller \
  --namespace semaphore \
  --create-namespace \
  --set endpoint=<your-organization>.semaphoreci.com \
  --set apiToken=<your-api-token>
```

## Start jobs for an agent type

The controller automatically detects which agent types to monitor by looking at the secrets available in the namespace it is running on. To start monitoring the queue and creating jobs for an agent type, you need to create a Kubernetes secret with the necessary information for the controller to spin new agents for that agent type.

You can follow the guide [here](https://docs.semaphoreci.com/ci-cd-environment/self-hosted-agent-types/) to create an agent type. After doing so, you can start creating jobs for it by creating a secret like this:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-semaphore-agent-type
  namespace: semaphore
  labels:
    semaphoreci.com/resource-type: agent-type-configuration
stringData:
  agentTypeName: s1-my-agent-type
  registrationToken: <agent-type-registration-token>
```

Notice the `semaphoreci.com/resource-type=agent-type-configuration` label. That's how the controller knows this secret has the information needed to start agents for a Semaphore agent type.

## Using multiple agent types

You can start jobs for as many agent types you want. Just be aware that the controller will respect the `parallelism` settings and will not create more than the amount of jobs specified in that settings, for all the agent types you have.

## Default pod spec

The controller is responsible for starting Semaphore agents to run the jobs that appear in the queue for your agent type. Each Semaphore agent that starts will itself create a new pod to run the job that it is assigned. The agent configures that pod configured using a [pod spec](https://github.com/semaphoreci/agent/blob/master/docs/kubernetes-executor.md#--kubernetes-pod-spec) decorator.

This chart provides a default pod spec that the controller will use for all agent types that do not specify it themselves.

### The pre-job hook

By default, the controller's default pod spec includes a pre-job hook used to install the Semaphore toolbox at the beginning of every job.

> [!TIP]
> Pre-installing the Semaphore toolbox (and any other required tools for your builds) in the images used during the jobs is a good way to avoid wasting job running time to install dependencies.

### Disabling the pre-job hook

If you do not want to use the default pre-job hook, you can disable it with the `agent.defaultPodSpec.preJobHook.enabled` value:

```bash
helm upgrade --install semaphore-controller charts/controller \
  --namespace semaphore \
  --create-namespace \
  --set endpoint=<your-organization>.semaphoreci.com \
  --set apiToken=<your-api-token> \
  --set agent.defaultPodSpec.preJobHook.enabled=false
```

### Using a custom pre-job hook

If the default pre-job hook does not fit your needs, you can use a custom one with the `agent.defaultPodSpec.preJobHook.customScript` value:

```bash
helm upgrade --install semaphore-controller charts/controller \
  --namespace semaphore \
  --create-namespace \
  --set endpoint=<your-organization>.semaphoreci.com \
  --set apiToken=<your-api-token> \
  --set agent.defaultPodSpec.preJobHook.customScript=$(cat my-custom-script.sh | base64)
```

### Do not specify a default pod spec

If you do not want to have a default pod spec for your agent types, you can disable it with:

```bash
helm upgrade --install semaphore-controller charts/controller \
  --namespace semaphore \
  --create-namespace \
  --set endpoint=<your-organization>.semaphoreci.com \
  --set apiToken=<your-api-token> \
  --set agent.defaultPodSpec.enabled=false
```

### Overriding the default pod spec values

You can also configure the pod, main container and sidecar containers for the default controller's pod spec, specifying the `agent.defaultPodSpec.pod`, `agent.defaultPodSpec.mainContainer` and `agent.defaultPodSpec.sidecarContainers` parameters.

For example, if you have a `custom-values.yml` file like this:

```yaml
endpoint: <your-organization>.semaphoreci.com
apiToken: <your-api-token>
agent:
  defaultPodSpec:
    mainContainer:
      env:
        - name: FOO_1
          value: BAR_1
        - name: FOO_2
          value: BAR_2
```

You can expose `FOO_1` and `FOO_2` environment variables to all Semaphore jobs. To install it:

```bash
helm upgrade --install semaphore-controller charts/controller \
  --namespace semaphore \
  --create-namespace \
  -f custom-values.yml
```

### Overriding the default pod spec for a single agent type

You might need to configure the pods to run the Semaphore jobs differently depending on the agent type. You can do that by specifying a `agentStartupParameters` field in your agent type secret.

For example, if you want to use a different pod spec only for an agent type `s1-my-agent-type-2`, you can do so by specifying the `agentStartupParameters` in the agent type secret:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: custom-pre-job-hook-for-my-agent-type-1
  namespace: semaphore
stringData:
  pre-job-hook: |-
    echo "hello from custom pre-job hook script"
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-agent-type-2-pod-spec
  namespace: semaphore
data:
  pod: |-
    volumes:
    - name: pre-job-hook
      secret:
        secretName: custom-pre-job-hook-for-my-agent-type-1
        defaultMode: 0644
        items:
        - key: pre-job-hook
          path: pre-job-hook
  mainContainer: |-
    env:
    - name: FOO_1
      value: DIFFERENT_VALUE_1
    - name: FOO_2
      value: DIFFERENT_VALUE_2
    resources:
      limits:
        cpu: "0.5"
        memory: 500Mi
      requests:
        cpu: "0.25"
        memory: 250Mi
    volumeMounts:
      - name: pre-job-hook
        mountPath: /opt/semaphore/hooks
        readOnly: true
---
apiVersion: v1
kind: Secret
metadata:
  name: my-semaphore-agent-type-2
  namespace: semaphore
  labels:
    semaphoreci.com/resource-type: agent-type-configuration
stringData:
  agentTypeName: s1-my-agent-type-2
  registrationToken: <registration-token>
  agentStartupParameters: |-
    "--kubernetes-pod-spec my-agent-type-2-pod-spec --pre-job-hook-path /opt/semaphore/hooks/pre-job-hook"
```

## Logging

Since agent pods are deleted by the controller when the job finishes, it is recommended to configure your Kubernetes cluster to stream the agent pod logs to an external place, to help with troubleshooting, if needed. [This guide](https://kubernetes.io/docs/concepts/cluster-administration/logging/#cluster-level-logging-architectures) describes the usual strategies to accomplish that.

## Configuration

All the available configuration values can be seen with `helm show values renderedtext/controller`.
