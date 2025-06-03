# Outputs pour l'environnement Production
# Informations importantes exposées après déploiement

# Outputs généraux
output "project_id" {
  description = "ID du projet GCP"
  value       = var.project_id
}

output "environment" {
  description = "Nom de l'environnement"
  value       = local.environment
}

output "region" {
  description = "Région de déploiement"
  value       = var.region
}

# Outputs réseau
output "vpc_network_name" {
  description = "Nom du réseau VPC"
  value       = module.networking.vpc_network_name
}

output "vpc_network_id" {
  description = "ID du réseau VPC"
  value       = module.networking.vpc_network_id
}

output "private_subnet_name" {
  description = "Nom du sous-réseau privé"
  value       = module.networking.private_subnet_name
}

output "private_subnet_cidr" {
  description = "CIDR du sous-réseau privé"
  value       = module.networking.private_subnet_cidr
}

output "public_subnet_name" {
  description = "Nom du sous-réseau public"
  value       = module.networking.public_subnet_name
}

output "vpc_connector_name" {
  description = "Nom du connecteur VPC"
  value       = module.networking.vpc_connector_name
}

output "nat_gateway_ip" {
  description = "IP externe de la passerelle NAT"
  value       = module.networking.nat_gateway_ip
}

# Outputs Cloud SQL
output "database_instance_name" {
  description = "Nom de l'instance Cloud SQL"
  value       = module.cloud_sql.instance_name
}

output "database_connection_name" {
  description = "Nom de connexion Cloud SQL"
  value       = module.cloud_sql.connection_name
  sensitive   = true
}

output "database_private_ip" {
  description = "IP privée de l'instance Cloud SQL"
  value       = module.cloud_sql.private_ip_address
  sensitive   = true
}

output "database_server_ca_cert" {
  description = "Certificat CA du serveur de base de données"
  value       = module.cloud_sql.server_ca_cert
  sensitive   = true
}

output "read_replica_connection_names" {
  description = "Noms de connexion des réplicas de lecture"
  value       = module.cloud_sql.read_replica_connection_names
  sensitive   = true
}

# Outputs Cloud Run
output "cloud_run_service_name" {
  description = "Nom du service Cloud Run"
  value       = module.cloud_run.service_name
}

output "cloud_run_service_url" {
  description = "URL du service Cloud Run"
  value       = module.cloud_run.service_url
}

output "cloud_run_service_location" {
  description = "Région du service Cloud Run"
  value       = module.cloud_run.service_location
}

output "cloud_run_latest_revision" {
  description = "Dernière révision du service Cloud Run"
  value       = module.cloud_run.latest_revision_name
}

# Outputs IAM
output "cloud_run_service_account_email" {
  description = "Email du service account Cloud Run"
  value       = module.iam.cloud_run_service_account_email
}

output "cloud_run_service_account_name" {
  description = "Nom du service account Cloud Run"
  value       = module.iam.cloud_run_service_account_name
}

output "cloudsql_service_account_email" {
  description = "Email du service account Cloud SQL"
  value       = module.iam.cloudsql_service_account_email
}

# Outputs Monitoring
output "monitoring_notification_channels" {
  description = "Canaux de notification configurés"
  value       = module.monitoring.notification_channels
}

output "monitoring_dashboard_url" {
  description = "URL du dashboard de monitoring"
  value       = module.monitoring.dashboard_url
}

output "budget_alert_name" {
  description = "Nom de l'alerte de budget"
  value       = module.monitoring.budget_name
}

# Outputs sécurité et secrets
output "secret_manager_secrets" {
  description = "Liste des secrets créés dans Secret Manager"
  value       = module.cloud_sql.secret_names
  sensitive   = true
}

# Outputs pour l'intégration
output "environment_variables" {
  description = "Variables d'environnement pour l'application"
  value = {
    SPRING_PROFILES_ACTIVE    = local.environment
    DB_NAME                  = local.database_config.database_name
    DB_USER                  = local.database_config.user_name
    INSTANCE_CONNECTION_NAME = module.cloud_sql.connection_name
    ENVIRONMENT             = local.environment
  }
  sensitive = true
}

# Outputs pour les tests et validation
output "health_check_url" {
  description = "URL du health check de l'application"
  value       = "${module.cloud_run.service_url}/actuator/health"
}

