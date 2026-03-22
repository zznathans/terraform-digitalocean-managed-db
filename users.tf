locals {
  use_pools = length(local.pool_combinations) > 0

  gcp_secret_iter = local.use_pools ? local.pool_combinations : {
    for u in var.db_users : u => { user = u, db_name = "" }
  }
}

resource "digitalocean_database_user" "user" {
  for_each   = toset(var.db_users)
  cluster_id = digitalocean_database_cluster.cluster.id
  name       = each.value
}

resource "google_secret_manager_regional_secret" "psql-user" {
  for_each  = var.push_gcp_secret ? local.gcp_secret_iter : {}
  project   = var.gcp_project
  location  = var.gcp_region
  secret_id = local.use_pools ? "${var.stack_name}-db-${each.key}" : "${var.stack_name}-db-user-${each.key}"

  labels = {
    managed-by = "terraform"
    app        = var.stack_name
  }
}

resource "google_secret_manager_regional_secret_version" "psql-user" {
  for_each    = var.push_gcp_secret ? local.gcp_secret_iter : {}
  secret      = google_secret_manager_regional_secret.psql-user[each.key].id
  secret_data = jsonencode({
    db_host     = local.use_pools ? digitalocean_database_connection_pool.pool[each.key].host : digitalocean_database_cluster.cluster.host
    db_port     = local.use_pools ? digitalocean_database_connection_pool.pool[each.key].port : digitalocean_database_cluster.cluster.port
    db_user     = digitalocean_database_user.user[each.value.user].name
    db_password = digitalocean_database_user.user[each.value.user].password
  })
}
