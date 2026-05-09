output "cluster_id" {
  value = digitalocean_database_cluster.cluster.id
}

output "cluster_host" {
  value = digitalocean_database_cluster.cluster.host
}

output "cluster_private_host" {
  value = digitalocean_database_cluster.cluster.private_host
}

output "cluster_port" {
  value = digitalocean_database_cluster.cluster.port
}

output "cluster_uri" {
  value     = digitalocean_database_cluster.cluster.uri
  sensitive = true
}

output "cluster_private_uri" {
  value     = digitalocean_database_cluster.cluster.private_uri
  sensitive = true
}
