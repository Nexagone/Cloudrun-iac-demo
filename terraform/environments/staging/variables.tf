# Variables pour l'environnement Staging
# Configuration intermédiaire entre dev et prod

variable "project_id" {
  description = "ID du projet Google Cloud"
  type        = string
  validation {
    condition     = length(var.project_id) > 0
    error_message = "Le project_id ne peut pas être vide."
  }
}

variable "project_name" {
  description = "Nom du projet (utilisé pour nommer les ressources)"
  type        = string
}

variable "environment" {
  description = "Nom de l'environnement"
  type        = string
  default     = "staging"
  validation {
    condition     = var.environment == "staging"
    error_message = "L'environnement doit être 'staging' pour cette configuration."
  }
}

variable "region" {
  description = "Région Google Cloud principale"
  type        = string
  default     = "europe-west1"
  validation {
    condition     = can(regex("^(europe|us|asia)", var.region))
    error_message = "La région doit être une région Google Cloud valide."
  }
}

# Labels
variable "team" {
  description = "Nom de l'équipe"
  type        = string
  default     = "platform"
}

variable "cost_center" {
  description = "Centre de coût"
  type        = string
  default     = "engineering"
}

# Configuration réseau
variable "vpc_cidr_range" {
  description = "CIDR du VPC principal"
  type        = string
  default     = "10.1.0.0/16"
  validation {
    condition     = can(cidrhost(var.vpc_cidr_range, 0))
    error_message = "Le CIDR du VPC doit être valide."
  }
}

variable "private_subnet_cidr" {
  description = "CIDR du sous-réseau privé"
  type        = string
  default     = "10.1.1.0/24"
}

variable "public_subnet_cidr" {
  description = "CIDR du sous-réseau public"
  type        = string
  default     = "10.1.2.0/24"
}

variable "pods_cidr_range" {
  description = "CIDR pour les pods GKE"
  type        = string
  default     = "10.1.16.0/20"
}

variable "services_cidr_range" {
  description = "CIDR pour les services GKE"
  type        = string
  default     = "10.1.32.0/20"
}

variable "authorized_networks" {
  description = "Réseaux autorisés pour Cloud SQL"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# Configuration Cloud SQL
variable "database_tier" {
  description = "Tier de l'instance Cloud SQL"
  type        = string
  default     = "db-custom-2-4096"  # 2 vCPU, 4GB RAM pour staging
}

variable "disk_size" {
  description = "Taille du disque en GB"
  type        = number
  default     = 50
}

variable "max_disk_size" {
  description = "Taille maximale du disque en GB"
  type        = number
  default     = 100
}

variable "high_availability" {
  description = "Activer la haute disponibilité"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Nombre de jours de rétention des backups"
  type        = number
  default     = 14
  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 365
    error_message = "La rétention des backups doit être entre 1 et 365 jours."
  }
}

variable "backup_location" {
  description = "Localisation des backups"
  type        = string
  default     = "europe-west1"
}

variable "point_in_time_recovery" {
  description = "Activer la récupération point-in-time"
  type        = bool
  default     = true
}

variable "maintenance_window_day" {
  description = "Jour de la semaine pour la maintenance (1=Lundi)"
  type        = number
  default     = 7
  validation {
    condition     = var.maintenance_window_day >= 1 && var.maintenance_window_day <= 7
    error_message = "Le jour de maintenance doit être entre 1 (Lundi) et 7 (Dimanche)."
  }
}

variable "maintenance_window_hour" {
  description = "Heure de début de la maintenance (0-23)"
  type        = number
  default     = 3
  validation {
    condition     = var.maintenance_window_hour >= 0 && var.maintenance_window_hour <= 23
    error_message = "L'heure de maintenance doit être entre 0 et 23."
  }
}

variable "read_replica_count" {
  description = "Nombre de réplicas de lecture"
  type        = number
  default     = 1
  validation {
    condition     = var.read_replica_count >= 0 && var.read_replica_count <= 5
    error_message = "Le nombre de réplicas doit être entre 0 et 5."
  }
}

variable "replica_tier" {
  description = "Tier des réplicas de lecture"
  type        = string
  default     = "db-custom-1-2048"
}

# Configuration Cloud Run
variable "cloud_run_cpu_limit" {
  description = "Limite CPU pour Cloud Run"
  type        = string
  default     = "1000m"  # 1 vCPU
}

variable "cloud_run_memory_limit" {
  description = "Limite mémoire pour Cloud Run"
  type        = string
  default     = "1Gi"  # 1GB RAM
}

variable "cloud_run_min_instances" {
  description = "Nombre minimum d'instances Cloud Run"
  type        = number
  default     = 1
}

variable "cloud_run_max_instances" {
  description = "Nombre maximum d'instances Cloud Run"
  type        = number
  default     = 10
}

variable "cloud_run_concurrency" {
  description = "Nombre de requêtes simultanées par instance"
  type        = number
  default     = 60
  validation {
    condition     = var.cloud_run_concurrency >= 1 && var.cloud_run_concurrency <= 1000
    error_message = "La concurrence doit être entre 1 et 1000."
  }
}

