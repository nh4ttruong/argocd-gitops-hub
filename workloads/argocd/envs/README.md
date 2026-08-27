# ArgoCD

## Bootstrap ArgoCD on the hub cluster (First time only)

```bash
cd hub
kustomize build . --enable-helm | kubectl apply --server-side --force-conflicts -f -
```

Then apply the root app-of-apps once:

```bash
kubectl apply -f ../../../../root-app-of-apps.yaml
```

After that, Argo CD is **self-managed**: this folder is picked up by the
`hub-infrastructure-kustomize` ApplicationSet (`apps/*/envs/hub`), so every
later change to values, AppProjects, or cluster registrations syncs from Git.
`kustomize.buildOptions: --enable-helm` is set in `argo-cd-values.yaml` so the
repo-server can render the `helmCharts` entry itself.

## Note

- Don't add any other env folder in this directory. This directory is only for
  ArgoCD configuration on the `hub` cluster.
- Because I don't want to change/create AppProject manually, so I use Kustomize
  to render all of them (See `hub/app-projects/`).
- `hub/in-cluster-registration.yaml` registers the hub cluster itself with the
  `env: hub` label that the ApplicationSet cluster generators select on. It
  contains no credentials.
