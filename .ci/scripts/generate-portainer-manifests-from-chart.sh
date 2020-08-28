#!/bin/bash
#
# What is this?
# -------------
# This handy little script will generate kubernetes YAML manifests from the portainer
# helm chart. It's intended to be used to prepare up-to-date manifests for users who prefer _not_
# to use helm.
# 
# How does it work?
# -----------------
# At a high level, we run helm in --dry-run mode, which causes the manifests to be rendered, but displayed
# to stdout instead of applied to Kubernetes.
# Then we perform certain transformations on these rendered manifests:
# 1. Remove the rendered NOTES
# 2. Remove the header produced by helf --dry-run
# 3. Remove references to helm in rendered manifests (no point attaching a label like "app.kubernetes.io/managed-by: Helm" if we are not!)

helm install --no-hooks --namespace zorgburger --set disableTest=true --dry-run zorgburger charts/portainer \
| sed -n '1,/NOTES/p' | sed \$d \
| grep -vE 'NAME|LAST DEPLOYED|NAMESPACE|STATUS|REVISION|HOOKS|MANIFEST|TEST SUITE' \
| grep -iv helm \
| sed 's/zorgburger/portainer/' \
| sed 's/portainer-portainer/portainer/' \
> deploy/manifests/portainer/portainer.yaml

helm install --no-hooks --namespace zorgburger --set service.type=LoadBalancer --set disableTest=true --dry-run zorgburger charts/portainer \
| sed -n '1,/NOTES/p' | sed \$d \
| grep -vE 'NAME|LAST DEPLOYED|NAMESPACE|STATUS|REVISION|HOOKS|MANIFEST|TEST SUITE' \
| grep -iv helm \
| sed 's/zorgburger/portainer/' \
| sed 's/portainer-portainer/portainer/' \
> deploy/manifests/portainer/portainer-lb.yaml