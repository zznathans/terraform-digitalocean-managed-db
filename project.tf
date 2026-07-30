resource "digitalocean_project" "this" {
  count       = var.create_project ? 1 : 0
  name        = var.project_name
  description = "Managed by Terraform (terraform-digitalocean-managed-db)."
  purpose     = "Web Application"
  environment = "Production"
}

locals {
  project_id = var.create_project ? digitalocean_project.this[0].id : var.project_id
}
