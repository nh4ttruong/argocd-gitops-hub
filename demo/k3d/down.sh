#!/usr/bin/env bash
# Tear down the local demo clusters.
set -euo pipefail
for c in production staging dev hub; do
  k3d cluster delete "$c" 2>/dev/null || true
done
echo "Demo clusters removed."
