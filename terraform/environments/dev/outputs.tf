# URLs et endpoints
output "cloud_run_url" {
  description = "URL du service Cloud Run"
  value       = module.cloud_run.service_url
}

output "dashboard_url" {
  description = "URL du dashboard Monitoring"
  value       = module.monitoring.dashboard_url
}

# Informations de connexion
output "sql_instance_connection_name" {
  description = "Nom de connexion Cloud SQL"
  value       = module.cloud_sql.instance_connection_name
}

output "sql_database_name" {
  description = "Nom de la base de données"
  value       = module.cloud_sql.database_name
}

output "sql_user" {
  description = "Utilisateur de la base de données"
  value       = module.cloud_sql.app_user
}

# Service Accounts
output "cloud_run_service_account" {
  description = "Email du service account Cloud Run"
  value       = module.iam.cloud_run_service_account_email
}

output "cloud_build_service_account" {
  description = "Email du service account Cloud Build"
  value       = module.iam.cloud_build_service_account_email
}

# Réseau
output "network_name" {
  description = "Nom du réseau VPC"
  value       = module.networking.network_name
}

output "nat_ip" {
  description = "Adresse IP externe du NAT"
  value       = module.networking.nat_ip
}

# Secrets
output "db_password_secret_name" {
  description = "Nom du secret contenant le mot de passe DB"
  value       = module.cloud_sql.app_password_secret_name
}

# Monitoring
output "uptime_check_id" {
  description = "ID de l'uptime check"
  value       = module.monitoring.uptime_check_id
}

# Informations de déploiement
output "deployment_info" {
  description = "Informations pour le déploiement"
  value = {
    project_id        = var.project_id
    region           = var.region
    service_name     = module.cloud_run.service_name
    image_url        = var.docker_image_url
    environment      = var.environment
  }
} 