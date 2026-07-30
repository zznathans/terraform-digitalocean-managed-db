resource "digitalocean_vpc" "this" {
  count    = var.create_vpc ? 1 : 0
  name     = var.vpc_name
  region   = var.region
  ip_range = var.vpc_ip_range
}

data "digitalocean_vpc" "this" {
  count = var.create_vpc ? 0 : 1
  name  = var.vpc_name
}

locals {
  vpc_id = var.create_vpc ? digitalocean_vpc.this[0].id : data.digitalocean_vpc.this[0].id
}
