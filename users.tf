resource "digitalocean_database_user" "user" {
  for_each   = toset(var.db_users)
  cluster_id = digitalocean_database_cluster.cluster.id
  name       = each.value
}