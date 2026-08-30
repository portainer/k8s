# Portainer Agent

A Helm chart for deploying Portainer Agent in Kubernetes clusters.

## Introduction

This chart bootstraps a Portainer Agent deployment on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager. The chart uses the official Portainer Agent LTS version (2.27.4) by default.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+

## Installing the Chart

To install the chart with the release name `portainer-agent`:

```bash
helm repo add portainer https://portainer.github.io/k8s/
helm repo update
helm install portainer-agent portainer/portainer-agent --create-namespace -n portainer
```

## Uninstalling the Chart

To uninstall/delete the `portainer-agent` deployment:

```bash
helm uninstall portainer-agent -n portainer
```

## Configuration

The following table lists the configurable parameters of the Portainer Agent chart and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `deploymentMode` | Deployment mode (agent, edge, edge-async) | `"agent"` |
| `replicaCount` | Number of replicas | `1` |
| `image.repository` | Image repository | `"portainer/agent"` |
| `image.pullPolicy` | Image pull policy | `"Always"` |
| `image.tag` | Image tag (use "lts" for latest LTS version) | `"lts"` |
| `service.type` | Service type | `"ClusterIP"` |
| `service.port` | Service port | `9001` |
| `service.nodePort` | Node port (when type is NodePort) | `30775` |
| `serviceAccount.create` | Create service account | `true` |
| `serviceAccount.name` | Service account name | `""` |
| `resources` | Resource limits and requests | `{}` |
| `nodeSelector` | Node selector | `{}` |
| `tolerations` | Tolerations | `[]` |
| `affinity` | Affinity rules | `{}` |
| `podAnnotations` | Pod annotations | `{}` |
| `feature.flags` | Feature flags | `[]` |
| `extraEnv` | Extra environment variables | `[]` |
| `imagePullSecrets` | Image pull secrets | `[]` |

## Deployment Modes

### Agent Mode

Standard Portainer Agent for Kubernetes management:

```bash
helm install portainer-agent portainer/portainer-agent \
  --set deploymentMode=agent \
  --set service.type=NodePort \
  --set service.nodePort=30775 \
  --set image.tag=2.27.4 \
  --create-namespace -n portainer
```

### Edge Mode

Edge Agent for remote environment management:

```bash
helm install portainer-edge portainer/portainer-agent \
  --set deploymentMode=edge \
  --set edge.id="YOUR_EDGE_ID" \
  --set edge.key="YOUR_EDGE_KEY" \
  --set image.tag=2.27.4 \
  --create-namespace -n portainer
```

### Edge-Async Mode

Edge Agent with async communication:

```bash
helm install portainer-edge-async portainer/portainer-agent \
  --set deploymentMode=edge-async \
  --set edge.id="YOUR_EDGE_ID" \
  --set edge.key="YOUR_EDGE_KEY" \
  --set image.tag=2.27.4 \
  --create-namespace -n portainer
```

## Versioning

This chart follows [Semantic Versioning](https://semver.org/). The chart version is independent of the Portainer Agent version.

- Chart version: `1.0.0`
- Portainer Agent version: `2.27.4` (LTS)

## License

This chart is licensed under the MIT License. 