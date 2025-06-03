# Outputs pour l'environnement Staging
# Informations importantes pour l'équipe de développement et les tests

# Informations générales
output "project_id" {
  description = "ID du projet Google Cloud"
  value       = var.project_id
}

output "environment" {
  description = "Nom de l'environnement"
  value       = var.environment
}

output "region" {
  description = "Région principale"
  value       = var.region
}

# Informations réseau
output "vpc_name" {
  description = "Nom du VPC"
  value       = module.networking.vpc_name
}

output "vpc_id" {
  description = "ID du VPC"
  value       = module.networking.vpc_id
}

output "private_subnet_name" {
  description = "Nom du sous-réseau privé"
  value       = module.networking.private_subnet_name
}

output "public_subnet_name" {
  description = "Nom du sous-réseau public"
  value       = module.networking.public_subnet_name
}

output "nat_gateway_name" {
  description = "Nom de la passerelle NAT"
  value       = module.networking.nat_gateway_name
}

# Cloud SQL - Informations de connexion
output "database_instance_name" {
  description = "Nom de l'instance Cloud SQL"
  value       = module.cloud_sql.instance_name
}

output "database_connection_name" {
  description = "Nom de connexion Cloud SQL (pour Cloud Run)"
  value       = module.cloud_sql.connection_name
}

output "database_private_ip" {
  description = "Adresse IP privée de la base de données"
  value       = module.cloud_sql.private_ip_address
  sensitive   = true
}

output "database_public_ip" {
  description = "Adresse IP publique de la base de données (si activée)"
  value       = module.cloud_sql.public_ip_address
  sensitive   = true
}

output "database_name" {
  description = "Nom de la base de données"
  value       = module.cloud_sql.database_name
}

output "database_user" {
  description = "Utilisateur de la base de données"
  value       = module.cloud_sql.database_user
  sensitive   = true
}

# Informations des réplicas (staging en a 1)
output "database_replica_names" {
  description = "Noms des réplicas de lecture"
  value       = module.cloud_sql.replica_names
}

output "database_replica_connection_names" {
  description = "Noms de connexion des réplicas"
  value       = module.cloud_sql.replica_connection_names
}

# Cloud Run - Service
output "cloud_run_service_name" {
  description = "Nom du service Cloud Run"
  value       = module.cloud_run.service_name
}

output "cloud_run_service_url" {
  description = "URL du service Cloud Run"
  value       = module.cloud_run.service_url
}

output "cloud_run_service_id" {
  description = "ID du service Cloud Run"
  value       = module.cloud_run.service_id
}

output "cloud_run_latest_revision" {
  description = "Dernière révision du service"
  value       = module.cloud_run.latest_revision_name
}

# Configuration Cloud Run (staging)
output "cloud_run_configuration" {
  description = "Configuration du service Cloud Run pour staging"
  value = {
    cpu_limit         = var.cloud_run_cpu_limit
    memory_limit      = var.cloud_run_memory_limit
    min_instances     = var.cloud_run_min_instances
    max_instances     = var.cloud_run_max_instances
    concurrency       = var.cloud_run_concurrency
    timeout_seconds   = var.cloud_run_timeout_seconds
    cpu_throttling    = var.cloud_run_cpu_throttling
  }
}

# Service Accounts
output "cloud_run_service_account_email" {
  description = "Email du service account Cloud Run"
  value       = module.iam.cloud_run_service_account_email
}

output "cloud_sql_service_account_email" {
  description = "Email du service account Cloud SQL"
  value       = module.iam.cloud_sql_service_account_email
}

# Artifact Registry
output "artifact_registry_repository" {
  description = "Nom du repository Artifact Registry"
  value       = module.artifact_registry.repository_name
}

output "artifact_registry_location" {
  description = "Localisation du repository"
  value       = module.artifact_registry.repository_location
}

output "docker_image_base_url" {
  description = "URL de base pour les images Docker"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${module.artifact_registry.repository_name}"
}

# Secrets Manager
output "secret_manager_secrets" {
  description = "Secrets créés dans Secret Manager"
  value       = module.secret_manager.secret_names
}

output "database_credentials_secret" {
  description = "Nom du secret contenant les credentials de la base"
  value       = module.secret_manager.database_credentials_secret_name
  sensitive   = true
}

# Monitoring
output "monitoring_dashboard_url" {
  description = "URL du dashboard de monitoring (staging)"
  value       = module.monitoring.dashboard_url
}

output "alerting_policies" {
  description = "Politiques d'alerte configurées"
  value       = module.monitoring.alert_policy_names
}

output "uptime_check_ids" {
  description = "IDs des vérifications de disponibilité"
  value       = module.monitoring.uptime_check_ids
}

