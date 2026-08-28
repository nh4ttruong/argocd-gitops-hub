#!/usr/bin/env bash
# Join spoke clusters to the hub's Argo CD — Declarative equivalent of
# `argocd cluster add <ctx> --label env=<env>`.
# Usage: ./demo/k3d/register-spoke.sh [env ...]   (Default: dev staging production)
set -euo pipefail
HUB_CTX="k3d-hub"

ENVS=("$@")
[ ${#ENVS[@]} -eq 0 ] && ENVS=(dev staging production)

register() {
  local env="$1"
  local ctx="k3d-$env"
  local server="https://k3d-$env-server-0:6443" # Reachable inside the shared docker network

  echo "==> [$env] 1/2 Service account on the spoke ($ctx)"
  kubectl --context "$ctx" -n kube-system create serviceaccount argocd-manager \
    --dry-run=client -o yaml | kubectl --context "$ctx" apply -f -
  kubectl --context "$ctx" create clusterrolebinding argocd-manager \
    --clusterrole=cluster-admin --serviceaccount=kube-system:argocd-manager \
    --dry-run=client -o yaml | kubectl --context "$ctx" apply -f -
  kubectl --context "$ctx" -n kube-system apply -f - <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: argocd-manager-token
  annotations:
    kubernetes.io/service-account.name: argocd-manager
type: kubernetes.io/service-account-token
YAML

  # Token controller needs a moment to mint the token
  local token=""
  for _ in $(seq 1 10); do
    token=$(kubectl --context "$ctx" -n kube-system get secret argocd-manager-token -o jsonpath='{.data.token}' 2>/dev/null || true)
    [ -n "$token" ] && break
    sleep 2
  done
  [ -n "$token" ] || { echo "    Token never appeared on $ctx"; return 1; }
  token=$(printf '%s' "$token" | base64 -d)
  local ca
  ca=$(kubectl --context "$ctx" -n kube-system get secret argocd-manager-token -o jsonpath='{.data.ca\.crt}')

  echo "==> [$env] 2/2 Cluster registration on the hub (Labeled env=$env for the generators)"
  kubectl --context "$HUB_CTX" -n argocd apply -f - <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: cluster-$env
  labels:
    argocd.argoproj.io/secret-type: cluster
    env: $env
type: Opaque
stringData:
  name: $env
  server: $server
  config: |
    {
      "bearerToken": "$token",
      "tlsClientConfig": {
        "insecure": false,
        "caData": "$ca"
      }
    }
YAML
  echo "    Spoke '$env' registered at $server"
}

for env in "${ENVS[@]}"; do
  register "$env"
done

echo
echo "Watch: kubectl --context $HUB_CTX -n argocd get applications -w"
