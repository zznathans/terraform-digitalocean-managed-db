locals {
  use_pools = length(local.pool_combinations) > 0

  secret_iter = local.use_pools ? local.pool_combinations : {
    for idx, u in var.db_users :
    u => {
      user    = u
      db_name = length(var.db_names) > idx ? var.db_names[idx] : ""
    }
  }
}

resource "digitalocean_database_user" "user" {
  for_each   = toset(var.db_users)
  cluster_id = digitalocean_database_cluster.cluster.id
  name       = each.value
}
