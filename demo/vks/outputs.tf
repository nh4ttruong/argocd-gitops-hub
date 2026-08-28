output "cluster_names" {
  description = "env => cluster name"
  value       = { for env, c in vngcloud_vks_cluster.this : env => c.name }
}

output "cluster_ids" {
  description = "env => cluster ID"
  value       = { for env, c in vngcloud_vks_cluster.this : env => c.id }
}

output "node_group_ids" {
  description = "env => node group ID"
  value       = { for env, ng in vngcloud_vks_cluster_node_group.this : env => ng.id }
}
