output "dashboard_url" {
  description = "URL du dashboard Monitoring"
  value       = "https://console.cloud.google.com/monitoring/dashboards/custom/${google_monitoring_dashboard.main.id}?project=${var.project_id}"
}

output "uptime_check_id" {
  description = "ID de l'uptime check"
  value       = google_monitoring_uptime_check_config.health_check.uptime_check_id
}

output "notification_channels" {
  description = "IDs des canaux de notification email"
  value       = [for ch in google_monitoring_notification_channel.email : ch.id]
}

output "log_sink_name" {
  description = "Nom du sink de logs vers BigQuery"
  value       = var.enable_log_sink ? google_logging_project_sink.bigquery_sink[0].name : null
}

output "bigquery_dataset_id" {
  description = "ID du dataset BigQuery pour les logs"
  value       = var.enable_log_sink ? google_bigquery_dataset.logs[0].dataset_id : null
} 