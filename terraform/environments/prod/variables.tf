# Variables pour l'environnement Production
# Configuration centralisée pour tous les paramètres de production

# Configuration globale
variable "project_id" {
  description = "ID du projet GCP pour l'environnement de production"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "L'ID du projet doit être valide selon les conventions GCP."
  }
}

variable "project_name" {
  description = "Nom du projet (utilisé pour nommer les ressources)"
  type        = string
}

variable "environment" {
  description = "Nom de l'environnement"
  type        = string
  default     = "prod"
  validation {
    condition     = var.environment == "prod"
    error_message = "Cet environnement doit être 'prod'."
  }
}

variable "region" {
  description = "Région GCP principale pour l'environnement de production"
  type        = string
  default     = "europe-west1"
  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]-[a-z]$", var.region))
    error_message = "La région doit être une région GCP valide."
  }
}

# Configuration réseau
variable "vpc_cidr_range" {
  description = "Plage CIDR pour le VPC principal"
  type        = string
  default     = "10.2.0.0/16"
  validation {
    condition     = can(cidrhost(var.vpc_cidr_range, 0))
    error_message = "La plage CIDR doit être valide."
  }
}

variable "private_subnet_cidr" {
  description = "Plage CIDR pour le sous-réseau privé"
  type        = string
  default     = "10.2.1.0/24"
}

variable "public_subnet_cidr" {
  description = "Plage CIDR pour le sous-réseau public"
  type        = string
  default     = "10.2.2.0/24"
}

variable "pods_cidr_range" {
  description = "Plage CIDR pour les pods (si GKE utilisé)"
  type        = string
  default     = "10.2.16.0/20"
}

variable "services_cidr_range" {
  description = "Plage CIDR pour les services (si GKE utilisé)"
  type        = string
  default     = "10.2.32.0/20"
}

variable "services_subnet_cidr" {
  description = "CIDR pour le sous-réseau des services"
  type        = string
  default     = "10.2.3.0/24"
}

variable "database_subnet_cidr" {
  description = "CIDR pour le sous-réseau de la base de données"
  type        = string
  default     = "10.2.4.0/24"
}

variable "services_secondary_cidr" {
  description = "CIDR secondaire pour les services"
  type        = string
  default     = "10.2.5.0/24"
}

variable "authorized_networks" {
  description = "Réseaux autorisés à accéder aux ressources"
  type = list(object({
    name  = string
    value = string
  }))
  default = [
    {
      name  = "production-office"
      value = "203.0.113.0/24"
    },
    {
      name  = "backup-office"
      value = "198.51.100.0/24"
    }
  ]
}

# Configuration Cloud SQL
variable "database_tier" {
  description = "Niveau de l'instance Cloud SQL"
  type        = string
  default     = "db-custom-4-8192"
  validation {
    condition = contains([
      "db-custom-1-3840", "db-custom-2-7680", "db-custom-4-15360",
      "db-custom-8-30720", "db-custom-16-61440", "db-custom-4-8192"
    ], var.database_tier)
    error_message = "Le tier de base de données doit être un tier Cloud SQL valide."
  }
}

variable "disk_size" {
  description = "Taille du disque en GB"
  type        = number
  default     = 100
  validation {
    condition     = var.disk_size >= 10 && var.disk_size <= 65536
    error_message = "La taille du disque doit être entre 10 GB et 65536 GB."
  }
}

variable "max_disk_size" {
  description = "Taille maximale du disque avec auto-resize en GB"
  type        = number
  default     = 500
  validation {
    condition     = var.max_disk_size >= var.disk_size
    error_message = "La taille maximale doit être supérieure à la taille initiale."
  }
}

variable "high_availability" {
  description = "Activer la haute disponibilité pour Cloud SQL"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Nombre de jours de rétention des sauvegardes"
  type        = number
  default     = 30
  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 365
    error_message = "La rétention des sauvegardes doit être entre 1 et 365 jours."
  }
}

variable "backup_location" {
  description = "Localisation des sauvegardes"
  type        = string
  default     = "europe-west1"
}

variable "point_in_time_recovery" {
  description = "Activer la récupération point-in-time"
  type        = bool
  default     = true
}

variable "maintenance_window_day" {
  description = "Jour de la semaine pour la maintenance (1 = dimanche)"
  type        = number
  default     = 1
  validation {
    condition     = var.maintenance_window_day >= 1 && var.maintenance_window_day <= 7
    error_message = "Le jour de maintenance doit être entre 1 (dimanche) et 7 (samedi)."
  }
}

variable "maintenance_window_hour" {
  description = "Heure de la maintenance (0-23)"
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
  default     = 2
  validation {
    condition     = var.read_replica_count >= 0 && var.read_replica_count <= 10
    error_message = "Le nombre de réplicas doit être entre 0 et 10."
  }
}

variable "replica_tier" {
  description = "Niveau des instances réplicas"
  type        = string
  default     = "db-custom-2-4096"
}

