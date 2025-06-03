variable "project_name" {
  description = "Nom du projet"
  type        = string
}

variable "project_id" {
  description = "ID du projet GCP"
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
  description = "Région GCP"
  type        = string
  default     = "europe-west1"
}

variable "service_name" {
  description = "Nom du service Cloud Run"
  type        = string
}

variable "service_url" {
  description = "URL du service Cloud Run"
  type        = string
}

variable "sql_instance_name" {
  description = "Nom de l'instance Cloud SQL"
  type        = string
  default     = ""
}

variable "health_check_path" {
  description = "Chemin pour les health checks"
  type        = string
  default     = "/actuator/health"
}

variable "notification_emails" {
  description = "Liste des emails pour les notifications"
  type        = list(string)
  default     = []
}

variable "slack_webhook_url" {
  description = "URL du webhook Slack pour les notifications"
  type        = string
  default     = ""
  sensitive   = true
}

variable "latency_threshold_ms" {
  description = "Seuil de latence en millisecondes pour les alertes"
  type        = number
  default     = 2000
}

variable "error_rate_threshold" {
  description = "Seuil du taux d'erreur pour les alertes (erreurs/min)"
  type        = number
  default     = 5
}

variable "cpu_threshold" {
  description = "Seuil d'utilisation CPU pour les alertes (0-1)"
  type        = number
  default     = 0.8
}

variable "memory_threshold" {
  description = "Seuil d'utilisation mémoire pour les alertes (0-1)"
  type        = number
  default     = 0.8
}

variable "sql_connections_threshold" {
  description = "Seuil de connexions SQL pour les alertes"
  type        = number
  default     = 80
}

variable "enable_log_sink" {
  description = "Activer le sink vers BigQuery pour les logs"
  type        = bool
  default     = true
}

variable "bigquery_dataset" {
  description = "Nom du dataset BigQuery pour les logs"
  type        = string
  default     = "application_logs"
}

variable "labels" {
  description = "Labels à appliquer aux ressources"
  type        = map(string)
  default     = {}
} 