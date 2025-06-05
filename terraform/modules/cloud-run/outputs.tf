output "service_name" {
  description = "Nom du service Cloud Run"
  value       = google_cloud_run_v2_service.main.name
}

output "service_url" {
  description = "URL du service Cloud Run"
  value       = google_cloud_run_v2_service.main.uri
}

output "service_location" {
  description = "Région du service Cloud Run"
  value       = google_cloud_run_v2_service.main.location
}

output "vpc_connector_name" {
  description = "Nom du connecteur VPC"
  value       = var.create_vpc_connector ? google_vpc_access_connector.connector[0].name : ""
}

output "custom_domain_status" {
  description = "Statut du domaine personnalisé"
  value       = var.custom_domain != "" ? google_cloud_run_domain_mapping.domain[0].status : null
} 