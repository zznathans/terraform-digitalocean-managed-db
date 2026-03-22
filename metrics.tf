data "digitalocean_database_metrics_credentials" "metrics" {}

resource "google_secret_manager_regional_secret" "metrics" {
  project   = var.gcp_project
  location  = var.gcp_region
  secret_id = "${var.stack_name}-db-metrics"

  labels = {
    managed-by = "terraform"
    app        = var.stack_name
  }
}

resource "google_secret_manager_regional_secret_version" "metrics" {
  secret      = google_secret_manager_regional_secret.metrics.id
  secret_data = jsonencode({
    metrics_username = data.digitalocean_database_metrics_credentials.metrics.username
    metrics_password = data.digitalocean_database_metrics_credentials.metrics.password
    metrics_endpoint = digitalocean_database_cluster.cluster.metrics_endpoints.host
    metrics_port    = digitalocean_database_cluster.cluster.metrics_endpoints.port
  })
}
