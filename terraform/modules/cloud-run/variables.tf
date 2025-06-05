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

variable "image_url" {
  description = "URL de l'image Docker"
  type        = string
}

variable "service_account_email" {
  description = "Email du service account pour Cloud Run"
  type        = string
}

variable "min_instances" {
  description = "Nombre minimum d'instances"
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Nombre maximum d'instances"
  type        = number
  default     = 10
}

variable "cpu_limit" {
  description = "Limite CPU (ex: '1000m' pour 1 vCPU)"
  type        = string
  default     = "1000m"
}

variable "memory_limit" {
  description = "Limite mémoire (ex: '512Mi')"
  type        = string
  default     = "512Mi"
}

variable "port" {
  description = "Port d'écoute du container"
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "Chemin pour les health checks"
  type        = string
  default     = "/actuator/health"
}

variable "sql_connection_name" {
  description = "Nom de connexion Cloud SQL"
  type        = string
}

variable "database_name" {
  description = "Nom de la base de données"
  type        = string
}

variable "database_user" {
  description = "Utilisateur de la base de données"
  type        = string
}

variable "db_password_secret_name" {
  description = "Nom du secret contenant le mot de passe DB"
  type        = string
}

variable "environment_variables" {
  description = "Variables d'environnement supplémentaires"
  type        = map(string)
  default     = {}
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

variable "network_name" {
  description = "Nom du réseau VPC"
  type        = string
}

variable "vpc_connector_name" {
  description = "Nom du connecteur VPC"
  type        = string
  default     = ""
}

variable "create_vpc_connector" {
  description = "Créer un connecteur VPC"
  type        = bool
  default     = false
}

variable "vpc_connector_cidr" {
  description = "CIDR pour le connecteur VPC Cloud Run"
  type        = string
  default     = "10.8.0.0/28"
}

variable "labels" {
  description = "Labels à appliquer aux ressources"
  type        = map(string)
  default     = {}
}

# Transformation des labels pour assurer la conformité
locals {
  normalized_labels = {
    for key, value in var.labels :
    key => lower(replace(value, "-", "_"))
  }
}

variable "docker_registry_credentials" {
  description = "Credentials pour le registre Docker privé"
  type = object({
    server   = string
    username = string
    password = string
  })
  default = null
} 