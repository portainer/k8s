
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
- [Database Encryption](#database-encryption)
- [Note re persisting data](#note-re-persisting-data)




# Deploying with Helm

Ensure you're using at least helm v3.2, which [includes support](https://github.com/helm/helm/pull/7648) for the `--create-namespace` argument.

Install the repository:

```
helm repo add portainer https://portainer.github.io/k8s/
helm repo update
```

## Community Edition

Install the helm chart:

### Using NodePort on a local/remote cluster

```
helm install --create-namespace -n portainer portainer portainer/portainer
```

###  Using a cloud provider's loadbalancer

```
helm install --create-namespace -n portainer portainer portainer/portainer \
--set service.type=LoadBalancer
```


### Using ClusterIP with an ingress

```
helm install --create-namespace -n portainer portainer portainer/portainer \
--set service.type=ClusterIP
```

For advanced helm customization, see the [chart README](/charts/portainer/README.md)

## Enterprise Edition

### Using NodePort on a local/remote cluster

```
helm install --create-namespace -n portainer portainer portainer/portainer \
--set enterpriseEdition.enabled=true 
```

###  Using a cloud provider's loadbalancer

```
helm install --create-namespace -n portainer portainer portainer/portainer \
--set enterpriseEdition.enabled=true  \
--set service.type=LoadBalancer
```


### Using ClusterIP with an ingress

```
helm install --create-namespace -n portainer portainer portainer/portainer \
--set enterpriseEdition.enabled=true \
--set service.type=ClusterIP
```

For advanced helm customization, see the [chart README](/charts/portainer/README.md)

# Deploying with manifests

If you're not using helm, you can install Portainer using manifests directly, as follows

## Community Edition

### Using NodePort on a local/remote cluster

```
kubectl apply -f https://raw.githubusercontent.com/portainer/k8s/master/deploy/manifests/portainer/portainer.yaml
```

###  Using a cloud provider's loadbalancer

```
kubectl apply -f https://raw.githubusercontent.com/portainer/k8s/master/deploy/manifests/portainer/portainer-lb.yaml
```

## Enterprise Edition

### Using NodePort on a local/remote cluster

```
kubectl apply- f https://raw.githubusercontent.com/portainer/k8s/master/deploy/manifests/portainer/portainer-ee.yaml
```

###  Using a cloud provider's loadbalancer

```
kubectl apply -f https://raw.githubusercontent.com/portainer/k8s/master/deploy/manifests/portainer/portainer-lb-ee.yaml
```

# Database Encryption

Portainer supports encrypting its internal database at rest using a key you provide. This feature requires chart version **2.39.0** or later.

> **⚠️ This is a non-reversible change.** Once Portainer starts with encryption enabled the database will be encrypted and cannot be decrypted without the original key. Rolling back to a chart version older than 2.39.0 is not supported after encryption has been enabled.

> **⚠️ Back up your encryption key externally.** A Kubernetes secret is not a sufficient sole backup. Store the key in a secure external system (e.g. HashiCorp Vault, AWS Secrets Manager, Azure Key Vault) before enabling this feature. If the key is lost, the Portainer database cannot be recovered.

Create the secret in the same namespace as Portainer:

```bash
kubectl create secret generic portainer-key \
  --from-literal=secret=<your-encryption-key> \
  -n portainer
```

Then enable it via Helm:

```bash
helm upgrade -i -n portainer portainer portainer/portainer \
  --set dbEncryption.existingSecret=portainer-key
```

For full details see the [chart README](/charts/portainer/README.md#database-encryption).

# Note re persisting data

The charts/manifests will create a persistent volume for storing Portainer data, using the default StorageClass.

In some Kubernetes clusters (microk8s), the default Storage Class simply creates hostPath volumes, which are not explicitly tied to a particular node. In a multi-node cluster, this can create an issue when the pod is terminated and rescheduled on a different node, "leaving" all the persistent data behind and starting the pod with an "empty" volume.

While this behaviour is inherently a limitation of using hostPath volumes, a suitable workaround is to use add a nodeSelector to the deployment, which effectively "pins" the portainer pod to a particular node.

The nodeSelector can be added in the following ways:

1. Edit your own values.yaml and set the value of nodeSelector like this:

```
nodeSelector:
  kubernetes.io/hostname: <YOUR NODE NAME>
```

2. Explicictly set the target node when deploying/updating the helm chart on the CLI, by including `--set nodeSelector.kubernetes.io/hostname=<YOUR NODE NAME>`
   
3. If you've deployed Portainer via manifests, without Helm, run the following one-liner to "patch" the deployment, forcing the pod to always be scheduled on the node it's currently running on:

```
kubectl patch deployments -n portainer portainer -p '{"spec": {"template": {"spec": {"nodeSelector": {"kubernetes.io/hostname": "'$(kubectl get pods -n portainer -o jsonpath='{ ..nodeName }')'"}}}}}' || (echo Failed to identify current node of portainer pod; exit 1)
```