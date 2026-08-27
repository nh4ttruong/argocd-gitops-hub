variable "client_id" {
  description = "VNG Cloud service account client ID"
  type        = string
  sensitive   = true
}

variable "client_secret" {
  description = "VNG Cloud service account client secret"
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  description = "VPC ID shared by all clusters (net-xxxx)"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID shared by all clusters (sub-xxxx)"
  type        = string
}

variable "ssh_key_id" {
  description = "SSH key ID for the worker nodes (ssh-xxxx)"
  type        = string
}

variable "flavor_id" {
  description = "Flavor ID for the worker nodes (flav-xxxx) — 2 vCPU / 4 GB for this demo"
  type        = string
}

variable "name_prefix" {
  description = "Cluster name prefix; the full name must stay within 20 characters"
  type        = string
  default     = "gitops-demo"
}

variable "vks_version" {
  description = "VKS control plane version; null lets VKS pick its default"
  type        = string
  default     = null
}

variable "clusters" {
  description = "Demo clusters — env => pod CIDR"
  type        = map(string)
  default = {
    hub        = "172.16.0.0/16"
    dev        = "172.17.0.0/16"
    staging    = "172.18.0.0/16"
    production = "172.19.0.0/16"
  }
}
