# Activation de l'API Artifact Registry
resource "google_project_service" "artifact_registry" {
  service = "artifactregistry.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy        = false
}

# Dépôt Artifact Registry
resource "google_artifact_registry_repository" "main" {
  depends_on = [google_project_service.artifact_registry]
  
  location      = var.region
  repository_id = "${lower(var.project_name)}-${var.environment}"
  description   = "Dépôt Docker pour ${var.project_name} - ${var.environment}"
  format        = "DOCKER"
  
  docker_config {
    immutable_tags = var.environment == "prod"
  }
  
  labels = local.normalized_labels
}

# IAM - Accès en lecture pour Cloud Run
resource "google_artifact_registry_repository_iam_member" "cloud_run_reader" {
  location   = google_artifact_registry_repository.main.location
  repository = google_artifact_registry_repository.main.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${var.cloud_run_service_account}"
}

# IAM - Accès en écriture pour Cloud Build
resource "google_artifact_registry_repository_iam_member" "cloud_build_writer" {
  location   = google_artifact_registry_repository.main.location
  repository = google_artifact_registry_repository.main.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${var.cloud_build_service_account}"
} 