variable "cloud_run_timeout_seconds" {
  description = "Timeout des requêtes en secondes"
  type        = number
  default     = 300
  validation {
    condition     = var.cloud_run_timeout_seconds >= 1 && var.cloud_run_timeout_seconds <= 3600
    error_message = "Le timeout doit être entre 1 et 3600 secondes."
  }
}

variable "cloud_run_cpu_throttling" {
  description = "Activer le throttling CPU"
  type        = bool
  default     = true
}

# Configuration Artifact Registry
variable "registry_format" {
  description = "Format du registre (DOCKER, MAVEN, etc.)"
  type        = string
  default     = "DOCKER"
  validation {
    condition     = contains(["DOCKER", "MAVEN", "NPM", "PYTHON"], var.registry_format)
    error_message = "Le format doit être DOCKER, MAVEN, NPM ou PYTHON."
  }
}

variable "registry_description" {
  description = "Description du registre Artifact Registry"
  type        = string
  default     = "Staging Docker registry pour centralisation de données"
}

# Configuration monitoring et alertes
variable "enable_monitoring" {
  description = "Activer le monitoring"
  type        = bool
  default     = true
}

variable "alert_email" {
  description = "Email pour les alertes"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.alert_email))
    error_message = "L'email doit être au format valide."
  }
}

variable "slack_webhook_url" {
  description = "URL du webhook Slack"
  type        = string
  default     = ""
}

variable "sms_number" {
  description = "Numéro de téléphone pour les alertes SMS"
  type        = string
  default     = ""
}

# Budget et coûts
variable "budget_amount" {
  description = "Montant du budget mensuel en euros"
  type        = string
  default     = "250"
}

variable "budget_alert_thresholds" {
  description = "Seuils d'alerte du budget (pourcentages)"
  type        = list(number)
  default     = [0.5, 0.8, 1.0]
  validation {
    condition     = alltrue([for t in var.budget_alert_thresholds : t > 0 && t <= 1.5])
    error_message = "Les seuils doivent être entre 0 et 1.5 (150%)."
  }
}

# Sécurité
variable "enable_private_ip" {
  description = "Utiliser des IPs privées uniquement"
  type        = bool
  default     = true
}

variable "enable_ssl_redirect" {
  description = "Rediriger HTTP vers HTTPS"
  type        = bool
  default     = true
}

variable "enable_armor" {
  description = "Activer Google Cloud Armor"
  type        = bool
  default     = true
}

variable "allowed_source_ranges" {
  description = "Plages d'IP autorisées"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_audit_logs" {
  description = "Activer les logs d'audit"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Durée de rétention des logs en jours"
  type        = number
  default     = 30
  validation {
    condition     = var.log_retention_days >= 1 && var.log_retention_days <= 3653
    error_message = "La rétention des logs doit être entre 1 et 3653 jours (10 ans)."
  }
}

# Configuration spécifique staging
variable "deletion_protection" {
  description = "Activer la protection contre la suppression"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Ignorer le snapshot final à la suppression"
  type        = bool
  default     = false
}

variable "enable_performance_insights" {
  description = "Activer Performance Insights"
  type        = bool
  default     = true
}

variable "enable_query_insights" {
  description = "Activer Query Insights"
  type        = bool
  default     = true
}

# Labels
variable "labels" {
  description = "Labels à appliquer aux ressources"
  type        = map(string)
  default = {
    environment = "staging"
    project     = "data-centralization"
    team        = "platform"
    cost-center = "testing"
  }
}

# Configuration des secrets
variable "enable_secret_manager" {
  description = "Activer Secret Manager"
  type        = bool
  default     = true
}

variable "secret_locations" {
  description = "Régions pour les secrets"
  type        = list(string)
  default     = ["europe-west1", "europe-west4"]
}

# Configuration backup
variable "backup_cross_region" {
  description = "Backups cross-région"
  type        = bool
  default     = true
}

variable "backup_location_secondary" {
  description = "Localisation secondaire des backups"
  type        = string
  default     = "europe-west4"
}

variable "enable_point_in_time_recovery" {
  description = "Activer la récupération point-in-time"
  type        = bool
  default     = true
}

# Performance
variable "enable_connection_pooling" {
  description = "Activer le pooling de connexions"
  type        = bool
  default     = true
}

variable "max_connections" {
  description = "Nombre maximum de connexions"
  type        = string
  default     = "200"
}

variable "shared_preload_libraries" {
  description = "Librairies partagées PostgreSQL"
  type        = string
  default     = "pg_stat_statements"
}

# Monitoring intermédiaire
variable "enable_slow_query_log" {
  description = "Activer les logs de requêtes lentes"
  type        = bool
  default     = true
}

variable "slow_query_threshold" {
  description = "Seuil pour les requêtes lentes"
  type        = string
  default     = "2s"
}

