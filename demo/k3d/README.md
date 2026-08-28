# Local demo — Four clusters on k3d

The whole flow, in the order it has to happen:

| Step | Command | What it does |
| --- | --- | --- |
| 1 · Clusters | `./demo/k3d/up.sh` | Creates the hub first, then dev, staging and production |
| 2 · Argo CD | `./demo/k3d/bootstrap.sh` | Installs Argo CD on the hub, links Git, applies the root app |
| 3 · Spokes | `./demo/k3d/register-spoke.sh` | Joins the three spokes, labeled `env: <env>` |

Prereqs: `docker`, `k3d`, `kustomize`, `helm`, `kubectl`.

## 1 · Clusters

```bash
./demo/k3d/up.sh                            # hub dev staging production
./demo/k3d/up.sh hub                        # Or one at a time
./demo/k3d/up.sh dev staging production
```

The hub has to exist first, because each spoke config joins the `k3d-hub`
docker network — That is how the hub's Argo CD reaches
`https://k3d-<env>-server-0:6443` in step 3. Every spoke node is labeled
`env=<env>`, which the infra values pin to with `nodeSelector`. Clusters that
already exist are skipped, so re-running is safe.

## 2 · Argo CD on the hub

```bash
export GITHUB_TOKEN=<Fine-grained PAT, Contents: Read-only>
./demo/k3d/bootstrap.sh
```

Three phases, all pinned to the `k3d-hub` context: Render and apply the Argo CD
chart, create the `repo-creds` secret that links both private repos, then apply
`root-app-of-apps.yaml`. Without `GITHUB_TOKEN` the credential step is skipped
and nothing renders, since both repos are private.

Expected a few minutes later: `root` plus `hub-argocd`, `hub-cert-manager`,
`hub-ingress-nginx`, `hub-coredns` and `hub-kustomization`, all Synced/Healthy.
The `dev`, `staging` and `production` ApplicationSets sit at 0 apps until a
spoke is registered.

> [!NOTE]
> The root app pulls from GitHub `HEAD`, not from your working tree — Push
> before testing local changes.

## 3 · Join the spokes

```bash
./demo/k3d/register-spoke.sh                # dev staging production
./demo/k3d/register-spoke.sh staging        # Or one at a time
```

Per spoke: A `cluster-admin` service account plus token on the spoke, then a
cluster Secret on the hub labeled `env: <env>`. That label is the only thing the
generators match on. Within ~3 minutes the `{env}-*` Applications appear — Infra
(cert-manager, ingress-nginx, coredns) and workloads (backend, homepage,
webhook, whoami).

`production-*` is generated but stays OutOfSync, because none of the
`appsets/production/*` ApplicationSets carry an `automated:` block:

```bash
kubectl --context k3d-hub -n argocd get applications -l env=production
argocd app sync production-backend
```

## Teardown

```bash
./demo/k3d/down.sh
```

Four clusters at one server node each. Run `./demo/k3d/up.sh hub dev` and
register only `dev` if the machine is tight on memory.
