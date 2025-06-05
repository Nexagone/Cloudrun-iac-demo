output "repository_id" {
  description = "ID du dépôt Artifact Registry"
  value       = google_artifact_registry_repository.main.repository_id
}

output "repository_name" {
  description = "Nom complet du dépôt Artifact Registry"
  value       = google_artifact_registry_repository.main.name
}

output "repository_url" {
  description = "URL du dépôt Artifact Registry"
  value       = "${google_artifact_registry_repository.main.location}-docker.pkg.dev/${data.google_project.current.project_id}/${google_artifact_registry_repository.main.repository_id}"
}

# Récupération des informations du projet
data "google_project" "current" {} 