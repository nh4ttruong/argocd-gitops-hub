# Clusters — Provisioning

Two interchangeable ways to stand up the 4-cluster demo topology
(hub + dev/staging/production spokes) — pick one:

| Platform | Folder | Use case |
|---|---|---|
| [k3d](k3d/) | Local docker clusters + bootstrap scripts | Quick demo on your machine |
| [VKS](vks/) | VNG Cloud managed Kubernetes via Terraform | Cloud demo on real infrastructure |

Everything above this folder (`apps/`, `appsets/`, `workloads/`) is
platform-agnostic GitOps content — it runs the same on either.
