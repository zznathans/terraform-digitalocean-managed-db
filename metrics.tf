locals {
  push_any_metrics = var.push_metrics_to_gcp_secret || var.push_metrics_to_aws_secret
}

data "digitalocean_database_metrics_credentials" "metrics" {
  count = local.push_any_metrics ? 1 : 0
}
