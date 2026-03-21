resource "digitalocean_database_cluster" "cluster" {
  name       = "${var.stack_name}-db"
  engine     = var.engine
  version    = var.engine_version
  region     = var.region
  size       = var.instance_size
  node_count = var.node_count
  project_id = var.project_id

  dynamic "backup_restore" {
    for_each = var.backup_source != "" ? [1] : []
    content {
      database_name = var.backup_source
    }
  }
}
