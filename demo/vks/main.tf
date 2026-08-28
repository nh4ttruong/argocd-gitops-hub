locals {
  # Cluster names cap at 20 characters
  short_names = { production = "prod" }
}

resource "vngcloud_vks_cluster" "this" {
  for_each = var.clusters

  name    = "${var.name_prefix}-${lookup(local.short_names, each.key, each.key)}"
  version = var.vks_version

  vpc_id      = var.vpc_id
  subnet_id   = var.subnet_id
  cidr        = each.value
  az_strategy = "SINGLE"

  network_type                   = "CILIUM_OVERLAY"
  enable_private_cluster         = false
  enabled_load_balancer_plugin   = true
  enabled_block_store_csi_plugin = true
}

# Node groups stay separate resources, as the provider recommends — Inline
# node_group blocks are ForceNew on the cluster.
resource "vngcloud_vks_cluster_node_group" "this" {
  for_each = var.clusters

  cluster_id = vngcloud_vks_cluster.this[each.key].id
  name       = "${each.key}-pool"

  flavor_id  = var.flavor_id
  ssh_key_id = var.ssh_key_id
  num_nodes  = 1
  disk_size  = 50

  # Infra values pin workloads with nodeSelector env=<env>
  labels = { env = each.key }
}
