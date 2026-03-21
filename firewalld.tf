resource "digitalocean_database_firewall" "firewall" {
  cluster_id = digitalocean_database_cluster.cluster.id

  dynamic "rule" {
    for_each = var.firewall_droplets
    content {
      type  = "droplet"
      value = rule.value
    }
  }

  dynamic "rule" {
    for_each = var.firewall_tags
    content {
      type  = "tag"
      value = rule.value
    }
  }

  dynamic "rule" {
    for_each = var.firewall_k8s
    content {
      type  = "k8s"
      value = rule.value
    }
  }

  dynamic "rule" {
    for_each = var.firewall_ips
    content {
      type  = "ip_addr"
      value = rule.value
    }
  }
}