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

variable "workload_identity_users" {
  description = "Liste des utilisateurs pour Workload Identity"
  type        = list(string)
  default     = []
} 