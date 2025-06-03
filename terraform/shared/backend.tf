# Configuration backend partagée pour tous les environnements
terraform {
  backend "gcs" {
    # Configuration spécifique par environment via backend.conf
    # bucket  = "terraform-state-{project-id}"
    # prefix  = "terraform/state/{environment}"
  }
}

# Configuration des providers
terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
} 