# Regional secrets (gcp_secret_regional = true)

resource "google_secret_manager_regional_secret" "user" {
  for_each  = var.push_gcp_secret && var.gcp_secret_regional ? local.secret_iter : {}
  project   = var.gcp_project
  location  = var.gcp_region
  secret_id = local.use_pools ? "${var.stack_name}-db-${each.key}" : "${var.stack_name}-db-user-${each.key}"

  labels = merge(var.tags, {
    managed-by = "terraform"
    app        = var.stack_name
  })
}

resource "google_secret_manager_regional_secret_version" "user" {
  for_each = var.push_gcp_secret && var.gcp_secret_regional ? local.secret_iter : {}
  secret   = google_secret_manager_regional_secret.user[each.key].id
  secret_data = jsonencode({
    db_host = local.use_pools ? (
      var.append_port_to_hostname ? "${digitalocean_database_connection_pool.pool[each.key].private_host}:${digitalocean_database_connection_pool.pool[each.key].port}" : digitalocean_database_connection_pool.pool[each.key].private_host
      ) : (
      var.append_port_to_hostname ? "${digitalocean_database_cluster.cluster.private_host}:${digitalocean_database_cluster.cluster.port}" : digitalocean_database_cluster.cluster.private_host
    )
    db_port     = local.use_pools ? digitalocean_database_connection_pool.pool[each.key].port : digitalocean_database_cluster.cluster.port
    db_user     = digitalocean_database_user.user[each.value.user].name
    db_password = digitalocean_database_user.user[each.value.user].password
    db_name     = each.value.db_name != "" ? each.value.db_name : null
  })
}

resource "google_secret_manager_regional_secret" "metrics" {
  count     = var.push_metrics_to_gcp_secret && var.gcp_secret_regional ? 1 : 0
  project   = var.gcp_project
  location  = var.gcp_region
  secret_id = "${var.stack_name}-db-metrics"

  labels = merge(var.tags, {
    managed-by = "terraform"
    app        = var.stack_name
  })
}

resource "google_secret_manager_regional_secret_version" "metrics" {
  count  = var.push_metrics_to_gcp_secret && var.gcp_secret_regional ? 1 : 0
  secret = google_secret_manager_regional_secret.metrics[0].id
  secret_data = jsonencode({
    metrics_username = data.digitalocean_database_metrics_credentials.metrics[0].username
    metrics_password = data.digitalocean_database_metrics_credentials.metrics[0].password
    metrics_endpoint = digitalocean_database_cluster.cluster.metrics_endpoints[0]
  })
}

# Global secrets with replication policy (gcp_secret_regional = false)

resource "google_secret_manager_secret" "user" {
  for_each  = var.push_gcp_secret && !var.gcp_secret_regional ? local.secret_iter : {}
  project   = var.gcp_project
  secret_id = local.use_pools ? "${var.stack_name}-db-${each.key}" : "${var.stack_name}-db-user-${each.key}"

  replication {
    dynamic "auto" {
      for_each = var.gcp_replication.automatic ? [1] : []
      content {}
    }

    dynamic "user_managed" {
      for_each = !var.gcp_replication.automatic ? [1] : []
      content {
        dynamic "replicas" {
          for_each = var.gcp_replication.locations
          content {
            location = replicas.value
          }
        }
      }
    }
  }

  labels = merge(var.tags, {
    managed-by = "terraform"
    app        = var.stack_name
  })
}

resource "google_secret_manager_secret_version" "user" {
  for_each = var.push_gcp_secret && !var.gcp_secret_regional ? local.secret_iter : {}
  secret   = google_secret_manager_secret.user[each.key].id
  secret_data = jsonencode({
    db_host = local.use_pools ? (
      var.append_port_to_hostname ? "${digitalocean_database_connection_pool.pool[each.key].private_host}:${digitalocean_database_connection_pool.pool[each.key].port}" : digitalocean_database_connection_pool.pool[each.key].private_host
      ) : (
      var.append_port_to_hostname ? "${digitalocean_database_cluster.cluster.private_host}:${digitalocean_database_cluster.cluster.port}" : digitalocean_database_cluster.cluster.private_host
    )
    db_port     = local.use_pools ? digitalocean_database_connection_pool.pool[each.key].port : digitalocean_database_cluster.cluster.port
    db_user     = digitalocean_database_user.user[each.value.user].name
    db_password = digitalocean_database_user.user[each.value.user].password
    db_name     = each.value.db_name != "" ? each.value.db_name : null
  })
}

resource "google_secret_manager_secret" "metrics" {
  count     = var.push_metrics_to_gcp_secret && !var.gcp_secret_regional ? 1 : 0
  project   = var.gcp_project
  secret_id = "${var.stack_name}-db-metrics"

  replication {
    dynamic "auto" {
      for_each = var.gcp_replication.automatic ? [1] : []
      content {}
    }

    dynamic "user_managed" {
      for_each = !var.gcp_replication.automatic ? [1] : []
      content {
        dynamic "replicas" {
          for_each = var.gcp_replication.locations
          content {
            location = replicas.value
          }
        }
      }
    }
  }

  labels = merge(var.tags, {
    managed-by = "terraform"
    app        = var.stack_name
  })
}

resource "google_secret_manager_secret_version" "metrics" {
  count  = var.push_metrics_to_gcp_secret && !var.gcp_secret_regional ? 1 : 0
  secret = google_secret_manager_secret.metrics[0].id
  secret_data = jsonencode({
    metrics_username = data.digitalocean_database_metrics_credentials.metrics[0].username
    metrics_password = data.digitalocean_database_metrics_credentials.metrics[0].password
    metrics_endpoint = digitalocean_database_cluster.cluster.metrics_endpoints[0]
  })
}