output "api_base_url" {
  description = "URL de base de l'API"
  value       = "${module.cloud_run.service_url}/api"
}

# Outputs pour le CI/CD
output "artifact_registry_repository" {
  description = "Repository Artifact Registry"
  value       = "europe-west1-docker.pkg.dev/${var.project_id}/data-centralization-registry"
}

output "docker_image_url" {
  description = "URL de l'image Docker"
  value       = local.cloud_run_config.image_url
}

# Outputs pour la documentation
output "deployment_info" {
  description = "Informations de déploiement"
  value = {
    environment                = local.environment
    region                    = var.region
    vpc_network               = module.networking.vpc_network_name
    cloud_run_service         = module.cloud_run.service_name
    cloud_sql_instance        = module.cloud_sql.instance_name
    high_availability_enabled = var.high_availability
    read_replicas_count       = var.read_replica_count
    min_instances            = var.cloud_run_min_instances
    max_instances            = var.cloud_run_max_instances
    cpu_limit                = var.cloud_run_cpu_limit
    memory_limit             = var.cloud_run_memory_limit
    backup_retention_days    = var.backup_retention_days
    ssl_mode                 = var.ssl_mode
    monitoring_enabled       = var.enable_monitoring
    audit_logs_enabled       = var.enable_audit_logs
  }
}

# Outputs pour le monitoring externe
output "monitoring_endpoints" {
  description = "Points de terminaison pour le monitoring externe"
  value = {
    health_check = "${module.cloud_run.service_url}/actuator/health"
    metrics      = "${module.cloud_run.service_url}/actuator/metrics"
    info         = "${module.cloud_run.service_url}/actuator/info"
    prometheus   = "${module.cloud_run.service_url}/actuator/prometheus"
  }
}

# Outputs pour la sauvegarde et restauration
output "backup_configuration" {
  description = "Configuration des sauvegardes"
  value = {
    backup_enabled              = true
    backup_retention_days       = var.backup_retention_days
    backup_location            = var.backup_location
    backup_location_secondary  = var.backup_location_secondary
    point_in_time_recovery     = var.point_in_time_recovery
    cross_region_backup        = var.backup_cross_region
    maintenance_window_day     = var.maintenance_window_day
    maintenance_window_hour    = var.maintenance_window_hour
  }
}

# Outputs pour les coûts
output "cost_allocation_labels" {
  description = "Labels pour l'allocation des coûts"
  value = {
    environment  = local.environment
    project      = var.labels.project
    team         = var.labels.team
    cost_center  = var.labels.cost-center
  }
}

# Outputs pour la conformité
output "compliance_info" {
  description = "Informations de conformité"
  value = {
    data_classification       = var.labels.data-class
    backup_required          = var.labels.backup
    monitoring_level         = var.labels.monitoring
    compliance_required      = var.labels.compliance
    deletion_protection      = var.deletion_protection
    ssl_enforced            = var.require_ssl
    ssl_mode                = var.ssl_mode
    audit_logs_enabled      = var.enable_audit_logs
    log_retention_days      = var.log_retention_days
    pgaudit_enabled         = var.enable_pgaudit
  }
}

# Summary output pour documentation automatique
output "deployment_summary" {
  description = "Résumé complet du déploiement production"
  value = {
    # Infrastructure
    project_id    = var.project_id
    environment   = local.environment
    region        = var.region
    
    # Services déployés
    services = {
      cloud_run = {
        name = module.cloud_run.service_name
        url  = module.cloud_run.service_url
      }
      cloud_sql = {
        name = module.cloud_sql.instance_name
        type = "PostgreSQL 14"
        tier = var.database_tier
        ha   = var.high_availability
      }
      vpc = {
        name = module.networking.vpc_network_name
        cidr = var.vpc_cidr_range
      }
    }
    
    # Configuration critique
    critical_config = {
      min_instances           = var.cloud_run_min_instances
      max_instances          = var.cloud_run_max_instances
      database_backup_days   = var.backup_retention_days
      ssl_required          = var.require_ssl
      deletion_protection   = var.deletion_protection
      monitoring_enabled    = var.enable_monitoring
    }
    
    # Accès
    access_points = {
      application_url = module.cloud_run.service_url
      health_check   = "${module.cloud_run.service_url}/actuator/health"
      metrics        = "${module.cloud_run.service_url}/actuator/metrics"
    }
  }
} 