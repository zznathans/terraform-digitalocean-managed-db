resource "digitalocean_database_user" "user" {
  for_each   = toset(var.db_users)
  cluster_id = digitalocean_database_cluster.cluster.id
  name       = each.value
}

resource "google_secret_manager_regional_secret" "psql-user" {
  for_each  = var.push_gcp_secret ? toset(var.db_users) : toset([])
  project   = var.gcp_project
  location  = var.gcp_region
  secret_id = "${var.stack_name}-db-user-${each.value}"

  labels = {
    managed-by = "terraform"
    app        = var.stack_name
  }
}

resource "google_secret_manager_regional_secret_version" "psql-user" {
  for_each    = var.push_gcp_secret ? toset(var.db_users) : toset([])
  secret      = google_secret_manager_regional_secret.psql-user[each.key].id
  secret_data = jsonencode({
    db_host     = digitalocean_database_cluster.cluster.host
    db_port     = digitalocean_database_cluster.cluster.port
    db_user     = digitalocean_database_user.user[each.key].name
    db_password = digitalocean_database_user.user[each.key].password
  })
}
