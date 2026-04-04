# do_db

Terraform module for provisioning a DigitalOcean managed database cluster with optional connection pooling, firewall rules, and GCP Secret Manager integration.

## Features

- Provisions a DigitalOcean managed database cluster (PostgreSQL or other supported engines)
- Creates databases and users
- Configures connection pools (PgBouncer) for PostgreSQL clusters — one pool per user/database combination
- Sets up database firewall rules (droplets, tags, Kubernetes clusters, IP addresses)
- Optionally stores connection credentials in GCP Secret Manager (regional)
- Optionally stores database metrics credentials in GCP Secret Manager

## Usage

```hcl
module "db" {
  source = "git::https://gitlab-ca-tor-1.yeetbox.net/terraform/postgresdb.git"

  stack_name     = "myapp"
  engine         = "pg"
  engine_version = "16"
  region         = "tor1"
  vpc_name       = "my-vpc"
  project_id     = "abc123"

  db_names = ["myapp"]
  db_users = ["myapp"]

  instance_size = "db-s-1vcpu-1gb"
  node_count    = 1

  firewall_tags = ["my-k8s-tag"]

  push_gcp_secret    = true
  gcp_project        = "my-gcp-project"
  gcp_region         = "northamerica-northeast2"
}
```

## Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `stack_name` | `string` | — | Name prefix for all resources |
| `engine` | `string` | — | Database engine (e.g. `pg`, `mysql`, `redis`) |
| `engine_version` | `string` | — | Engine version |
| `region` | `string` | — | DigitalOcean region slug |
| `vpc_name` | `string` | — | Name of the existing DigitalOcean VPC |
| `project_id` | `string` | — | DigitalOcean project ID |
| `db_names` | `list` | `[]` | Database names to create |
| `db_users` | `list` | `[]` | Database users to create |
| `instance_size` | `string` | `db-s-1vcpu-1gb` | Cluster instance size |
| `node_count` | `number` | `1` | Number of nodes |
| `backup_source` | `string` | `""` | Restore from a backup of this database name |
| `conn_pool_size` | `number` | `5` | Connection pool size (PostgreSQL only) |
| `conn_pool_mode` | `string` | `transaction` | PgBouncer pool mode (PostgreSQL only) |
| `firewall_droplets` | `list` | `[]` | Droplet IDs to allow |
| `firewall_tags` | `list` | `[]` | DigitalOcean tags to allow |
| `firewall_k8s` | `list` | `[]` | Kubernetes cluster UUIDs to allow |
| `firewall_ips` | `list` | `[]` | IP addresses to allow |
| `push_gcp_secret` | `bool` | `false` | Push connection credentials to GCP Secret Manager |
| `gcp_project` | `string` | — | GCP project ID (required if pushing secrets) |
| `gcp_region` | `string` | — | GCP region for Secret Manager (required if pushing secrets) |
| `append_port_to_hostname` | `bool` | `false` | Append `:port` to the `db_host` value in secrets |
| `push_metrics_to_gcp_secret` | `bool` | `false` | Push metrics credentials to GCP Secret Manager |

## GCP Secret Structure

When `push_gcp_secret = true`, a regional secret is created per user (or per user/database pool combination for PostgreSQL). The secret value is JSON:

```json
{
  "db_host": "host[:port]",
  "db_port": 25060,
  "db_user": "myuser",
  "db_password": "...",
  "db_name": "mydb"
}
```

Secret IDs follow the pattern:
- With connection pools: `{stack_name}-db-{user}-{db_name}`
- Without pools: `{stack_name}-db-user-{user}`

When `push_metrics_to_gcp_secret = true`, a secret named `{stack_name}-db-metrics` is created:

```json
{
  "metrics_username": "...",
  "metrics_password": "...",
  "metrics_endpoint": { ... }
}
```

## Providers

| Provider | Source |
|----------|--------|
| `digitalocean` | `digitalocean/digitalocean` |
| `google` | `hashicorp/google` |
