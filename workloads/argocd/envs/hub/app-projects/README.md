# AppProject

One AppProject per environment, split by ownership tier. Names MUST match what
the ApplicationSet templates generate:

| Project | Used by | Source repo | Cluster-scope perms |
|---|---|---|---|
| `{env}-infra` (hub/dev/staging/production) | `*-infrastructure-*` ApplicationSets | argocd-gitops-hub | Wide open (Demo) |
| `{env}-apps` (dev/staging/production) | `*-application-*` ApplicationSets | argocd-gitops-spokes | `Namespace` only |

Every `destinations.server` points at the k3d demo endpoint of its environment
(`https://k3d-<env>-server-0:6443`). Swap them for the real API servers when
registering clusters elsewhere.
