#!/usr/bin/env bash
# Create the k3d demo clusters — Hub first, then the spokes.
# Usage: ./demo/k3d/up.sh [env ...]   (Default: hub dev staging production)
set -euo pipefail
cd "$(dirname "$0")/../.."

ENVS=("$@")
[ ${#ENVS[@]} -eq 0 ] && ENVS=(hub dev staging production)

for env in "${ENVS[@]}"; do
  if k3d cluster list --no-headers 2>/dev/null | awk '{print $1}' | grep -qx "$env"; then
    echo "==> Cluster '$env' already exists — Skipping"
    continue
  fi
  echo "==> Creating cluster '$env'"
  k3d cluster create --config "demo/k3d/configs/$env.yaml" --wait
done

echo
echo "Clusters ready. Next: ./demo/k3d/bootstrap.sh"
