variable "stack_name" {
  type = string
}

variable "db_users" {
  type    = list(string)
  default = []
}

variable "db_names" {
  type    = list(string)
  default = []
}

variable "conn_pool_size" {
  type    = number
  default = 5
}

variable "conn_pool_mode" {
  type    = string
  default = "transaction"

  validation {
    condition     = contains(["transaction", "session", "statement"], var.conn_pool_mode)
    error_message = "conn_pool_mode must be \"transaction\", \"session\", or \"statement\"."
  }
}

variable "engine_version" {
  type = string
}

variable "engine" {
  type = string

  validation {
    condition     = contains(["pg", "mysql", "redis"], var.engine)
    error_message = "engine must be \"pg\", \"mysql\", or \"redis\"."
  }
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
  type    = string
  default = ""
}

variable "project_id" {
  type        = string
  default     = null
  description = "Existing DigitalOcean project ID to attach the cluster to. Required unless create_project = true."
}

variable "create_project" {
  type        = bool
  default     = false
  description = "When true, create a new DigitalOcean project named project_name and attach the cluster to it, instead of using an existing project_id."
}

variable "project_name" {
  type        = string
  default     = null
  description = "Name for the new project when create_project = true."
}

variable "firewall_droplets" {
  type    = list(string)
  default = []
}

variable "firewall_tags" {
  type    = list(string)
  default = []
}

variable "firewall_k8s" {
  type    = list(string)
  default = []
}

variable "firewall_ips" {
  type    = list(string)
  default = []
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags merged into all supported resources. Applied as labels on GCP secrets and tags on AWS secrets. GCP requires lowercase keys and values."
}

variable "append_port_to_hostname" {
  type    = bool
  default = false
}

variable "vpc_name" {
  type = string
}

variable "create_vpc" {
  type        = bool
  default     = false
  description = "When true, create a new VPC named vpc_name in region instead of looking up an existing one."
}

variable "vpc_ip_range" {
  type        = string
  default     = null
  description = "CIDR range for the VPC when create_vpc = true. Omit to let DigitalOcean auto-assign one."
}

# GCP Secret Manager

variable "push_gcp_secret" {
  type    = bool
  default = false
}

variable "gcp_project" {
  type        = string
  default     = null
  description = "GCP project ID (required if push_gcp_secret = true or push_metrics_to_gcp_secret = true)"
}

variable "gcp_region" {
  type        = string
  default     = null
  description = "GCP region for Secret Manager (required if push_gcp_secret = true or push_metrics_to_gcp_secret = true)"
}

variable "gcp_secret_regional" {
  type        = bool
  default     = true
  description = "When true, create a regional secret (requires gcp_region). When false, create a global secret with a replication policy (requires gcp_replication)."
}

variable "gcp_replication" {
  type = object({
    automatic = optional(bool, true)
    locations = optional(list(string), [])
  })
  default     = { automatic = true, locations = [] }
  description = "Replication policy for global GCP secrets (used when gcp_secret_regional = false). Set automatic = true for Google-managed replication, or set automatic = false and provide locations for user-managed replication."
}

variable "push_metrics_to_gcp_secret" {
  type    = bool
  default = false
}

# AWS Secrets Manager

variable "push_aws_secret" {
  type    = bool
  default = false
}

variable "aws_region" {
  type        = string
  default     = null
  description = "AWS region for Secrets Manager (required if push_aws_secret = true or push_metrics_to_aws_secret = true)"
}

variable "aws_replicas" {
  type = list(object({
    region     = string
    kms_key_id = optional(string, null)
  }))
  default     = []
  description = "Regions to replicate each AWS secret into. kms_key_id defaults to aws/secretsmanager in that region."
}

variable "push_metrics_to_aws_secret" {
  type    = bool
  default = false
}
