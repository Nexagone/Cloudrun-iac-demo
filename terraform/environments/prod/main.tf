# Configuration Terraform - Environnement Production
terraform {
  required_version = ">= 1.5"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
  
  # Backend configuré pour la production avec encryption
  backend "gcs" {
    bucket  = "terraform-state-prod-data-centralization"
    prefix  = "terraform/state"
    encryption_key = "your-encryption-key-for-prod"
  }
}

# Configuration du provider Google pour la production
provider "google" {
  project = var.project_id
  region  = var.region
  
  # Configuration spécifique production
  user_project_override = true
  billing_project       = var.project_id
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
  
  user_project_override = true
  billing_project       = var.project_id
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
    terraform     = "true"
    environment   = local.environment
    deployed-by   = "terraform"
    created-date  = formatdate("YYYY-MM-DD", timestamp())
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

# Module Networking - Configuration production avec redondance
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

# Module IAM - Sécurité renforcée pour la production
module "iam" {
  source = "../../modules/iam"
  
  project_name = var.project_name
  project_id   = var.project_id
  environment  = local.environment
  
  workload_identity_users = var.workload_identity_users
  
  depends_on = [module.networking]
}

# Module Cloud SQL - Configuration haute disponibilité
module "cloud_sql" {
  source = "../../modules/cloud-sql"
  
  project_name    = var.project_name
  environment     = local.environment
  region          = var.region
  
  # Configuration instance principale
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
  
  depends_on = [module.networking, module.iam]
}

# Module Cloud Run - Configuration production avec scaling
module "cloud_run" {
  source = "../../modules/cloud-run"
  
  project_name = var.project_name
  project_id   = var.project_id
  environment  = local.environment
  region       = var.region
  
  # Image
  image_url = local.cloud_run_config.image_url
  
  # Service Account
  service_account_email = module.iam.cloud_run_service_account_email
  
  # Configuration performance production
  cpu_limit    = var.cloud_run_cpu_limit
  memory_limit = var.cloud_run_memory_limit
  min_instances = var.cloud_run_min_instances
  max_instances = var.cloud_run_max_instances
  
  # Base de données
  sql_connection_name      = module.cloud_sql.instance_connection_name
  database_name           = module.cloud_sql.database_name
  database_user           = module.cloud_sql.app_user
  db_password_secret_name = module.cloud_sql.app_password_secret_name
  
  # Variables d'environnement
  environment_variables = {
    SPRING_PROFILES_ACTIVE     = local.environment
    DB_NAME                   = local.database_config.database_name
    DB_USER                   = local.database_config.user_name
    INSTANCE_CONNECTION_NAME  = module.cloud_sql.instance_connection_name
    ENVIRONMENT              = local.environment
    LOG_LEVEL               = "INFO"
    JVM_OPTS                = "-Xmx1536m -XX:+UseG1GC -XX:MaxGCPauseMillis=200"
  }
  
  # Réseau
  network_name = module.networking.network_name
  
  labels = local.common_labels
  
  depends_on = [module.networking, module.iam, module.cloud_sql]
}

# Module Monitoring - Surveillance complète production
module "monitoring" {
  source = "../../modules/monitoring"
  
  project_name = var.project_name
  project_id   = var.project_id
  environment  = local.environment
  region       = var.region
  
  service_name = module.cloud_run.service_name
  service_url  = module.cloud_run.service_url
  sql_instance_name = module.cloud_sql.instance_name
  
  # Notifications
  notification_emails = var.notification_emails
  slack_webhook_url  = var.slack_webhook_url
  
  # Seuils d'alerte
  latency_threshold_ms      = var.latency_threshold_ms
  error_rate_threshold      = var.error_rate_threshold
  cpu_threshold            = var.cpu_threshold
  memory_threshold         = var.memory_threshold
  sql_connections_threshold = var.sql_connections_threshold
  
  # Logs
  enable_log_sink  = var.enable_log_sink
  bigquery_dataset = "${var.project_name}_${local.environment}_logs"
  
  labels = local.common_labels
  
  depends_on = [module.cloud_run, module.cloud_sql]
} 