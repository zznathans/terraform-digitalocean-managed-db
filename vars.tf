variable "do_token" {
  type    = string
  default = ""
}

variable "stack_name" {
  type = string
}

variable "db_users" {
  type = list(any)
}

variable "db_names" {
  type = list(any)
}

variable "conn_pool_size" {
  type    = int
  default = 5
}

variable "conn_pool_mode" {
  type    = string
  default = "transaction"
}

variable "engine_version" {
  type = string
}

variable "engine" {
  type = string
}

variable "instance_size" {
  type    = string
  default = "db-s-1vcpu-1gb"
}

variable "region" {
  type = string
}

variable "node_count" {
  type    = int
  default = 1
}

variable "backup_source" {
  type = string
}

variable "project_id" {
  type = string
}

variable "firewall_droplets" {
  type    = list(any)
  default = []
}

variable "firewall_tags" {
  type    = list(any)
  default = []
}

variable "firewall_k8s" {
  type    = list(any)
  default = []
}

variable "firewall_ips" {
  type    = list(any)
  default = []
}