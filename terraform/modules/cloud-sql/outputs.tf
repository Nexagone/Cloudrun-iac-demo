output "instance_name" {
  description = "Nom de l'instance Cloud SQL"
  value       = google_sql_database_instance.main.name
}

output "instance_connection_name" {
  description = "Connection name pour Cloud SQL"
  value       = google_sql_database_instance.main.connection_name
}

output "instance_ip_address" {
  description = "Adresse IP privée de l'instance"
  value       = google_sql_database_instance.main.private_ip_address
}

output "database_name" {
  description = "Nom de la base de données"
  value       = google_sql_database.main.name
}

output "app_user" {
  description = "Nom de l'utilisateur de l'application"
  value       = google_sql_user.app_user.name
}

output "root_password_secret_name" {
  description = "Nom du secret pour le mot de passe root"
  value       = google_secret_manager_secret.db_root_password.secret_id
}

output "app_password_secret_name" {
  description = "Nom du secret pour le mot de passe de l'application"
  value       = google_secret_manager_secret.db_app_password.secret_id
}

output "read_replica_connection_name" {
  description = "Connection name du réplica de lecture"
  value       = var.environment == "prod" && var.enable_read_replica ? google_sql_database_instance.read_replica[0].connection_name : null
} 