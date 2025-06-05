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
  description = "Région GCP"
  type        = string
  default     = "europe-west1"
}

variable "cloud_run_service_account" {
  description = "Email du service account Cloud Run"
  type        = string
}

variable "cloud_build_service_account" {
  description = "Email du service account Cloud Build"
  type        = string
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