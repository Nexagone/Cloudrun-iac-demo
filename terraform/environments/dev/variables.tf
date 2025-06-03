# Variables obligatoires
variable "project_id" {
  description = "ID du projet GCP"
  type        = string
}

variable "project_name" {
  description = "Nom du projet (utilisé pour nommer les ressources)"
  type        = string
}

variable "billing_account" {
  description = "ID du compte de facturation GCP"
  type        = string
}

# Variables d'environnement
variable "environment" {
  description = "Nom de l'environnement"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "Région GCP principale"
  type        = string
  default     = "europe-west1"
}

variable "backup_region" {
  description = "Région pour les sauvegardes"
  type        = string
  default     = "europe-west2"
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
variable "db_tier" {
  description = "Tier de l'instance Cloud SQL"
  type        = string
  default     = "db-f1-micro"
}

variable "db_disk_size" {
  description = "Taille du disque en GB"
  type        = number
  default     = 20
}

variable "db_max_disk_size" {
  description = "Taille maximale du disque en GB"
  type        = number
  default     = 50
}

variable "db_max_connections" {
  description = "Nombre maximum de connexions"
  type        = string
  default     = "50"
}

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

variable "point_in_time_recovery" {
  description = "Activer la récupération point-in-time"
  type        = bool
  default     = true
}

# Configuration Cloud Run
variable "default_image_url" {
  description = "URL de l'image Docker par défaut"
  type        = string
  default     = ""
}

variable "min_instances" {
  description = "Nombre minimum d'instances"
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Nombre maximum d'instances"
  type        = number
  default     = 5
}

variable "cpu_limit" {
  description = "Limite CPU"
  type        = string
  default     = "1000m"
}

variable "memory_limit" {
  description = "Limite mémoire"
  type        = string
  default     = "512Mi"
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

variable "environment_variables" {
  description = "Variables d'environnement supplémentaires"
  type        = map(string)
  default     = {}
}

# Configuration Monitoring
variable "notification_emails" {
  description = "Liste des emails pour les notifications"
  type        = list(string)
  default     = []
}

variable "slack_webhook_url" {
  description = "URL du webhook Slack"
  type        = string
  default     = ""
  sensitive   = true
}

variable "latency_threshold_ms" {
  description = "Seuil de latence en millisecondes"
  type        = number
  default     = 3000  # Plus élevé pour dev
}

variable "error_rate_threshold" {
  description = "Seuil du taux d'erreur"
  type        = number
  default     = 10  # Plus élevé pour dev
}

variable "cpu_threshold" {
  description = "Seuil d'utilisation CPU"
  type        = number
  default     = 0.9  # Plus élevé pour dev
}

variable "memory_threshold" {
  description = "Seuil d'utilisation mémoire"
  type        = number
  default     = 0.9  # Plus élevé pour dev
}

variable "sql_connections_threshold" {
  description = "Seuil de connexions SQL"
  type        = number
  default     = 40  # Adapté au tier micro
}

variable "enable_log_sink" {
  description = "Activer le sink vers BigQuery"
  type        = bool
  default     = false  # Désactivé pour dev pour économiser
}

# Configuration Budget
variable "budget_amount" {
  description = "Montant du budget en euros (0 pour désactiver)"
  type        = number
  default     = 50
}

# IAM
variable "workload_identity_users" {
  description = "Liste des utilisateurs pour Workload Identity"
  type        = list(string)
  default     = []
} 