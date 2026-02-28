#!/usr/bin/env bash
# Template tests for the Portainer Helm chart.
# Run from the repo root: bash .ci/scripts/template-tests.sh
set -euo pipefail

CHART="charts/portainer"
fail=0

check() {
  local desc="$1" pattern="$2" output="$3"
  if ! echo "$output" | grep -q "$pattern"; then
    echo "FAIL [$desc]: expected '$pattern' not found"
    fail=1
  else
    echo "PASS [$desc]"
  fi
}

absent() {
  local desc="$1" pattern="$2" output="$3"
  if echo "$output" | grep -q "$pattern"; then
    echo "FAIL [$desc]: unexpected '$pattern' found"
    fail=1
  else
    echo "PASS [$desc]"
  fi
}

vol_consistent() {
  local desc="$1" name="$2" output="$3"
  [[ $(echo "$output" | grep -c "name: ${name}$") -ge 2 ]] \
    && echo "PASS [volume consistency: $desc]" \
    || { echo "FAIL [volume consistency: $desc]: name mismatch between volumes and volumeMounts"; fail=1; }
}

# Default: tunnel-port rendered for NodePort with edgeNodePort set
out=$(helm template portainer "$CHART")
check "default: tunnel-port arg" "\-\-tunnel-port" "$out"

# tls.force: --http-disabled added, HTTP port 9000 removed
out=$(helm template portainer "$CHART" --set tls.force=true)
check  "tls.force: --http-disabled arg"    "\-\-http-disabled"  "$out"
absent "tls.force: no containerPort 9000"  "containerPort: 9000" "$out"

# tls.existingSecret: cert args and volume mount
out=$(helm template portainer "$CHART" --set tls.existingSecret=my-tls)
check "tls.existingSecret: --tlscert arg"     "\-\-tlscert=/certs/tls.crt" "$out"
check "tls.existingSecret: --tlskey arg"      "\-\-tlskey=/certs/tls.key"  "$out"
check "tls.existingSecret: certs volumeMount" "mountPath: /certs$"         "$out"
vol_consistent "certs" "certs" "$out"

# mtls.existingSecret: mtls args and volume mount
out=$(helm template portainer "$CHART" --set mtls.existingSecret=my-mtls)
check "mtls: --mtlscacert arg"      "\-\-mtlscacert="        "$out"
check "mtls: --mtlscert arg"        "\-\-mtlscert="          "$out"
check "mtls: --mtlskey arg"         "\-\-mtlskey="           "$out"
check "mtls: mtlscerts volumeMount" "mountPath: /certs/mtls" "$out"
vol_consistent "mtlscerts" "mtlscerts" "$out"

# adminPassword.existingSecret: arg, volume, and volumeMount
out=$(helm template portainer "$CHART" --set adminPassword.existingSecret=my-pw)
check "adminPassword: --admin-password-file arg" "\-\-admin-password-file=/run/portainer/admin-password" "$out"
check "adminPassword: volume present"            "name: admin-password"                                  "$out"
check "adminPassword: volumeMount mountPath"     "mountPath: /run/portainer/admin-password"              "$out"
vol_consistent "admin-password" "admin-password" "$out"

# dbEncryption CE: portainer-key volume, CE mountPath
out=$(helm template portainer "$CHART" --set dbEncryption.existingSecret=my-key)
check "dbEncryption CE: portainer-key volume" "name: portainer-key"               "$out"
check "dbEncryption CE: CE mountPath"         "mountPath: /run/secrets/portainer" "$out"
vol_consistent "portainer-key" "portainer-key" "$out"

# dbEncryption EE: EE mountPath
out=$(helm template portainer "$CHART" \
  --set enterpriseEdition.enabled=true \
  --set dbEncryption.existingSecret=my-key)
check "dbEncryption EE: EE mountPath" "mountPath: /run/portainer/portainer" "$out"

# trusted_origins: --trusted-origins arg
out=$(helm template portainer "$CHART" \
  --set trusted_origins.enabled=true \
  --set trusted_origins.domains=portainer.example.com)
check "trusted_origins: --trusted-origins arg" "\-\-trusted-origins=" "$out"

# feature.flags: flag values rendered in args
out=$(helm template portainer "$CHART" --set "feature.flags={--feat-one}")
check "feature.flags: flag in args" "feat-one" "$out"

# extraEnv: env vars rendered on the container
out=$(helm template portainer "$CHART" \
  --set "extraEnv[0].name=MY_VAR" \
  --set "extraEnv[0].value=hello")
check "extraEnv: env var name rendered" "MY_VAR" "$out"

