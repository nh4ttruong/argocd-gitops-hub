#!/usr/bin/env bash
# Tear down the local demo clusters.
set -euo pipefail
k3d cluster delete hub 2>/dev/null || true
k3d cluster delete dev 2>/dev/null || true
echo "Demo clusters removed."
