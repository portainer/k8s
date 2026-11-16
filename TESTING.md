# Testing the Portainer Helm Chart

This document explains how to run the chart tests locally before opening a pull request.

## Prerequisites

| Tool | Version | Install |
|---|---|---|
| Helm | v3.10+ | https://helm.sh/docs/intro/install/ |
| kube-score | 1.10+ | https://github.com/zegl/kube-score/releases |
| chart-testing (ct) | v3.10+ | https://github.com/helm/chart-testing/releases |
| kind | v0.26+ | https://kind.sigs.k8s.io/docs/user/quick-start/#installation |
| kubectl | any recent | https://kubernetes.io/docs/tasks/tools/ |

---

## 1. Lint

Checks YAML formatting, chart structure, and schema validity.

```bash
# Helm lint
helm lint charts/portainer

# chart-testing lint (stricter, uses .ci/lint-config.yaml rules)
ct lint --config .ci/ct-config.yaml
```

---

## 2. Kube-score

Validates the rendered manifests against Kubernetes best practices.

```bash
# Download kube-score if you don't have it
wget https://github.com/zegl/kube-score/releases/download/v1.10.0/kube-score_1.10.0_linux_amd64 -O kube-score
chmod 755 kube-score

# Run against the chart
helm template charts/* | ./kube-score score - \
  --ignore-test pod-networkpolicy \
  --ignore-test deployment-has-poddisruptionbudget \
  --ignore-test deployment-has-host-podantiaffinity \
  --ignore-test container-security-context \
  --ignore-test container-resources \
  --ignore-test pod-probes \
  --ignore-test container-image-tag \
  --enable-optional-test container-security-context-privileged
```

---

## 3. Template tests

Renders the chart with specific values and asserts the output is correct. No cluster
needed — runs in seconds.

```bash
# Render with default values and inspect
helm template portainer charts/portainer

# Render a specific feature and check the output
helm template portainer charts/portainer --set tls.force=true
helm template portainer charts/portainer --set adminPassword.existingSecret=my-secret
helm template portainer charts/portainer --set enterpriseEdition.enabled=true
```

The CI runs a full set of assertions automatically. To replicate the CI checks locally,
run the workflow script inline — copy the `run: |` block from the
`Run template tests` step in `.github/workflows/on-push-lint-charts.yml` into your
terminal with `CHART=charts/portainer`.

---

## 4. Kind cluster install test

Installs the chart into a real (local) Kubernetes cluster using
[kind](https://kind.sigs.k8s.io/) and verifies pods reach `Ready`.

```bash
# Create a kind cluster
kind create cluster --name portainer-test

# Run chart-testing install (tests default values + all files under charts/portainer/ci/)
ct install --config .ci/ct-config.yaml

# Clean up
kind delete cluster --name portainer-test
```

`ct install` runs a separate install for each file in `charts/portainer/ci/`:

| File | What it tests |
|---|---|
| `ci/default-values.yaml` | Default NodePort install |
| `ci/clusterip-values.yaml` | ClusterIP service (typical ingress setup) |

Each install creates a temporary namespace, waits for all pods to be `Ready`, then
tears it down.

---

## 5. Testing a specific feature manually

For features that require a pre-existing Kubernetes secret (TLS, mTLS, adminPassword,
dbEncryption), create the secret first, then install:

```bash
# adminPassword example
kubectl create namespace portainer
kubectl create secret generic portainer-admin-password \
  -n portainer \
  --from-literal=password=yourpassword

helm install portainer charts/portainer \
  -n portainer \
  --set adminPassword.existingSecret=portainer-admin-password

# dbEncryption example
kubectl create secret generic portainer-key \
  -n portainer \
  --from-literal=secret=your-32-char-encryption-key-here

helm install portainer charts/portainer \
  -n portainer \
  --set dbEncryption.existingSecret=portainer-key

# TLS example (self-signed cert)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /tmp/tls.key -out /tmp/tls.crt -subj "/CN=portainer"
kubectl create secret tls portainer-tls -n portainer \
  --cert=/tmp/tls.crt --key=/tmp/tls.key

helm install portainer charts/portainer \
  -n portainer \
  --set tls.force=true \
  --set tls.existingSecret=portainer-tls
```

---

## Adding new tests

- **Template test** (no cluster): add a `check` or `absent` assertion to the
  `Run template tests` step in `.github/workflows/on-push-lint-charts.yml`.
  Run it locally with `helm template portainer charts/portainer --set <flag>` first
  to confirm the expected output.

- **Advanced combination test**: add to the `Run advanced template tests` step in
  the same workflow file. These run only when files under
  `charts/portainer/templates/` are changed.

- **Live cluster test**: add a new `ci/*-values.yaml` file under `charts/portainer/`.
  `ct install` picks it up automatically.
