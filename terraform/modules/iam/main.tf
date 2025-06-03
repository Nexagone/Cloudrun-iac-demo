# Service Account pour Cloud Run
resource "google_service_account" "cloud_run" {
  account_id   = "${var.project_name}-${var.environment}-cloudrun"
  display_name = "Service Account pour Cloud Run ${var.environment}"
  description  = "Service Account avec permissions minimales pour Cloud Run"
}

# Permissions pour accéder aux secrets
resource "google_project_iam_member" "secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.cloud_run.email}"
}

# Permissions pour Cloud SQL
resource "google_project_iam_member" "cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloud_run.email}"
}

# Permissions pour Cloud Logging
resource "google_project_iam_member" "log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cloud_run.email}"
}

# Permissions pour Cloud Monitoring
resource "google_project_iam_member" "monitoring_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.cloud_run.email}"
}

# Service Account pour Cloud Build
resource "google_service_account" "cloud_build" {
  account_id   = "${var.project_name}-${var.environment}-cloudbuild"  
  display_name = "Service Account pour Cloud Build ${var.environment}"
  description  = "Service Account pour les déploiements CI/CD"
}

# Permissions pour Cloud Build - accès aux images
resource "google_project_iam_member" "cloud_build_storage" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.cloud_build.email}"
}

# Permissions pour Cloud Build - déploiement Cloud Run
resource "google_project_iam_member" "cloud_build_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.cloud_build.email}"
}

# Permissions pour Cloud Build - accès aux secrets
resource "google_project_iam_member" "cloud_build_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.cloud_build.email}"
}

# Permissions pour Cloud Build - agir en tant que service account
resource "google_service_account_iam_member" "cloud_build_sa_user" {
  service_account_id = google_service_account.cloud_run.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.cloud_build.email}"
}

# Service Account pour monitoring
resource "google_service_account" "monitoring" {
  account_id   = "${var.project_name}-${var.environment}-monitoring"
  display_name = "Service Account pour Monitoring ${var.environment}"
  description  = "Service Account pour les alertes et dashboards"
}

# Permissions pour monitoring - lecture des métriques
resource "google_project_iam_member" "monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.monitoring.email}"
}

# Workload Identity pour les services externes si nécessaire
resource "google_service_account_iam_member" "workload_identity" {
  count = length(var.workload_identity_users)
  
  service_account_id = google_service_account.cloud_run.name
  role               = "roles/iam.workloadIdentityUser"
  member             = var.workload_identity_users[count.index]
} 