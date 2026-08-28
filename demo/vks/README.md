# VKS — Terraform demo topology

Four VKS clusters on VNG Cloud, same topology as [k3d](../k3d/): one hub for
Argo CD plus three spokes. Each cluster gets one node group of a single worker
(2 vCPU / 4 GB) labeled `env: <env>`, which is what the infra values select on.

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

Kubeconfigs come from the [VKS console](https://vks.console.vngcloud.vn) — The
provider exposes no kubeconfig attribute. With the hub kubeconfig in hand, run
[Bootstrap](../../README.md#bootstrap) against it, then register each spoke the
same way as on k3d: A cluster Secret on the hub labeled `env: <env>`, see
[register-spoke.sh](../k3d/register-spoke.sh).

## Notes

- Credentials come from a [service account](https://iam.console.vngcloud.vn/service-account) with VKS permissions. VPC, subnet, SSH key and flavor must exist beforehand; flavor IDs are listed in the [VNG Cloud docs](https://docs.vngcloud.vn/vng-cloud-document/v/vn/vks/tham-khao-them/danh-sach-flavor-dang-ho-tro).
- Cluster names cap at 20 characters, hence `gitops-demo-prod` — Its env key and node label stay `production`.
- `vks_version` is null by default, which leaves the provider default of `1.29.1-vks.1724605200`. Pin a current version from the [supported list](https://docs.vngcloud.vn/vng-cloud-document/v/vn/vks/tham-khao-them/phien-ban-ho-tro-kubernetes).
- Node groups are separate resources rather than inline `node_group` blocks, which the provider recommends because inline blocks force the whole cluster to be recreated when they change.
- Changing `name`, `cidr`, `vpc_id`, `subnet_id` or `network_type` recreates the cluster.
- One node per cluster with no autoscaling. Add `auto_scale_config` in [main.tf](main.tf) for anything beyond a demo.
