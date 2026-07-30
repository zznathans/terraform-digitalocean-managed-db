# terraform-digitalocean-managed-db

Terraform module for provisioning a DigitalOcean managed database cluster with optional connection pooling, firewall rules, and credential storage in GCP Secret Manager and/or AWS Secrets Manager.

## Features

- Provisions a DigitalOcean managed database cluster (PostgreSQL, MySQL, or Redis)
- Creates databases and users
- Configures PgBouncer connection pools for PostgreSQL — one pool per user/database pair
- Sets up database firewall rules (droplets, tags, Kubernetes clusters, IP addresses) — skipped when all lists are empty
- Attaches the cluster to a VPC — either an existing one, or a new one created alongside the cluster
- Attaches the cluster to a project — either an existing one, or a new one created alongside the cluster
- Optionally restores from a backup
- Optionally stores connection credentials in GCP Secret Manager (regional)
- Optionally stores database metrics credentials in GCP Secret Manager
- Optionally stores connection credentials in AWS Secrets Manager with cross-region replication support
- Optionally stores database metrics credentials in AWS Secrets Manager

## Requirements

| Name | Version |
|------|---------|
| Terraform / OpenTofu | `>= 1.3.0` |
| [digitalocean](https://registry.terraform.io/providers/digitalocean/digitalocean/latest) | `~> 2.0` |
| [google](https://registry.terraform.io/providers/hashicorp/google/latest) | `>= 4.0` — only if `push_gcp_secret = true` or `push_metrics_to_gcp_secret = true` |
| [aws](https://registry.terraform.io/providers/hashicorp/aws/latest) | `>= 5.0` — only if `push_aws_secret = true` or `push_metrics_to_aws_secret = true` |

> **Note:** All three providers are declared in `required_providers`, so OpenTofu will initialise them regardless of feature flags. Configure credentials only for the providers you use; unconfigured providers will not cause failures when their feature flags are `false`.

## Usage

```hcl
module "db" {
  source = "git::https://github.com/zznathans/terraform-digitalocean-managed-db.git"

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

  tags = { env = "production", team = "platform" }

  firewall_tags = ["my-k8s-tag"]

  push_gcp_secret = true
  gcp_project     = "my-gcp-project"
  gcp_region      = "northamerica-northeast2"

  push_aws_secret = true
  aws_region      = "us-east-1"
}
```

### With a dedicated VPC and project

By default `vpc_name` must match an existing VPC and `project_id` must match an existing project. Set `create_vpc` / `create_project` to have the module create them instead:

```hcl
module "db" {
  source = "git::https://github.com/zznathans/terraform-digitalocean-managed-db.git"

  stack_name     = "myapp"
  engine         = "mysql"
  engine_version = "8"
  region         = "nyc1"

  vpc_name   = "myapp-vpc"
  create_vpc = true

  project_name   = "myapp"
  create_project = true

  db_names = ["myapp"]
  db_users = ["myapp"]
}
```

### With metrics and cross-region AWS replication

```hcl
module "db" {
  source = "git::https://github.com/zznathans/terraform-digitalocean-managed-db.git"

  stack_name     = "myapp"
  engine         = "pg"
  engine_version = "16"
  region         = "nyc1"
  vpc_name       = "my-vpc"
  project_id     = "abc123"

  db_names = ["myapp"]
  db_users = ["myapp"]

  push_gcp_secret            = true
  push_metrics_to_gcp_secret = true
  gcp_project                = "my-gcp-project"
  gcp_region                 = "us-east1"

  push_aws_secret            = true
  push_metrics_to_aws_secret = true
  aws_region                 = "us-east-1"
  aws_replicas = [
    { region = "us-west-2" },
    { region = "eu-west-1", kms_key_id = "arn:aws:kms:eu-west-1:123456789012:key/mrk-abc123" }
  ]
}
```

### With GCP global secret (automatic replication)

```hcl
module "db" {
  source = "git::https://github.com/zznathans/terraform-digitalocean-managed-db.git"

  stack_name     = "myapp"
  engine         = "pg"
  engine_version = "16"
  region         = "nyc1"
  vpc_name       = "my-vpc"
  project_id     = "abc123"

  db_names = ["myapp"]
  db_users = ["myapp"]

  push_gcp_secret     = true
  gcp_project         = "my-gcp-project"
  gcp_secret_regional = false
  gcp_replication     = { automatic = true }
}
```

### With GCP global secret (user-managed replication)

```hcl
module "db" {
  source = "git::https://github.com/zznathans/terraform-digitalocean-managed-db.git"

  stack_name     = "myapp"
  engine         = "pg"
  engine_version = "16"
  region         = "nyc1"
  vpc_name       = "my-vpc"
  project_id     = "abc123"

  db_names = ["myapp"]
  db_users = ["myapp"]

  push_gcp_secret     = true
  gcp_project         = "my-gcp-project"
  gcp_secret_regional = false
  gcp_replication = {
    automatic = false
    locations = ["us-central1", "us-east1"]
  }
}
```

## Variables

### Core

| Name | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| `stack_name` | `string` | — | yes | Name prefix applied to all resources |
| `engine` | `string` | — | yes | Database engine: `pg`, `mysql`, or `redis` |
| `engine_version` | `string` | — | yes | Engine version (e.g. `16`) |
| `region` | `string` | — | yes | DigitalOcean region slug (e.g. `tor1`, `nyc1`) |
| `vpc_name` | `string` | — | yes | Name of the VPC to attach the cluster to — an existing VPC by default, or a newly created one when `create_vpc = true` |
| `create_vpc` | `bool` | `false` | no | When `true`, create a new VPC named `vpc_name` in `region` instead of looking up an existing one |
| `vpc_ip_range` | `string` | `null` | no | CIDR range for the VPC when `create_vpc = true`. Omit to let DigitalOcean auto-assign one. |
| `project_id` | `string` | `null` | no* | Existing DigitalOcean project ID to attach the cluster to. *Required unless `create_project = true`. |
| `create_project` | `bool` | `false` | no | When `true`, create a new DigitalOcean project named `project_name` and attach the cluster to it, instead of using an existing `project_id` |
| `project_name` | `string` | `null` | no | Name for the new project when `create_project = true` |
| `instance_size` | `string` | `"db-s-1vcpu-1gb"` | no | Cluster node size slug |
| `node_count` | `number` | `1` | no | Number of nodes in the cluster |
| `db_names` | `list(string)` | `[]` | no | Database names to create |
| `db_users` | `list(string)` | `[]` | no | Database users to create |
| `backup_source` | `string` | `""` | no | Name of a database to restore from backup (omit to start fresh) |
| `tags` | `map(string)` | `{}` | no | Tags merged into all supported resources. Applied as labels on GCP secrets and tags on AWS secrets. GCP requires lowercase keys and values. |

### Connection pooling (PostgreSQL only)

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `conn_pool_size` | `number` | `5` | PgBouncer pool size per pool |
| `conn_pool_mode` | `string` | `"transaction"` | PgBouncer mode: `transaction`, `session`, or `statement` |
| `append_port_to_hostname` | `bool` | `false` | When `true`, the `db_host` field in secrets is `host:port` instead of just `host` |

### Firewall

All lists default to `[]`. The firewall resource is only created when at least one list is non-empty.

| Name | Type | Description |
|------|------|-------------|
| `firewall_droplets` | `list(string)` | Droplet IDs to allow |
| `firewall_tags` | `list(string)` | DigitalOcean tags to allow |
| `firewall_k8s` | `list(string)` | Kubernetes cluster UUIDs to allow |
| `firewall_ips` | `list(string)` | IP addresses to allow |

### GCP Secret Manager

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `push_gcp_secret` | `bool` | `false` | Push connection credentials to GCP Secret Manager |
| `push_metrics_to_gcp_secret` | `bool` | `false` | Push metrics credentials to GCP Secret Manager |
| `gcp_project` | `string` | `null` | GCP project ID (required if either GCP flag is `true`) |
| `gcp_secret_regional` | `bool` | `true` | `true` = regional secret (requires `gcp_region`); `false` = global secret with replication policy (requires `gcp_replication`) |
| `gcp_region` | `string` | `null` | GCP region for regional secrets (required when `gcp_secret_regional = true`) |
| `gcp_replication` | `object` | `{automatic=true}` | Replication policy for global secrets (used when `gcp_secret_regional = false`) |

#### `gcp_replication` object

Only used when `gcp_secret_regional = false`.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `automatic` | `bool` | `true` | `true` = Google-managed automatic replication; `false` = user-managed replication to specific `locations` |
| `locations` | `list(string)` | `[]` | GCP regions to replicate into (e.g. `["us-central1", "us-east1"]`). Only used when `automatic = false`. |

### AWS Secrets Manager

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `push_aws_secret` | `bool` | `false` | Push connection credentials to AWS Secrets Manager |
| `push_metrics_to_aws_secret` | `bool` | `false` | Push metrics credentials to AWS Secrets Manager |
| `aws_region` | `string` | `null` | AWS region for Secrets Manager (required if either AWS flag is `true`) |
| `aws_replicas` | `list(object)` | `[]` | Additional regions to replicate each AWS secret into (see below) |

#### `aws_replicas` object

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `region` | `string` | — | AWS region to replicate the secret into |
| `kms_key_id` | `string` | `null` | ARN, key ID, or alias of the KMS key in the replica region. Omit to use `aws/secretsmanager`. |

## Outputs

| Name | Description |
|------|-------------|
| `cluster_id` | DigitalOcean cluster ID |
| `cluster_host` | Public hostname of the cluster |
| `cluster_private_host` | Private hostname (within the VPC) |
| `cluster_port` | Port the cluster listens on |
| `cluster_uri` | Full connection URI (sensitive) |
| `cluster_private_uri` | Full private connection URI (sensitive) |

## Secret structure

### Connection credentials

One secret is created per user (or per user/database pool for PostgreSQL). The secret ID follows the pattern:

- With connection pools: `{stack_name}-db-{user}-{db_name}`
- Without pools: `{stack_name}-db-user-{user}`

```json
{
  "db_host":     "private-host[:port]",
  "db_port":     25060,
  "db_user":     "myuser",
  "db_password": "...",
  "db_name":     "mydb"
}
```

`db_name` is `null` when no database name is associated with the user. `db_host` includes the port suffix when `append_port_to_hostname = true`.

### Metrics credentials

One secret named `{stack_name}-db-metrics` is created when `push_metrics_to_gcp_secret = true` or `push_metrics_to_aws_secret = true`.

```json
{
  "metrics_username": "...",
  "metrics_password": "...",
  "metrics_endpoint": "..."
}
```

## CI/CD

Validation runs on all pull requests. Releases are cut automatically from `main` using [semantic-release](https://semantic-release.gitbook.io/) based on conventional commits.

The `GITHUB_TOKEN` secret is provided automatically by GitHub Actions. No additional secrets are required for CI validation — providers are initialised without credentials and `tofu validate` does not contact any APIs.

For deployments that use the GCP or AWS integrations, the runner must have credentials available:

| Provider | Credential |
|----------|-----------|
| DigitalOcean | `DIGITALOCEAN_TOKEN` environment variable |
| GCP | `GOOGLE_APPLICATION_CREDENTIALS` pointing to a service account key with `roles/secretmanager.admin` |
| AWS | Standard AWS credential chain (`AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` or an instance role) with `secretsmanager:CreateSecret`, `secretsmanager:PutSecretValue`, `secretsmanager:TagResource`, and `secretsmanager:ReplicateSecretToRegions` |

## Resources

| Resource | Condition |
|----------|-----------|
| `digitalocean_database_cluster.cluster` | Always |
| `digitalocean_vpc.this` | When `create_vpc = true` |
| `digitalocean_project.this` | When `create_project = true` |
| `digitalocean_database_db.db` | One per entry in `db_names` |
| `digitalocean_database_user.user` | One per entry in `db_users` |
| `digitalocean_database_connection_pool.pool` | PostgreSQL only; one per user/db pair |
| `digitalocean_database_firewall.firewall` | When at least one firewall list is non-empty |
| `google_secret_manager_regional_secret.user` | When `push_gcp_secret = true` and `gcp_secret_regional = true` |
| `google_secret_manager_regional_secret.metrics` | When `push_metrics_to_gcp_secret = true` and `gcp_secret_regional = true` |
| `google_secret_manager_secret.user` | When `push_gcp_secret = true` and `gcp_secret_regional = false` |
| `google_secret_manager_secret.metrics` | When `push_metrics_to_gcp_secret = true` and `gcp_secret_regional = false` |
| `aws_secretsmanager_secret.user` | When `push_aws_secret = true` |
| `aws_secretsmanager_secret.metrics` | When `push_metrics_to_aws_secret = true` |
