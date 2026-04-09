locals {
  pool_combinations = var.engine == "pg" ? {
    for idx, u in var.db_users :
    "${u}-${length(var.db_names) > idx ? var.db_names[idx] : u}" => {
      user    = u
      db_name = length(var.db_names) > idx ? var.db_names[idx] : u
    }
  } : {}
}

resource "digitalocean_database_connection_pool" "pool" {
  for_each   = local.pool_combinations
  cluster_id = digitalocean_database_cluster.cluster.id
  name       = each.value.user == each.value.db_name ? "${each.value.user}" : "${each.key}"
  mode       = var.conn_pool_mode
  size       = var.conn_pool_size
  db_name    = each.value.db_name
  user       = each.value.user
}
