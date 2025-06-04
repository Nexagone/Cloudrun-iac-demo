# Configuration Terraform - Environnement Production
terraform {
  required_version = ">= 1.5"
  
  backend "gcs" {
    # Configuration dans backend.conf
  }
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# Configuration du provider Google
provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# Activation des APIs nécessaires
resource "google_project_service" "apis" {
  for_each = toset([
    "run.googleapis.com",
    "sql-component.googleapis.com",
    "sqladmin.googleapis.com",
    "secretmanager.googleapis.com",
    "compute.googleapis.com",
    "servicenetworking.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "bigquery.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "vpcaccess.googleapis.com"
  ])
  
  project = var.project_id
  service = each.value
  
  disable_dependent_services = false
  disable_on_destroy        = false
}

# Data sources
data "google_project" "current" {
  project_id = var.project_id
}

data "google_client_config" "current" {}

# Variables locales pour la production
locals {
  environment = "prod"
  
  # Configuration spécifique production
  common_labels = merge(var.labels, {
    environment  = var.environment
    project      = var.project_name
    managed-by   = "terraform"
  })
  
  # Configuration réseau production
  network_config = {
    vpc_name             = "${local.environment}-vpc"
    private_subnet_name  = "${local.environment}-private-subnet"
    public_subnet_name   = "${local.environment}-public-subnet"
    nat_name            = "${local.environment}-nat-gateway"
    router_name         = "${local.environment}-router"
  }
  
  # Configuration base de données production
  database_config = {
    instance_name       = "${local.environment}-postgres-instance"
    database_name       = "data_centralization"
    user_name          = "app_user"
    backup_config = {
      enabled                        = true
      start_time                    = "03:00"
      location                      = var.backup_location
      point_in_time_recovery_enabled = var.point_in_time_recovery
      transaction_log_retention_days = 7
      retained_backups              = var.backup_retention_days
    }
  }
  
  # Configuration Cloud Run production
  cloud_run_config = {
    service_name = "data-centralization-${local.environment}-service"
    image_url    = "europe-west1-docker.pkg.dev/${var.project_id}/data-centralization-registry/app:latest"
  }
}

# Module Networking
module "networking" {
  source = "../../modules/networking"
  
  project_name           = var.project_name
  region                = var.region
  services_subnet_cidr  = var.services_subnet_cidr
  database_subnet_cidr  = var.database_subnet_cidr
  services_secondary_cidr = var.services_secondary_cidr
  labels                = local.common_labels
  
  depends_on = [google_project_service.apis]
}

# Module IAM
module "iam" {
  source = "../../modules/iam"
  
  project_name = var.project_name
  project_id   = var.project_id
  environment  = var.environment
  
  workload_identity_users = var.workload_identity_users
  
  depends_on = [google_project_service.apis]
}

# Module Cloud SQL
module "cloud_sql" {
  source = "../../modules/cloud-sql"
  
  project_name    = var.project_name
  environment     = var.environment
  region          = var.region
  
  # Configuration production
  tier                = var.database_tier
  disk_size          = var.disk_size
  max_disk_size      = var.max_disk_size
  max_connections    = var.max_connections
  database_name      = var.database_name
  app_user           = var.database_user
  
  # Sécurité
  deletion_protection     = var.deletion_protection
  point_in_time_recovery = var.point_in_time_recovery
  backup_location        = var.backup_location
  
  # Réseau
  network_id               = module.networking.network_id
  private_vpc_connection   = module.networking.private_vpc_connection
  
  labels = local.common_labels
  
  depends_on = [
    google_project_service.apis,
    module.networking
  ]
}

# Artifact Registry pour les images Docker
resource "google_artifact_registry_repository" "docker_repo" {
  location      = var.region
  repository_id = "${var.project_name}-docker"
  description   = "Repository Docker pour ${var.project_name}"
  format        = "DOCKER"
  
  labels = local.common_labels
  
  depends_on = [google_project_service.apis]
}

# Module Cloud Run
module "cloud_run" {
  source = "../../modules/cloud-run"
  
  project_name = var.project_name
  project_id   = var.project_id
  environment  = var.environment
  region       = var.region
  
  # Image Docker
  image_url = var.docker_image_url
  docker_registry_credentials = var.docker_registry
  
  # Service Account
  service_account_email = module.iam.cloud_run_service_account_email
  
  # Configuration performance production
  min_instances = var.cloud_run_min_instances
  max_instances = var.cloud_run_max_instances
  cpu_limit    = var.cloud_run_cpu_limit
  memory_limit = var.cloud_run_memory_limit
  
  # Base de données
  sql_connection_name      = module.cloud_sql.instance_connection_name
  database_name           = module.cloud_sql.database_name
  database_user           = module.cloud_sql.app_user
  db_password_secret_name = module.cloud_sql.app_password_secret_name
  
  # Variables d'environnement
  environment_variables = merge(var.environment_variables, {
    SPRING_PROFILES_ACTIVE = var.environment
  })
  
  # Réseau
  network_name         = module.networking.network_name
  create_vpc_connector = true
  vpc_connector_cidr   = var.vpc_connector_cidr
  
  # Accès
  allow_public_access = var.allow_public_access
  custom_domain      = var.custom_domain
  
  labels = local.common_labels
  
  depends_on = [
    google_project_service.apis,
    module.networking,
    module.iam,
    module.cloud_sql
  ]
}

# Module Monitoring
module "monitoring" {
  source = "../../modules/monitoring"
  
  project_name = var.project_name
  project_id   = var.project_id
  environment  = var.environment
  region       = var.region
  
  service_name        = module.cloud_run.service_name
  service_url         = module.cloud_run.service_url
  sql_instance_name   = module.cloud_sql.instance_name
  
  # Notifications
  notification_emails = var.notification_emails
  slack_webhook_url   = var.slack_webhook_url
  
  # Seuils d'alerte
  latency_threshold_ms      = var.latency_threshold_ms
  error_rate_threshold      = var.error_rate_threshold
  cpu_threshold            = var.cpu_threshold
  memory_threshold         = var.memory_threshold
  sql_connections_threshold = var.sql_connections_threshold
  
  # Logs
  enable_log_sink   = var.enable_log_sink
  bigquery_dataset  = "${var.project_name}_${var.environment}_logs"
  
  labels = local.common_labels
  
  depends_on = [
    google_project_service.apis,
    module.cloud_run
  ]
}

# Budget Alert
resource "google_billing_budget" "budget" {
  count = var.budget_amount > 0 ? 1 : 0
  
  billing_account = var.billing_account
  display_name    = "Budget ${var.project_name} ${var.environment}"
  
  budget_filter {
    projects = ["projects/${var.project_id}"]
    credit_types_treatment = "INCLUDE_ALL_CREDITS"
  }
  
  amount {
    specified_amount {
      currency_code = "EUR"
      units         = tostring(var.budget_amount)
    }
  }
  
  threshold_rules {
    threshold_percent = 0.5
    spend_basis      = "CURRENT_SPEND"
  }
  
  threshold_rules {
    threshold_percent = 0.9
    spend_basis      = "CURRENT_SPEND"
  }
  
  threshold_rules {
    threshold_percent = 1.0
    spend_basis      = "FORECASTED_SPEND"
  }
  
  all_updates_rule {
    monitoring_notification_channels = module.monitoring.notification_channels.email
    disable_default_iam_recipients   = false
  }
} 