# Budget et coûts
output "budget_name" {
  description = "Nom du budget configuré"
  value       = module.billing.budget_name
}

output "budget_amount" {
  description = "Montant du budget (staging: 250€/mois)"
  value       = var.budget_amount
}

# Informations de sécurité (staging)
output "security_configuration" {
  description = "Configuration de sécurité pour staging"
  value = {
    private_ip_only     = var.enable_private_ip
    ssl_redirect        = var.enable_ssl_redirect
    cloud_armor         = var.enable_armor
    audit_logs          = var.enable_audit_logs
    deletion_protection = var.deletion_protection
    ssl_mode           = var.ssl_mode
    require_ssl        = var.require_ssl
  }
  sensitive = true
}

# Informations de backup (staging avec cross-région)
output "backup_configuration" {
  description = "Configuration des sauvegardes"
  value = {
    retention_days        = var.backup_retention_days
    location_primary      = var.backup_location
    location_secondary    = var.backup_location_secondary
    cross_region_enabled  = var.backup_cross_region
    point_in_time_recovery = var.enable_point_in_time_recovery
  }
}

# Informations de performance (staging)
output "performance_configuration" {
  description = "Configuration de performance pour staging"
  value = {
    database_tier            = var.database_tier
    disk_size               = var.disk_size
    max_disk_size          = var.max_disk_size
    high_availability      = var.high_availability
    read_replica_count     = var.read_replica_count
    connection_pooling     = var.enable_connection_pooling
    max_connections        = var.max_connections
    shared_preload_libraries = var.shared_preload_libraries
  }
}

# URLs importantes pour l'équipe
output "important_urls" {
  description = "URLs importantes pour l'environnement staging"
  value = {
    cloud_run_service      = module.cloud_run.service_url
    monitoring_dashboard   = module.monitoring.dashboard_url
    cloud_sql_console     = "https://console.cloud.google.com/sql/instances/${module.cloud_sql.instance_name}/overview?project=${var.project_id}"
    cloud_run_console     = "https://console.cloud.google.com/run/detail/${var.region}/${module.cloud_run.service_name}/metrics?project=${var.project_id}"
    artifact_registry     = "https://console.cloud.google.com/artifacts/docker/${var.project_id}/${var.region}/${module.artifact_registry.repository_name}?project=${var.project_id}"
    logs_explorer         = "https://console.cloud.google.com/logs/query?project=${var.project_id}"
  }
}

# Informations de connexion pour les développeurs
output "developer_info" {
  description = "Informations pour les développeurs (staging)"
  value = {
    environment_type          = "staging"
    database_connection_info  = "Utiliser Cloud SQL Proxy ou connexion privée via VPC"
    cloud_run_url            = module.cloud_run.service_url
    docker_repository        = "${var.region}-docker.pkg.dev/${var.project_id}/${module.artifact_registry.repository_name}"
    recommended_local_setup  = "Utiliser les même variables d'environnement qu'en staging pour les tests"
  }
  sensitive = true
}

# Métriques de coût (staging)
output "cost_optimization_info" {
  description = "Informations d'optimisation des coûts (staging)"
  value = {
    environment_cost_target = "250€/mois"
    cost_saving_features = [
      "1 réplica de lecture seulement",
      "Monitoring enhanced mais pas critical",
      "Retention logs 30 jours",
      "CPU throttling activé sur Cloud Run"
    ]
    scaling_configuration = {
      min_instances = var.cloud_run_min_instances
      max_instances = var.cloud_run_max_instances
      auto_scaling  = true
    }
  }
}

# Commandes utiles pour staging
output "useful_commands" {
  description = "Commandes utiles pour l'environnement staging"
  value = {
    connect_to_database = "gcloud sql connect ${module.cloud_sql.instance_name} --user=${module.cloud_sql.database_user}"
    view_cloud_run_logs = "gcloud logging read 'resource.type=cloud_run_revision AND resource.labels.service_name=${module.cloud_run.service_name}'"
    deploy_new_version  = "gcloud run deploy ${module.cloud_run.service_name} --image=${var.region}-docker.pkg.dev/${var.project_id}/${module.artifact_registry.repository_name}/app:latest --region=${var.region}"
    scale_service       = "gcloud run services update ${module.cloud_run.service_name} --min-instances=X --max-instances=Y --region=${var.region}"
  }
  sensitive = true
}

# Status de l'environnement
output "environment_status" {
  description = "Status et état de l'environnement staging"
  value = {
    environment           = var.environment
    deployment_time       = timestamp()
    high_availability    = var.high_availability
    monitoring_level     = "enhanced"
    security_level       = "intermediate"
    backup_level         = "cross-region"
    ready_for_testing    = true
  }
} 