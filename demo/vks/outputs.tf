output "cluster_names" {
  description = "env => cluster name"
  value       = { for env, c in vngcloud_vks_cluster.this : env => c.name }
}

output "cluster_ids" {
  description = "env => cluster ID"
  value       = { for env, c in vngcloud_vks_cluster.this : env => c.id }
}

output "kubeconfigs" {
  description = "env => kubeconfig"
  value       = { for env, c in vngcloud_vks_cluster.this : env => c.config }
  sensitive   = true
}
