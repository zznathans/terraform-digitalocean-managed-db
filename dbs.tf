resource "digitalocean_database_db" "db" {
  for_each   = toset(var.db_names)
  cluster_id = digitalocean_database_cluster.cluster.id
  name       = each.value
}