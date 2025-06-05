# Canal de notification Email
resource "google_monitoring_notification_channel" "email" {
  count = length(var.notification_emails)
  
  display_name = "Email ${var.notification_emails[count.index]}"
  type         = "email"
  
  labels = {
    email_address = var.notification_emails[count.index]
  }
  
  enabled = true
}

# Uptime check sur l'endpoint principal
resource "google_monitoring_uptime_check_config" "health_check" {
  display_name = "${var.project_name}-${var.environment}-health-check"
  timeout      = "10s"
  period       = "60s"
  
  http_check {
    path         = var.health_check_path
    port         = 443
    use_ssl      = true
    validate_ssl = true
  }
  
  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = replace(var.service_url, "https://", "")
    }
  }
  
  checker_type = "STATIC_IP_CHECKERS"
}

# Alertes sur la disponibilité
resource "google_monitoring_alert_policy" "uptime_alert" {
  display_name = "${var.project_name}-${var.environment} - Service Unavailable"
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "Uptime check failing"
    
    condition_threshold {
      filter          = "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" resource.type=\"uptime_url\" metric.label.check_id=\"${google_monitoring_uptime_check_config.health_check.uptime_check_id}\""
      duration        = "300s"
      comparison      = "COMPARISON_LT"
      threshold_value = 1
      
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_NEXT_OLDER"
        cross_series_reducer = "REDUCE_COUNT_FALSE"
        group_by_fields     = ["resource.label.project_id"]
      }
      
      trigger {
        count = 1
      }
    }
  }
  
  notification_channels = [for ch in google_monitoring_notification_channel.email : ch.id]
  
  alert_strategy {
    auto_close = "1800s"
  }
}

# Alertes sur la latence
resource "google_monitoring_alert_policy" "latency_alert" {
  display_name = "${var.project_name}-${var.environment} - High Latency"
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "High request latency"
    
    condition_threshold {
      filter         = "resource.type=\"cloud_run_revision\" resource.label.service_name=\"${var.service_name}\" metric.type=\"run.googleapis.com/request_latencies\""
      duration       = "300s"
      comparison     = "COMPARISON_GT"
      threshold_value = var.latency_threshold_ms
      
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_DELTA"
        cross_series_reducer = "REDUCE_PERCENTILE_95"
        group_by_fields     = ["resource.label.service_name"]
      }
    }
  }
  
  notification_channels = [for ch in google_monitoring_notification_channel.email : ch.id]
}

# Alertes sur le taux d'erreur
resource "google_monitoring_alert_policy" "error_rate_alert" {
  display_name = "${var.project_name}-${var.environment} - High Error Rate"
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "High error rate"
    
    condition_threshold {
      filter         = "resource.type=\"cloud_run_revision\" resource.label.service_name=\"${var.service_name}\" metric.type=\"run.googleapis.com/request_count\" metric.label.response_code_class!=\"2xx\""
      duration       = "300s"
      comparison     = "COMPARISON_GT"
      threshold_value = var.error_rate_threshold
      
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields     = ["resource.label.service_name"]
      }
    }
  }
  
  notification_channels = [for ch in google_monitoring_notification_channel.email : ch.id]
}

# Alertes sur l'utilisation CPU
resource "google_monitoring_alert_policy" "cpu_alert" {
  display_name = "${var.project_name}-${var.environment} - High CPU Usage"
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "High CPU utilization"
    
    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" resource.label.service_name=\"${var.service_name}\" metric.type=\"run.googleapis.com/container/cpu/utilizations\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.cpu_threshold
      
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_PERCENTILE_99"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields     = ["resource.label.service_name"]
      }
    }
  }
  
  notification_channels = [for ch in google_monitoring_notification_channel.email : ch.id]
}

# Alertes sur l'utilisation mémoire
resource "google_monitoring_alert_policy" "memory_alert" {
  display_name = "${var.project_name}-${var.environment} - High Memory Usage"
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "High memory utilization"
    
    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" resource.label.service_name=\"${var.service_name}\" metric.type=\"run.googleapis.com/container/memory/utilizations\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.memory_threshold
      
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_PERCENTILE_99"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields     = ["resource.label.service_name"]
      }
    }
  }
  
  notification_channels = [for ch in google_monitoring_notification_channel.email : ch.id]
}

