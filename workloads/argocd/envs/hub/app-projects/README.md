# AppProject

One AppProject per environment, split by ownership tier. Names MUST match what
the ApplicationSet templates generate:

| Project | Used by | Source repo | Cluster-scope perms |
|---|---|---|---|
| `{env}-infra` (hub/dev/staging/production) | `*-infrastructure-*` ApplicationSets | argocd-gitops-hub | Wide open (Demo) |
| `{env}-apps` (dev/staging/production) | `*-application-*` ApplicationSets | argocd-gitops-spokes | `Namespace` only |

Replace the `<*_CLUSTER_API_SERVER>` placeholders with the real spoke cluster
API endpoints when registering clusters.
