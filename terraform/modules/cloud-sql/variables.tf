variable "project_name" {
  description = "Nom du projet"
  type        = string
}

variable "environment" {
  description = "Environnement (dev, staging, prod)"
  type        = string
  
  validation {
    condition = contains(["dev", "staging", "prod"], var.environment)
    error_message = "L'environnement doit être dev, staging ou prod."
  }
}

variable "region" {
  description = "Région GCP principale"
  type        = string
  default     = "europe-west1"
}

variable "database_version" {
  description = "Version PostgreSQL"
  type        = string
  default     = "POSTGRES_14"
}

variable "tier" {
  description = "Tier de l'instance Cloud SQL"
  type        = string
  default     = "db-f1-micro"
}

variable "disk_type" {
  description = "Type de disque (PD_SSD ou PD_HDD)"
  type        = string
  default     = "PD_SSD"
}

variable "disk_size" {
  description = "Taille du disque en GB"
  type        = number
  default     = 20
}

variable "max_disk_size" {
  description = "Taille maximale du disque en GB"
  type        = number
  default     = 100
}

variable "max_connections" {
  description = "Nombre maximum de connexions"
  type        = string
  default     = "100"
}

variable "database_name" {
  description = "Nom de la base de données"
  type        = string
  default     = "app_db"
}

variable "app_user" {
  description = "Nom de l'utilisateur de l'application"
  type        = string
  default     = "app_user"
}

variable "backup_location" {
  description = "Région pour les sauvegardes"
  type        = string
  default     = "europe-west2"
}

variable "backup_retention_count" {
  description = "Nombre de sauvegardes à conserver"
  type        = number
  default     = 7
}

variable "transaction_log_retention_days" {
  description = "Nombre de jours pour conserver les logs de transaction"
  type        = number
  default     = 7
}

variable "point_in_time_recovery" {
  description = "Activer la récupération point-in-time"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Protection contre la suppression"
  type        = bool
  default     = true
}

variable "enable_read_replica" {
  description = "Créer un réplica de lecture"
  type        = bool
  default     = false
}

variable "replica_region" {
  description = "Région pour le réplica de lecture"
  type        = string
  default     = ""
}

variable "replica_tier" {
  description = "Tier pour le réplica de lecture"
  type        = string
  default     = ""
}

variable "network_id" {
  description = "ID du réseau VPC"
  type        = string
}

variable "private_vpc_connection" {
  description = "Connexion VPC privée"
  type        = string
}

variable "labels" {
  description = "Labels à appliquer aux ressources"
  type        = map(string)
  default     = {}
} 