# persistence.enabled=false: no data volume or volumeMount
out=$(helm template portainer "$CHART" --set persistence.enabled=false)
absent "persistence disabled: no data volume"      "name: data$"       "$out"
absent "persistence disabled: no data volumeMount" "mountPath: /data$" "$out"

# localMgmt=false: no serviceAccountName on the pod
out=$(helm template portainer "$CHART" --set localMgmt=false)
absent "localMgmt disabled: no serviceAccountName" "serviceAccountName" "$out"

# service.type=ClusterIP: no nodePort fields rendered
out=$(helm template portainer "$CHART" --set service.type=ClusterIP)
absent "ClusterIP: no nodePort fields" "nodePort:" "$out"

# ingress.enabled=true: Ingress resource present
out=$(helm template portainer "$CHART" --set ingress.enabled=true)
check "ingress enabled: Ingress resource" "kind: Ingress" "$out"

# EE image selection: enterpriseEdition.enabled=true must use the EE image
out=$(helm template portainer "$CHART" --set enterpriseEdition.enabled=true)
check  "EE enabled: EE image used"  "portainer-ee" "$out"
absent "EE enabled: CE image absent" "portainer-ce" "$out"

# tls.force + tls.existingSecret combined: both --http-disabled and --tlscert present
out=$(helm template portainer "$CHART" \
  --set tls.force=true \
  --set tls.existingSecret=my-tls)
check "tls combined: --http-disabled arg" "\-\-http-disabled"          "$out"
check "tls combined: --tlscert arg"       "\-\-tlscert=/certs/tls.crt" "$out"

# Full TLS stack: tls.force + cert secret + mTLS all together
out=$(helm template portainer "$CHART" \
  --set tls.force=true \
  --set tls.existingSecret=my-tls \
  --set mtls.existingSecret=my-mtls)
check  "full TLS stack: --http-disabled"       "\-\-http-disabled"   "$out"
check  "full TLS stack: --tlscert"             "\-\-tlscert="        "$out"
check  "full TLS stack: --mtlscacert"          "\-\-mtlscacert="     "$out"
absent "full TLS stack: no containerPort 9000" "containerPort: 9000" "$out"
vol_consistent "certs"     "certs"     "$out"
vol_consistent "mtlscerts" "mtlscerts" "$out"

# Full security stack: every secret-backed feature enabled at once
out=$(helm template portainer "$CHART" \
  --set tls.existingSecret=my-tls \
  --set mtls.existingSecret=my-mtls \
  --set adminPassword.existingSecret=my-pw \
  --set dbEncryption.existingSecret=my-key)
check "full security stack: --tlscert"             "\-\-tlscert="                      "$out"
check "full security stack: --mtlscacert"          "\-\-mtlscacert="                   "$out"
check "full security stack: --admin-password-file" "\-\-admin-password-file="          "$out"
check "full security stack: portainer-key volume"  "name: portainer-key"               "$out"
check "full security stack: CE mountPath"          "mountPath: /run/secrets/portainer" "$out"
vol_consistent "certs"          "certs"          "$out"
vol_consistent "mtlscerts"      "mtlscerts"      "$out"
vol_consistent "admin-password" "admin-password" "$out"
vol_consistent "portainer-key"  "portainer-key"  "$out"

# EE full stack: EE image + dbEncryption + adminPassword + tls.force
out=$(helm template portainer "$CHART" \
  --set enterpriseEdition.enabled=true \
  --set dbEncryption.existingSecret=my-key \
  --set adminPassword.existingSecret=my-pw \
  --set tls.force=true)
check  "EE full stack: EE image"              "portainer-ee"                        "$out"
absent "EE full stack: no CE image"           "portainer-ce"                        "$out"
check  "EE full stack: EE dbEncryption path"  "mountPath: /run/portainer/portainer" "$out"
check  "EE full stack: --http-disabled"       "\-\-http-disabled"                   "$out"
check  "EE full stack: --admin-password-file" "\-\-admin-password-file="            "$out"

# Combined extras: feature flags + trusted_origins + extraEnv together
out=$(helm template portainer "$CHART" \
  --set "feature.flags={--feat-one,--feat-two}" \
  --set trusted_origins.enabled=true \
  --set trusted_origins.domains=portainer.example.com \
  --set "extraEnv[0].name=MY_VAR" \
  --set "extraEnv[0].value=hello")
check "combined extras: feat-one flag"     "feat-one"             "$out"
check "combined extras: feat-two flag"     "feat-two"             "$out"
check "combined extras: --trusted-origins" "\-\-trusted-origins=" "$out"
check "combined extras: extraEnv MY_VAR"   "MY_VAR"               "$out"

exit $fail