variable "enable_connection_logging" {
  description = "Logger les connexions"
  type        = bool
  default     = true
}

variable "enable_checkpoints_logging" {
  description = "Logger les checkpoints"
  type        = bool
  default     = false
}

# Sécurité intermédiaire
variable "require_ssl" {
  description = "Exiger SSL pour les connexions"
  type        = bool
  default     = true
}

variable "ssl_mode" {
  description = "Mode SSL (ALLOW_UNENCRYPTED_AND_ENCRYPTED, ENCRYPTED_ONLY)"
  type        = string
  default     = "ENCRYPTED_ONLY"
  validation {
    condition = contains([
      "ALLOW_UNENCRYPTED_AND_ENCRYPTED",
      "ENCRYPTED_ONLY"
    ], var.ssl_mode)
    error_message = "Le mode SSL doit être ALLOW_UNENCRYPTED_AND_ENCRYPTED ou ENCRYPTED_ONLY."
  }
}

variable "enable_pgaudit" {
  description = "Activer pgAudit"
  type        = bool
  default     = false
}

variable "log_statement" {
  description = "Type de statements à logger (none, ddl, mod, all)"
  type        = string
  default     = "mod"
  validation {
    condition     = contains(["none", "ddl", "mod", "all"], var.log_statement)
    error_message = "log_statement doit être none, ddl, mod ou all."
  }
}

variable "log_min_duration_statement" {
  description = "Durée minimale (ms) pour logger une requête (-1 = désactivé)"
  type        = number
  default     = 2000
}

# Configuration réseau
variable "services_subnet_cidr" {
  description = "CIDR pour le sous-réseau des services"
  type        = string
  default     = "10.1.0.0/24"
}

variable "database_subnet_cidr" {
  description = "CIDR pour le sous-réseau de la base de données"
  type        = string
  default     = "10.2.0.0/24"
}

variable "services_secondary_cidr" {
  description = "CIDR secondaire pour les services"
  type        = string
  default     = "10.3.0.0/16"
}

variable "vpc_connector_cidr" {
  description = "CIDR pour le connecteur VPC"
  type        = string
  default     = "10.8.0.0/28"
}

# Configuration Cloud SQL
variable "database_name" {
  description = "Nom de la base de données"
  type        = string
  default     = "app_db"
}

variable "database_user" {
  description = "Nom de l'utilisateur de la base de données"
  type        = string
  default     = "app_user"
}

variable "backup_region" {
  description = "Région pour les sauvegardes"
  type        = string
  default     = "europe-west2"
}

variable "enable_read_replica" {
  description = "Activer un réplica de lecture"
  type        = bool
  default     = false
}

# Configuration Cloud Run
variable "default_image_url" {
  description = "URL de l'image Docker par défaut"
  type        = string
  default     = ""
}

variable "environment_variables" {
  description = "Variables d'environnement supplémentaires pour Cloud Run"
  type        = map(string)
  default     = {}
}

variable "allow_public_access" {
  description = "Autoriser l'accès public à Cloud Run"
  type        = bool
  default     = true
}

variable "custom_domain" {
  description = "Domaine personnalisé pour Cloud Run"
  type        = string
  default     = ""
}

# Configuration IAM
variable "workload_identity_users" {
  description = "Liste des utilisateurs pour Workload Identity"
  type        = list(string)
  default     = []
}

# Configuration monitoring
variable "notification_emails" {
  description = "Liste des emails pour les notifications"
  type        = list(string)
  default     = []
}

variable "latency_threshold_ms" {
  description = "Seuil de latence en millisecondes"
  type        = number
  default     = 2000
}

variable "error_rate_threshold" {
  description = "Seuil du taux d'erreur"
  type        = number
  default     = 5
}

variable "cpu_threshold" {
  description = "Seuil d'utilisation CPU"
  type        = number
  default     = 0.8
}

variable "memory_threshold" {
  description = "Seuil d'utilisation mémoire"
  type        = number
  default     = 0.8
}

variable "sql_connections_threshold" {
  description = "Seuil de connexions SQL"
  type        = number
  default     = 100
}

variable "enable_log_sink" {
  description = "Activer l'export des logs vers BigQuery"
  type        = bool
  default     = true
}

variable "billing_account" {
  description = "ID du compte de facturation"
  type        = string
}

variable "docker_registry" {
  description = "Configuration du registre Docker privé"
  type = object({
    server   = string
    username = string
    password = string
  })
  default = null
}

variable "docker_image_url" {
  description = "URL complète de l'image Docker dans le registre privé"
  type        = string
} 

# Labels
variable "team" {
  description = "Nom de l'équipe"
  type        = string
  default     = "platform"
}

variable "cost_center" {
  description = "Centre de coût"
  type        = string
  default     = "it-infrastructure"
}

variable "app_name" {
  description = "Nom de l'application"
  type        = string
}

variable "backup_region" {
  description = "Région pour les sauvegardes"
  type        = string
  default     = "europe-west2"
}