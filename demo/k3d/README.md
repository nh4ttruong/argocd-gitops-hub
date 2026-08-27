# Local demo — Bootstrap with k3d

Reproduce the whole bootstrap flow on your machine — See [Bootstrap](../../README.md#bootstrap) in the hub README.
Prereqs: `docker`, `k3d`, `kustomize`, `helm`, `kubectl`.

## Hub

```bash
./clusters/k3d/up.sh
kubectl -n argocd get applications -w
```

Expected after a few minutes: `root` + `hub-argocd`, `hub-cert-manager`,
`hub-ingress-nginx`, `hub-coredns`, `hub-kustomization` all Synced/Healthy.
The `dev/staging/production` ApplicationSets stay at 0 apps until a spoke
is registered.

> [!NOTE]
> The root app pulls from GitHub `HEAD`, not from your working tree — Push
> before testing local changes.

## Optional — Register a dev spoke

```bash
k3d cluster create --config clusters/k3d/configs/dev.yaml --wait
./clusters/k3d/register-spoke.sh dev
```

The dev cluster joins the hub's docker network, and `register-spoke.sh` is the
declarative equivalent of `argocd cluster add` (SA + token on the spoke,
labeled cluster Secret on the hub). Within ~3 minutes the generators emit
`dev-*` apps: Infra (cert-manager, ingress-nginx, coredns) + Workloads
(backend, homepage, webhook, whoami).

## Teardown

```bash
./clusters/k3d/down.sh
```
