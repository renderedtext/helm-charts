# Semaphore Helm charts

Helm repository for Semaphore charts. The current charts available are:
- [Semaphore controller](./charts/controller/)
- (*deprecated*) [Semaphore agent](./charts/agent/)
- (*deprecated*) [External metrics server](./charts/external-metrics-server/)

## Usage

[Helm]([documentation](https://helm.sh/docs/)) must be available to use the charts. Once Helm is available, add the repo with:

```
helm repo add renderedtext https://renderedtext.github.io/helm-charts
```

You can use `helm search repo renderedtext` to see the charts.