# Alertes Cloud SQL - connexions
resource "google_monitoring_alert_policy" "sql_connections_alert" {
  count = var.sql_instance_name != "" ? 1 : 0
  
  display_name = "${var.project_name}-${var.environment} - High SQL Connections"
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "High database connections"
    
    condition_threshold {
      filter         = "resource.type=\"cloudsql_database\" resource.label.database_id=\"${var.project_id}:${var.sql_instance_name}\" metric.type=\"cloudsql.googleapis.com/database/postgresql/num_backends\""
      duration       = "300s"
      comparison     = "COMPARISON_GT"
      threshold_value = var.sql_connections_threshold
      
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MEAN"
      }
    }
  }
  
  notification_channels = [for ch in google_monitoring_notification_channel.email : ch.id]
}

# Dashboard principal
resource "google_monitoring_dashboard" "main" {
  dashboard_json = jsonencode({
    displayName = "${var.project_name}-${var.environment} - Application Dashboard"
    
    gridLayout = {
      columns = 2
      widgets = [
        {
          title = "Requêtes par minute"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"cloud_run_revision\" resource.label.service_name=\"${var.service_name}\" metric.type=\"run.googleapis.com/request_count\""
                  aggregation = {
                    alignmentPeriod = "60s"
                    perSeriesAligner = "ALIGN_RATE"
                    crossSeriesReducer = "REDUCE_SUM"
                    groupByFields = ["resource.label.service_name"]
                  }
                }
              }
              plotType = "LINE"
            }]
            timeshiftDuration = "0s"
            yAxis = {
              label = "Requests/min"
              scale = "LINEAR"
            }
          }
        },
        {
          title = "Latence P95"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"cloud_run_revision\" resource.label.service_name=\"${var.service_name}\" metric.type=\"run.googleapis.com/request_latencies\""
                  aggregation = {
                    alignmentPeriod = "60s"
                    perSeriesAligner = "ALIGN_DELTA"
                    crossSeriesReducer = "REDUCE_PERCENTILE_95"
                    groupByFields = ["resource.label.service_name"]
                  }
                }
              }
              plotType = "LINE"
            }]
            yAxis = {
              label = "Latency (ms)"
              scale = "LINEAR"
            }
          }
        },
        {
          title = "Taux d'erreur"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"cloud_run_revision\" resource.label.service_name=\"${var.service_name}\" metric.type=\"run.googleapis.com/request_count\" metric.label.response_code_class!=\"2xx\""
                  aggregation = {
                    alignmentPeriod = "60s"
                    perSeriesAligner = "ALIGN_RATE"
                    crossSeriesReducer = "REDUCE_SUM"
                    groupByFields = ["resource.label.service_name"]
                  }
                }
              }
              plotType = "LINE"
            }]
            yAxis = {
              label = "Errors/min"
              scale = "LINEAR"
            }
          }
        },
        {
          title = "Utilisation CPU"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"cloud_run_revision\" resource.label.service_name=\"${var.service_name}\" metric.type=\"run.googleapis.com/container/cpu/utilizations\""
                  aggregation = {
                    alignmentPeriod = "60s"
                    perSeriesAligner = "ALIGN_PERCENTILE_99"
                    crossSeriesReducer = "REDUCE_MEAN"
                    groupByFields = ["resource.label.service_name"]
                  }
                }
              }
              plotType = "LINE"
            }]
            yAxis = {
              label = "CPU %"
              scale = "LINEAR"
            }
          }
        }
      ]
    }
  })
}

# Log sink pour BigQuery (analyse long terme)
resource "google_logging_project_sink" "bigquery_sink" {
  count = var.enable_log_sink ? 1 : 0
  
  name        = "${var.project_name}-${var.environment}-logs-sink"
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${var.bigquery_dataset}"
  
  filter = "resource.type=\"cloud_run_revision\" resource.labels.service_name=\"${var.service_name}\""
  
  unique_writer_identity = true
}

# Dataset BigQuery pour les logs
resource "google_bigquery_dataset" "logs" {
  count = var.enable_log_sink ? 1 : 0
  
  dataset_id    = var.bigquery_dataset
  friendly_name = "Logs ${var.project_name} ${var.environment}"
  description   = "Dataset pour stocker les logs de l'application"
  location      = var.region
  
  labels = var.labels
}

# Permissions pour le log sink
resource "google_bigquery_dataset_iam_member" "sink_writer" {
  count = var.enable_log_sink ? 1 : 0
  
  dataset_id = google_bigquery_dataset.logs[0].dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_project_sink.bigquery_sink[0].writer_identity
} 