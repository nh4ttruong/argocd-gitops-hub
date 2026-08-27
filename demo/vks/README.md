# VKS — Terraform demo topology

Four VKS clusters on VNG Cloud, same topology as [k3d](../k3d/): one hub for
Argo CD plus three spokes. Each cluster gets a single worker node (2 vCPU /
4 GB) labeled `env: <env>`, which is what the infra values select on.

| Cluster | Role | Pod CIDR |
| --- | --- | --- |
| `gitops-demo-hub` | Argo CD control plane | `172.16.0.0/16` |
| `gitops-demo-dev` | Spoke — dev | `172.17.0.0/16` |
| `gitops-demo-staging` | Spoke — staging | `172.18.0.0/16` |
| `gitops-demo-prod` | Spoke — production | `172.19.0.0/16` |

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars   # client_id, client_secret, vpc_id, subnet_id, ssh_key_id, flavor_id
terraform init
terraform apply
```

Pull the kubeconfigs, then run [Bootstrap](../../README.md#bootstrap) against
the hub:

```bash
for env in hub dev staging production; do
  terraform output -json kubeconfigs | jq -r ".$env" > "$env.kubeconfig"
done
export KUBECONFIG=$PWD/hub.kubeconfig
```

Registering a spoke is the same as on k3d — A cluster Secret on the hub labeled
`env: <env>`, see [register-spoke.sh](../k3d/register-spoke.sh).

## Notes

- Credentials come from a [service account](https://iam.console.vngcloud.vn/service-account) with VKS permissions. VPC, subnet, SSH key and flavor must exist beforehand.
- Cluster names cap at 20 characters, hence `gitops-demo-prod` — Its env key and node label stay `production`.
- `vks_version` defaults to null so VKS picks its current default; pin it if you need a specific control plane version.
- Changing `name`, `cidr`, `vpc_id`, `subnet_id` or `network_type` recreates the cluster.
- One node per cluster with no autoscaling. Bump `num_nodes` in [main.tf](main.tf) for anything beyond a demo.
