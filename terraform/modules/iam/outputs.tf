output "cloud_run_service_account_email" {
  description = "Email du service account Cloud Run"
  value       = google_service_account.cloud_run.email
}

output "cloud_run_service_account_name" {
  description = "Nom du service account Cloud Run"
  value       = google_service_account.cloud_run.name
}

output "cloud_build_service_account_email" {
  description = "Email du service account Cloud Build"
  value       = google_service_account.cloud_build.email
}

output "monitoring_service_account_email" {
  description = "Email du service account Monitoring"
  value       = google_service_account.monitoring.email
} 