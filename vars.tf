variable "stack_name" {
  type = string
}

variable "db_users" {
  type = list(any)
  default = []
}

variable "db_names" {
  type = list(any)
  default = []
}

variable "conn_pool_size" {
  type    = number
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
  type    = number
  default = 1
}

variable "backup_source" {
  type = string
  default = ""
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

variable "push_gcp_secret" {
    type    = bool
    default = false
}

variable "gcp_region" {
    type = string
}

variable "gcp_project" {
    type = string
}

variable "append_port_to_hostname" {
    type    = bool
    default = false
}

variable "push_metrics_to_gcp_secret" {
    type    = bool
    default = false
}