# Configuration Cloud Run
variable "cloud_run_cpu_limit" {
  description = "Limite CPU pour Cloud Run"
  type        = string
  default     = "2000m"
  validation {
    condition     = can(regex("^[0-9]+m?$", var.cloud_run_cpu_limit))
    error_message = "La limite CPU doit être au format valide (ex: 1000m ou 2)."
  }
}

variable "cloud_run_memory_limit" {
  description = "Limite mémoire pour Cloud Run"
  type        = string
  default     = "2Gi"
  validation {
    condition     = can(regex("^[0-9]+(Mi|Gi)$", var.cloud_run_memory_limit))
    error_message = "La limite mémoire doit être au format valide (ex: 512Mi ou 2Gi)."
  }
}

variable "cloud_run_min_instances" {
  description = "Nombre minimum d'instances Cloud Run"
  type        = number
  default     = 2
  validation {
    condition     = var.cloud_run_min_instances >= 0 && var.cloud_run_min_instances <= 1000
    error_message = "Le nombre minimum d'instances doit être entre 0 et 1000."
  }
}

variable "cloud_run_max_instances" {
  description = "Nombre maximum d'instances Cloud Run"
  type        = number
  default     = 100
  validation {
    condition     = var.cloud_run_max_instances >= var.cloud_run_min_instances
    error_message = "Le nombre maximum d'instances doit être supérieur au minimum."
  }
}

variable "cloud_run_concurrency" {
  description = "Nombre de requêtes simultanées par instance"
  type        = number
  default     = 80
  validation {
    condition     = var.cloud_run_concurrency >= 1 && var.cloud_run_concurrency <= 1000
    error_message = "La concurrence doit être entre 1 et 1000."
  }
}

variable "cloud_run_timeout_seconds" {
  description = "Timeout en secondes pour les requêtes"
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
  default     = false
}

# Configuration Artifact Registry
variable "registry_format" {
  description = "Format du registry"
  type        = string
  default     = "DOCKER"
  validation {
    condition     = contains(["DOCKER", "MAVEN", "NPM", "PYTHON"], var.registry_format)
    error_message = "Le format doit être DOCKER, MAVEN, NPM ou PYTHON."
  }
}

variable "registry_description" {
  description = "Description du registry"
  type        = string
  default     = "Production Docker registry pour centralisation de données"
}

# Configuration monitoring
variable "enable_monitoring" {
  description = "Activer le monitoring"
  type        = bool
  default     = true
}

variable "alert_email" {
  description = "Email pour les alertes"
  type        = string
  default     = "admin@example.com"
  validation {
    condition     = can(regex("^[\\w\\.-]+@[\\w\\.-]+\\.[a-z]{2,}$", var.alert_email))
    error_message = "L'email doit être au format valide."
  }
}

variable "slack_webhook_url" {
  description = "URL webhook Slack pour les alertes"
  type        = string
  default     = ""
}

variable "sms_number" {
  description = "Numéro SMS pour les alertes critiques"
  type        = string
  default     = ""
}

# Configuration budget
variable "budget_amount" {
  description = "Montant du budget mensuel"
  type        = string
  default     = "500"
  validation {
    condition     = can(tonumber(var.budget_amount)) && tonumber(var.budget_amount) > 0
    error_message = "Le montant du budget doit être un nombre positif."
  }
}

variable "budget_alert_thresholds" {
  description = "Seuils d'alerte du budget en pourcentage"
  type        = list(number)
  default     = [0.5, 0.8, 0.9, 1.0]
  validation {
    condition = alltrue([
      for threshold in var.budget_alert_thresholds : threshold > 0 && threshold <= 1
    ])
    error_message = "Les seuils doivent être entre 0 et 1."
  }
}

# Configuration sécurité
variable "enable_private_ip" {
  description = "Utiliser uniquement des IP privées"
  type        = bool
  default     = true
}

variable "enable_ssl_redirect" {
  description = "Rediriger HTTP vers HTTPS"
  type        = bool
  default     = true
}

variable "enable_armor" {
  description = "Activer Cloud Armor"
  type        = bool
  default     = true
}

variable "allowed_source_ranges" {
  description = "Plages IP autorisées"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_audit_logs" {
  description = "Activer les logs d'audit"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Rétention des logs en jours"
  type        = number
  default     = 90
  validation {
    condition     = var.log_retention_days >= 1 && var.log_retention_days <= 3653
    error_message = "La rétention des logs doit être entre 1 et 3653 jours."
  }
}

