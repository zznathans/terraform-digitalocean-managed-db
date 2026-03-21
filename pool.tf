locals {
  pool_combinations = {
    for combo in setproduct(var.db_users, var.db_names) :
    "${combo[0]}-${combo[1]}" => {
      user    = combo[0]
      db_name = combo[1]
    }
  }
}

resource "digitalocean_database_connection_pool" "pool" {
  for_each   = local.pool_combinations
  cluster_id = digitalocean_database_cluster.cluster.id
  name       = "${var.stack_name}-${each.key}-pool"
  mode       = var.conn_pool_mode
  size       = var.conn_pool_size
  db_name    = each.value.db_name
  user       = each.value.user
}
