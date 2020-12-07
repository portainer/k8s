
This repo contains helm and YAML for deploying Portainer into a Kubernetes environment. Follow the applicable instructions for your edition / deployment methodology below:

- [Deploying with Helm](#deploying-with-helm)
  - [Community Edition](#community-edition)
    - [Using NodePort on a local/remote cluster](#using-nodeport-on-a-localremote-cluster)
    - [Using a cloud provider's loadbalancer](#using-a-cloud-providers-loadbalancer)
    - [Using ClusterIP with an ingress](#using-clusterip-with-an-ingress)
  - [Enterprise Edition](#enterprise-edition)
    - [Using NodePort on a local/remote cluster](#using-nodeport-on-a-localremote-cluster-1)
    - [Using a cloud provider's loadbalancer](#using-a-cloud-providers-loadbalancer-1)
    - [Using ClusterIP with an ingress](#using-clusterip-with-an-ingress-1)
- [Deploying with manifests](#deploying-with-manifests)
  - [Community Edition](#community-edition-1)
    - [Using NodePort on a local/remote cluster](#using-nodeport-on-a-localremote-cluster-2)
    - [Using a cloud provider's loadbalancer](#using-a-cloud-providers-loadbalancer-2)
  - [Enterprise Edition](#enterprise-edition-1)
    - [Using NodePort on a local/remote cluster](#using-nodeport-on-a-localremote-cluster-3)
    - [Using a cloud provider's loadbalancer](#using-a-cloud-providers-loadbalancer-3)




# Deploying with Helm

Install the repository:

```
helm repo add portainer https://portainer.github.io/k8s/
helm repo update
```

Create the portainer namespace:

```
kubectl create namespace portainer
```

## Community Edition

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

## Enterprise Edition

### Using NodePort on a local/remote cluster

```
helm install --set enterpriseEdition.enabled=true -n portainer portainer portainer/portainer
```

###  Using a cloud provider's loadbalancer

```
helm install  --set enterpriseEdition.enabled=true -n portainer portainer portainer/portainer --set service.type=LoadBalancer
```


### Using ClusterIP with an ingress

```
helm install  --set enterpriseEdition.enabled=true -n portainer portainer portainer/portainer --set service.type=ClusterIP
```

For advanced helm customization, see the [chart README](/charts/portainer/README.md)

# Deploying with manifests

If you're not into helm, you can install Portainer using manifests, by first creating the portainer namespace:

```
kubectl create namespace portainer
```

And then...

## Community Edition

### Using NodePort on a local/remote cluster

```
kubectl create namespace portainer
kubectl apply -n portainer -f https://raw.githubusercontent.com/portainer/k8s/master/deploy/manifests/portainer/portainer.yaml
```

###  Using a cloud provider's loadbalancer

```
kubectl create namespace portainer
kubectl apply -n portainer -f https://raw.githubusercontent.com/portainer/k8s/master/deploy/manifests/portainer/portainer-lb.yaml
```

## Enterprise Edition

### Using NodePort on a local/remote cluster

```
kubectl create namespace portainer
kubectl apply -n portainer -f https://raw.githubusercontent.com/portainer/k8s/master/deploy/manifests/portainer/portainer-ee.yaml
```

###  Using a cloud provider's loadbalancer

```
kubectl create namespace portainer
kubectl apply -n portainer -f https://raw.githubusercontent.com/portainer/k8s/master/deploy/manifests/portainer/portainer-lb-ee.yaml
```
