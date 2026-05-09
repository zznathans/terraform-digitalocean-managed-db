resource "aws_secretsmanager_secret" "user" {
  for_each = var.push_aws_secret ? local.secret_iter : {}

  name        = local.use_pools ? "${var.stack_name}-db-${each.key}" : "${var.stack_name}-db-user-${each.key}"
  description = "DigitalOcean database credentials for ${var.stack_name}"

  dynamic "replica" {
    for_each = var.aws_replicas
    content {
      region     = replica.value.region
      kms_key_id = replica.value.kms_key_id
    }
  }

  tags = merge(var.tags, {
    managed-by = "terraform"
    app        = var.stack_name
  })
}

resource "aws_secretsmanager_secret_version" "user" {
  for_each  = var.push_aws_secret ? local.secret_iter : {}
  secret_id = aws_secretsmanager_secret.user[each.key].id
  secret_string = jsonencode({
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

resource "aws_secretsmanager_secret" "metrics" {
  count       = var.push_metrics_to_aws_secret ? 1 : 0
  name        = "${var.stack_name}-db-metrics"
  description = "DigitalOcean database metrics credentials for ${var.stack_name}"

  dynamic "replica" {
    for_each = var.aws_replicas
    content {
      region     = replica.value.region
      kms_key_id = replica.value.kms_key_id
    }
  }

  tags = merge(var.tags, {
    managed-by = "terraform"
    app        = var.stack_name
  })
}

resource "aws_secretsmanager_secret_version" "metrics" {
  count     = var.push_metrics_to_aws_secret ? 1 : 0
  secret_id = aws_secretsmanager_secret.metrics[0].id
  secret_string = jsonencode({
    metrics_username = data.digitalocean_database_metrics_credentials.metrics[0].username
    metrics_password = data.digitalocean_database_metrics_credentials.metrics[0].password
    metrics_endpoint = digitalocean_database_cluster.cluster.metrics_endpoints[0]
  })
}
