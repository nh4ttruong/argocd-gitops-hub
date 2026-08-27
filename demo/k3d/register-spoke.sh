#!/usr/bin/env bash
# Register a k3d spoke cluster with the hub's Argo CD — Declarative equivalent
# of `argocd cluster add <ctx> --label env=<env>`.
# Usage: ./clusters/k3d/register-spoke.sh <env>   (e.g. dev)
set -euo pipefail
ENV="${1:?Usage: register-spoke.sh <env>}"
SPOKE_CTX="k3d-$ENV"
HUB_CTX="k3d-hub"
SERVER="https://k3d-$ENV-server-0:6443" # Reachable inside the shared docker network

echo "==> 1/2 Service account on the spoke ($SPOKE_CTX)"
kubectl --context "$SPOKE_CTX" -n kube-system create serviceaccount argocd-manager \
  --dry-run=client -o yaml | kubectl --context "$SPOKE_CTX" apply -f -
kubectl --context "$SPOKE_CTX" create clusterrolebinding argocd-manager \
  --clusterrole=cluster-admin --serviceaccount=kube-system:argocd-manager \
  --dry-run=client -o yaml | kubectl --context "$SPOKE_CTX" apply -f -
kubectl --context "$SPOKE_CTX" -n kube-system apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: argocd-manager-token
  annotations:
    kubernetes.io/service-account.name: argocd-manager
type: kubernetes.io/service-account-token
EOF
# Token controller needs a moment to mint the token
for i in $(seq 1 10); do
  TOKEN=$(kubectl --context "$SPOKE_CTX" -n kube-system get secret argocd-manager-token -o jsonpath='{.data.token}' 2>/dev/null || true)
  [ -n "$TOKEN" ] && break; sleep 2
done
TOKEN=$(printf '%s' "$TOKEN" | base64 -d)
CA=$(kubectl --context "$SPOKE_CTX" -n kube-system get secret argocd-manager-token -o jsonpath='{.data.ca\.crt}')

echo "==> 2/2 Cluster registration on the hub (Labeled env=$ENV for the generators)"
kubectl --context "$HUB_CTX" -n argocd apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: cluster-$ENV
  labels:
    argocd.argoproj.io/secret-type: cluster
    env: $ENV
type: Opaque
stringData:
  name: $ENV
  server: $SERVER
  config: |
    {
      "bearerToken": "$TOKEN",
      "tlsClientConfig": {
        "insecure": false,
        "caData": "$CA"
      }
    }
EOF
echo "Spoke '$ENV' registered at $SERVER — Watch: kubectl --context $HUB_CTX -n argocd get applications -w"
