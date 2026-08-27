#!/usr/bin/env bash
# Spin up a local k3d hub cluster and bootstrap the whole GitOps stack.
# Prereqs: docker, k3d, kustomize, helm, kubectl.
set -euo pipefail
cd "$(dirname "$0")/../.."

echo "==> 1/4 Create k3d hub cluster"
k3d cluster create --config clusters/k3d/configs/hub.yaml --wait

echo "==> 2/4 Install Argo CD (Renders helm chart via kustomize)"
RENDER="$(mktemp)"
kustomize build workloads/argocd/envs/hub --enable-helm > "$RENDER"
# First pass may race CRD establishment — second pass converges (idempotent).
kubectl apply --server-side --force-conflicts -f "$RENDER" || true
kubectl wait --for condition=Established --timeout 120s \
  crd/applications.argoproj.io crd/appprojects.argoproj.io crd/applicationsets.argoproj.io
kubectl apply --server-side --force-conflicts -f "$RENDER"
rm -f "$RENDER"
kubectl -n argocd wait deploy --all --for condition=Available --timeout 300s

# Private repos: export GITHUB_TOKEN before running to register repo credentials
# (covers every repo under the account prefix — see Bootstrap in the hub README).
if [ -n "${GITHUB_TOKEN:-}" ]; then
  echo "==> 2b/4 Repository credentials (GITHUB_TOKEN detected)"
  kubectl -n argocd apply -f - <<EOF
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
EOF
fi

echo "==> 3/4 Apply root App-of-Apps (Last imperative action)"
kubectl apply -f root-app-of-apps.yaml

echo "==> 4/4 Done — Watch the chain reaction:"
echo "    kubectl -n argocd get applications -w"
echo "    Admin password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo "    UI: kubectl -n argocd port-forward svc/argocd-server 8081:443  ->  https://localhost:8081"