# Configuration spécifique production
variable "deletion_protection" {
  description = "Protection contre la suppression"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Ignorer le snapshot final"
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

# Configuration secrets
variable "enable_secret_manager" {
  description = "Utiliser Secret Manager"
  type        = bool
  default     = true
}

variable "secret_locations" {
  description = "Localisations pour les secrets"
  type        = list(string)
  default     = ["europe-west1", "europe-west4"]
}

# Configuration backup et disaster recovery
variable "backup_cross_region" {
  description = "Sauvegardes cross-région"
  type        = bool
  default     = true
}

variable "backup_location_secondary" {
  description = "Localisation secondaire pour les sauvegardes"
  type        = string
  default     = "europe-west4"
}

variable "enable_point_in_time_recovery" {
  description = "Activer la récupération point-in-time"
  type        = bool
  default     = true
}

# Configuration performance
variable "enable_connection_pooling" {
  description = "Activer le connection pooling"
  type        = bool
  default     = true
}

variable "max_connections" {
  description = "Nombre maximum de connexions PostgreSQL"
  type        = number
  default     = 200
  validation {
    condition     = var.max_connections >= 5 && var.max_connections <= 262143
    error_message = "Le nombre de connexions doit être entre 5 et 262143."
  }
}

variable "shared_preload_libraries" {
  description = "Bibliothèques partagées à précharger"
  type        = string
  default     = "pg_stat_statements,auto_explain"
}

# Configuration monitoring avancé
variable "enable_slow_query_log" {
  description = "Activer les logs de requêtes lentes"
  type        = bool
  default     = true
}

variable "slow_query_threshold" {
  description = "Seuil pour les requêtes lentes"
  type        = string
  default     = "1s"
}

variable "enable_connection_logging" {
  description = "Activer les logs de connexion"
  type        = bool
  default     = true
}

variable "enable_checkpoints_logging" {
  description = "Activer les logs de checkpoints"
  type        = bool
  default     = true
}

# Configuration compliance et sécurité
variable "require_ssl" {
  description = "Exiger SSL"
  type        = bool
  default     = true
}

variable "ssl_mode" {
  description = "Mode SSL"
  type        = string
  default     = "ENCRYPTED_ONLY"
  validation {
    condition     = contains(["ALLOW_UNENCRYPTED_AND_ENCRYPTED", "ENCRYPTED_ONLY", "TRUSTED_CLIENT_CERTIFICATE_REQUIRED"], var.ssl_mode)
    error_message = "Le mode SSL doit être une valeur valide."
  }
}

variable "enable_pgaudit" {
  description = "Activer pgAudit"
  type        = bool
  default     = true
}

variable "log_statement" {
  description = "Niveau de logging des statements"
  type        = string
  default     = "all"
  validation {
    condition     = contains(["none", "ddl", "mod", "all"], var.log_statement)
    error_message = "log_statement doit être 'none', 'ddl', 'mod' ou 'all'."
  }
}

variable "log_min_duration_statement" {
  description = "Durée minimale pour logger les statements (ms)"
  type        = number
  default     = 1000
  validation {
    condition     = var.log_min_duration_statement >= -1
    error_message = "La durée doit être >= -1 (-1 pour désactiver)."
  }
}

# Labels
variable "labels" {
  description = "Labels à appliquer aux ressources"
  type        = map(string)
  default = {
    environment   = "prod"
    project       = "data-centralization"
    team          = "platform"
    cost-center   = "it-infrastructure"
    backup        = "required"
    monitoring    = "critical"
    compliance    = "required"
    data-class    = "confidential"
  }
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
  default     = 1000  # Plus strict en prod
}

variable "error_rate_threshold" {
  description = "Seuil du taux d'erreur"
  type        = number
  default     = 2  # Plus strict en prod
}

variable "cpu_threshold" {
  description = "Seuil d'utilisation CPU"
  type        = number
  default     = 0.7  # Plus strict en prod
}

variable "memory_threshold" {
  description = "Seuil d'utilisation mémoire"
  type        = number
  default     = 0.7  # Plus strict en prod
}

variable "sql_connections_threshold" {
  description = "Seuil de connexions SQL"
  type        = number
  default     = 150  # Plus élevé pour la prod
}

variable "enable_log_sink" {
  description = "Activer l'export des logs vers BigQuery"
  type        = bool
  default     = true  # Toujours activé en prod
}

variable "billing_account" {
  description = "ID du compte de facturation"
  type        = string
}

# Configuration base de données
variable "database_name" {
  description = "Nom de la base de données"
  type        = string
  default     = "app_db"
}

variable "database_user" {
  description = "Nom de l'utilisateur de l'application"
  type        = string
  default     = "app_user"
}

# Configuration IAM
variable "workload_identity_users" {
  description = "Liste des utilisateurs pour Workload Identity"
  type        = list(string)
  default     = []
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

variable "environment_variables" {
  description = "Variables d'environnement supplémentaires pour Cloud Run"
  type        = map(string)
  default     = {}
}

variable "vpc_connector_cidr" {
  description = "CIDR pour le connecteur VPC Cloud Run"
  type        = string
  default     = "10.8.0.0/28"
}

variable "allow_public_access" {
  description = "Autoriser l'accès public"
  type        = bool
  default     = true
}

variable "custom_domain" {
  description = "Domaine personnalisé"
  type        = string
  default     = ""
} 