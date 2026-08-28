#!/usr/bin/env bash
# Deploy Argo CD on the hub, link it to Git, then hand over to the root app.
# Prereqs: the hub cluster exists (./demo/k3d/up.sh hub), kustomize, helm, kubectl.
set -euo pipefail
cd "$(dirname "$0")/../.."
K="kubectl --context k3d-hub"

echo "==> 1/3 Install Argo CD (Renders the helm chart via kustomize)"
RENDER="$(mktemp)"
kustomize build workloads/argocd/envs/hub --enable-helm > "$RENDER"
# First pass may race CRD establishment — Second pass converges (Idempotent).
$K apply --server-side --force-conflicts -f "$RENDER" || true
$K wait --for condition=Established --timeout 120s \
  crd/applications.argoproj.io crd/appprojects.argoproj.io crd/applicationsets.argoproj.io
$K apply --server-side --force-conflicts -f "$RENDER"
rm -f "$RENDER"
$K -n argocd wait deploy --all --for condition=Available --timeout 300s

echo "==> 2/3 Link Git (Repository credential)"
if [ -n "${GITHUB_TOKEN:-}" ]; then
  $K -n argocd apply -f - <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: repo-creds-github-nh4ttruong
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repo-creds
stringData:
  type: git
  url: https://github.com/nh4ttruong
  username: x-access-token
  password: ${GITHUB_TOKEN}
YAML
else
  echo "    GITHUB_TOKEN not set — Skipped. Both repos are private, so nothing"
  echo "    will render until the credential exists. Export it and re-run."
fi

echo "==> 3/3 Apply root App-of-Apps (Last imperative action)"
$K apply -f root-app-of-apps.yaml

echo
echo "Watch the chain reaction:"
echo "    kubectl --context k3d-hub -n argocd get applications -w"
echo "Admin password:"
echo "    kubectl --context k3d-hub -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo "UI:"
echo "    kubectl --context k3d-hub -n argocd port-forward svc/argocd-server 8081:443  ->  https://localhost:8081"
echo
echo "Next: ./demo/k3d/register-spoke.sh"
