# Génération d'un mot de passe aléatoire pour l'utilisateur root
resource "random_password" "root_password" {
  length  = 32
  special = true
}

# Génération d'un mot de passe aléatoire pour l'utilisateur applicatif
resource "random_password" "app_user_password" {
  length  = 32
  special = true
}

# Instance Cloud SQL PostgreSQL
resource "google_sql_database_instance" "main" {
  name             = "${lower(var.project_name)}-${var.environment}-postgres"
  database_version = var.database_version
  region          = var.region
  deletion_protection = var.deletion_protection
  
  settings {
    tier = var.tier
    
    availability_type = var.environment == "prod" ? "REGIONAL" : "ZONAL"
    
    disk_type       = var.disk_type
    disk_size       = var.disk_size
    disk_autoresize = true
    disk_autoresize_limit = var.max_disk_size
    
    user_labels = local.normalized_labels
    
    backup_configuration {
      enabled                        = true
      start_time                    = "03:00"
      location                      = var.backup_location
      point_in_time_recovery_enabled = var.point_in_time_recovery
      transaction_log_retention_days = var.transaction_log_retention_days
      
      backup_retention_settings {
        retained_backups = var.backup_retention_count
        retention_unit   = "COUNT"
      }
    }
    
    maintenance_window {
      day         = 7
      hour        = 4
      update_track = "stable"
    }
    
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                              = var.network_id
      enable_private_path_for_google_cloud_services = true
    }
    
    database_flags {
      name  = "max_connections"
      value = var.max_connections
    }
    
    insights_config {
      query_insights_enabled  = true
      query_plans_per_minute  = 5
      query_string_length     = 1024
      record_application_tags = false
      record_client_address   = false
    }
  }
  
  depends_on = [var.private_vpc_connection]
}

# Réplica de lecture pour la production
resource "google_sql_database_instance" "read_replica" {
  count = var.environment == "prod" && var.enable_read_replica ? 1 : 0
  
  name                 = "${lower(var.project_name)}-${var.environment}-replica"
  master_instance_name = google_sql_database_instance.main.name
  region              = var.replica_region != "" ? var.replica_region : var.region
  database_version    = var.database_version
  
  replica_configuration {
    failover_target = false
  }
  
  settings {
    tier = var.replica_tier != "" ? var.replica_tier : var.tier
    
    availability_type = "ZONAL"
    disk_autoresize  = true
    
    user_labels = local.normalized_labels
    
    ip_configuration {
      ipv4_enabled    = false
      private_network = var.network_id
    }
    
    insights_config {
      query_insights_enabled = true
    }
  }
}

# Base de données principale
resource "google_sql_database" "main" {
  name     = var.database_name
  instance = google_sql_database_instance.main.name
  
  depends_on = [google_sql_database_instance.main]
}

# Utilisateur root
resource "google_sql_user" "root" {
  name     = "postgres"
  instance = google_sql_database_instance.main.name
  password = random_password.root_password.result
}

# Utilisateur pour l'application
resource "google_sql_user" "app_user" {
  name     = var.app_user
  instance = google_sql_database_instance.main.name
  password = random_password.app_user_password.result
  
  depends_on = [google_sql_database.main]
}

# Stockage des mots de passe dans Secret Manager
resource "google_secret_manager_secret" "db_root_password" {
  secret_id = "${lower(var.project_name)}-${var.environment}-db-root-password"
  
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
  
  labels = local.normalized_labels
}

resource "google_secret_manager_secret_version" "db_root_password" {
  secret      = google_secret_manager_secret.db_root_password.id
  secret_data = random_password.root_password.result
}

resource "google_secret_manager_secret" "db_app_password" {
  secret_id = "${lower(var.project_name)}-${var.environment}-db-app-password"
  
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
  
  labels = local.normalized_labels
}

resource "google_secret_manager_secret_version" "db_app_password" {
  secret      = google_secret_manager_secret.db_app_password.id
  secret_data = random_password.app_user_password.result
} 