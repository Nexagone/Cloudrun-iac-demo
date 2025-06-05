variable "project_name" {
  description = "Nom du projet utilisé pour les ressources"
  type        = string
}

variable "region" {
  description = "Région GCP pour les ressources"
  type        = string
  default     = "europe-west1"
}

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
  description = "CIDR secondaire pour les services (pods GKE si besoin)"
  type        = string
  default     = "10.3.0.0/16"
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