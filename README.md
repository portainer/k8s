# Portainer Kubernetes Deployment

This repo contains helm and YAML (yuch) for deploying Portainer into a Kubernetes environment


## Quickstart with Helm

Install the repository:

```
helm repo add portainer https://portainer.github.io/k8s/
helm repo update
```

Create the portainer namespace:

```
kubectl create namespace portainer
```

Install the helm chart:

### Using NodePort on a local/remote cluster

```
helm install -n portainer portainer portainer/portainer
```

###  Using a cloud provider's loadbalancer

```
helm install -n portainer portainer portainer/portainer --set service.type=LoadBalancer
```


### Using ClusterIP with an ingress

```
helm install -n portainer portainer portainer/portainer --set service.type=ClusterIP
```

For advanced helm customization, see the [chart README](/charts/portainer/README.md)

## Quickstart with manifests

If you're not into helm, you can install Portainer using manifests, by first creating the portainer namespace:

```
kubectl create namespace portainer
```

And then...

### Using NodePort on a local/remote cluster

```
kubectl create namespace portainer
kubectl apply -n portainer -f https://portainer.github.io/k8s//deploy/manifests/portainer/portainer.yaml
```

###  Using a cloud provider's loadbalancer

```
kubectl create namespace portainer
kubectl apply -n portainer -f https://portainer.github.io/k8s//deploy/manifests/portainer/portainer-lb.yaml
```