# ArgoCD GitOps — Hub

Control-plane repo for a hub-spoke Argo CD fleet. One self-managed Argo CD runs
on the hub cluster, holds every cluster credential, and pushes to all of them:

- **Infrastructure** → Hub and every spoke, from this repo.
- **Applications** → Spokes only, from [argocd-gitops-spokes](https://github.com/nh4ttruong/argocd-gitops-spokes).

`root-app-of-apps.yaml` is the only object applied by hand. Every other
Application is generated from Git. Four environments: `hub` · `dev` ·
`staging` · `production`.

## Layout

| Path | Contents |
| --- | --- |
| `root-app-of-apps.yaml` | Root Application — Sources itself plus `apps/` |
| `apps/<env>.yaml` | One Application per env, each delivering `appsets/<env>/` |
| `appsets/<env>/infrastructure/` | ApplicationSets for infra, one per engine |
| `appsets/<env>/workloads/` | ApplicationSets for apps, one per engine (None in `hub`) |
| `workloads/<app>/` | The infra manifests — `argocd`, `cert-manager`, `ingress-nginx`, `coredns`, `kustomization` |
| `demo/` | Demo topology — [k3d](demo/k3d/) locally, [VKS](demo/vks/) via Terraform |

Top to bottom: `root` → `apps/<env>` → `appsets/<env>/*` → the generated
`{env}-{app}` Applications.

## How an Application appears

Each ApplicationSet is one `(env, engine)` pair. Its matrix generator crosses
cluster secrets labeled `env: <env>` with git paths matched by convention, and
emits one Application per pair.

| Type | Generator | Path pattern | Source repo |
| --- | --- | --- | --- |
| Infrastructure · Helm | `directories` | `workloads/*/charts/<env>` | This repo |
| Infrastructure · Kustomize | `directories` | `workloads/*/envs/<env>` | This repo |
| Application · Helm | `files` | `workloads/*/charts/<env>/app.yaml` | Spokes repo |
| Application · Kustomize | `files` | `workloads/*/envs/<env>/app.yaml` | Spokes repo |

For example:

| Cluster (`env`) | Matched path | → Application | Project | Namespace |
| --- | --- | --- | --- | --- |
| `hub` | `workloads/argocd/envs/hub` | `hub-argocd` | `hub-infra` | `argocd` |
| `dev` | `workloads/cert-manager/charts/dev` | `dev-cert-manager` | `dev-infra` | `cert-manager` |
| `dev` | `workloads/backend/charts/dev/app.yaml` (Spokes) | `dev-backend` | `dev-apps` | `shop` (From `app.yaml`) |

No ApplicationSet is edited for day-2 work.

## Conventions

| Concern | Convention |
| --- | --- |
| Helm app | `workloads/<app>/charts/<env>/Chart.yaml` (Wrapper chart) + Values merged `values/common.yaml` → `values/<env>/values.yaml` |
| Kustomize app | `workloads/<app>/envs/<env>/kustomization.yaml` (Base + overlay) |
| Application name | `{env}-{app}` |
| AppProject | Infra → `{env}-infra` · Workloads → `{env}-apps`, both in [app-projects](workloads/argocd/envs/hub/app-projects/) |
| Namespace | Infra → `{app}` with `CreateNamespace=true` · Workloads → From `app.yaml` in the spokes repo |
| Cluster selection | Cluster secret label `env: hub\|dev\|staging\|production` |
| Sync | Automated + selfHeal + ServerSideDiff, except all four `appsets/production/*` which omit `automated:` — Production waits for a manual sync. Root prunes with `Prune=confirm` |

## Bootstrap

Both repos are private, so Argo CD needs a read-only credential. A single
`repo-creds` secret on the account prefix covers both repos and both consumers,
repo-server for rendering and applicationset-controller for the git generators.

```bash
# 1 · Install Argo CD — Chart + AppProjects + the hub's own cluster registration
kustomize build workloads/argocd/envs/hub --enable-helm | kubectl apply --server-side --force-conflicts -f -
kubectl -n argocd wait deploy --all --for condition=Available --timeout 300s

# 2 · Repository credential — Fine-grained PAT with Contents: Read-only
printf 'PAT: '; read -rs GITHUB_TOKEN; echo
kubectl -n argocd apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: repo-creds-github-nh4ttruong
  labels:
    argocd.argoproj.io/secret-type: repo-creds
stringData:
  type: git
  url: https://github.com/nh4ttruong
  username: x-access-token
  password: ${GITHUB_TOKEN}
EOF

# 3 · Hand over to Git — The last imperative action
kubectl apply -f root-app-of-apps.yaml
```

Root syncs itself, creates the four env Applications, which create the 14
ApplicationSets, which generate the `hub-*` Applications — Including
`hub-argocd`, from which point Argo CD manages its own upgrades.
[demo/k3d/](demo/k3d/) scripts all three steps against local clusters.

## Day-2

| Task | Change |
| --- | --- |
| Add an infra app | New `workloads/<app>/charts/<env>/` or `workloads/<app>/envs/<env>/` here |
| Add a workload | Same layout in the [spokes repo](https://github.com/nh4ttruong/argocd-gitops-spokes) |
| Add a spoke cluster | Cluster Secret labeled `env: <env>` (See [register-spoke.sh](demo/k3d/register-spoke.sh)) plus its API server in the matching AppProject destinations |
| Upgrade Argo CD | Bump `helmCharts.version` in [workloads/argocd/envs/hub/kustomization.yaml](workloads/argocd/envs/hub/kustomization.yaml) |

> [!WARNING]
> Renaming a folder that `root` itself sources, such as `apps/`, cannot
> self-heal — The live root still points at the old path, so manifest
> generation fails and the sync that would fix its spec never runs. Re-apply
> `root-app-of-apps.yaml`, then hard-refresh.

> [!NOTE]
> Demo repo. For a real fleet: give production its own spokes repo with tighter
> access control, tighten the `*-infra` AppProject whitelists (Currently wide
> open) and replace the `<*_CLUSTER_API_SERVER>` placeholders. Secrets here are
> hand-applied and unencrypted — The repo credential and the spoke cluster
> tokens sit in etcd as plain text, the one part of this repo that is not
> GitOps-managed. Render them through External Secrets Operator or SOPS, and
> prefer a GitHub App over a PAT so rotation is automatic.
