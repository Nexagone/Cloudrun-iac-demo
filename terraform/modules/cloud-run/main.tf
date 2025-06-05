# Récupération des informations de l'instance Cloud SQL
data "google_sql_database_instance" "instance" {
  name = element(split(":", var.sql_connection_name), 2)
}

# Service Cloud Run
resource "google_cloud_run_v2_service" "main" {
  name     = var.service_name
  location = var.region
  
  template {
    service_account = var.service_account_email
    
    # Configuration du scaling
    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }
    
    containers {
      image = var.image_url
      
      # Configuration des ressources
      resources {
        limits = {
          cpu    = var.cpu_limit
          memory = var.memory_limit
        }
        cpu_idle = var.environment == "prod" ? false : true
        startup_cpu_boost = var.environment == "prod" ? true : false
      }
      
      # Variables d'environnement Spring Boot
      env {
        name  = "SPRING_DATASOURCE_HOST"
        value = data.google_sql_database_instance.instance.private_ip_address
      }
      
      env {
        name  = "SPRING_DATASOURCE_PORT"
        value = "5432"
      }
      
      env {
        name  = "SPRING_DATASOURCE_DB"
        value = var.database_name
      }
      
      env {
        name  = "SPRING_DATASOURCE_USERNAME"
        value = var.database_user
      }
      
      env {
        name  = "SPRING_DATASOURCE_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = var.db_password_secret_name
            version = "latest"
          }
        }
      }
      
      # Variables supplémentaires pour l'application
      dynamic "env" {
        for_each = var.environment_variables
        content {
          name  = env.key
          value = env.value
        }
      }
      
      # Port d'écoute
      ports {
        container_port = var.port
        name           = "http1"
      }
      
      # Health check personnalisé
      startup_probe {
        http_get {
          path = var.health_check_path
          port = var.port
        }
        initial_delay_seconds = 60
        timeout_seconds      = 10
        period_seconds      = 10
        failure_threshold    = 5
      }
      
      # Configuration des credentials Docker si fournis
      dynamic "env" {
        for_each = var.docker_registry_credentials != null ? [1] : []
        content {
          name = "DOCKER_CONFIG"
          value_source {
            secret_key_ref {
              secret = google_secret_manager_secret.docker_credentials[0].secret_id
              version = "latest"
            }
          }
        }
      }
      
      liveness_probe {
        http_get {
          path = var.health_check_path
          port = var.port
        }
        initial_delay_seconds = 60
        timeout_seconds      = 10
        period_seconds      = 30
        failure_threshold    = 3
      }
    }
    
    # Configuration réseau
    dynamic "vpc_access" {
      for_each = var.vpc_connector_name != "" ? [1] : []
      content {
        connector = "projects/${var.project_id}/locations/${var.region}/connectors/${var.vpc_connector_name}"
        egress    = "PRIVATE_RANGES_ONLY"
      }
    }
    
    # Annotations pour optimisations
    annotations = {
      "autoscaling.knative.dev/maxScale"        = tostring(var.max_instances)
      "autoscaling.knative.dev/minScale"        = tostring(var.min_instances)
      "run.googleapis.com/cpu-throttling"       = var.environment == "prod" ? "false" : "true"
      "run.googleapis.com/execution-environment" = "gen2"
    }
  }
  
  # Configuration du trafic
  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }
  
  labels = local.normalized_labels
}

# Politique IAM pour permettre l'accès public si nécessaire
resource "google_cloud_run_service_iam_member" "public_access" {
  count = var.allow_public_access ? 1 : 0
  
  location = google_cloud_run_v2_service.main.location
  service  = google_cloud_run_v2_service.main.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Domaine personnalisé (optionnel)
resource "google_cloud_run_domain_mapping" "domain" {
  count = var.custom_domain != "" ? 1 : 0
  
  location = var.region
  name     = var.custom_domain
  
  metadata {
    namespace = var.project_id
  }
  
  spec {
    route_name = google_cloud_run_v2_service.main.name
  }
}

# Connecteur VPC (si pas déjà créé)
resource "google_vpc_access_connector" "connector" {
  count = var.create_vpc_connector ? 1 : 0
  
  name          = "run-${var.environment}-connector"
  region        = var.region
  ip_cidr_range = var.vpc_connector_cidr
  network       = var.network_name
  
  min_instances = 2  # Minimum requis par GCP
  max_instances = 3  # On garde un maximum bas pour contrôler les coûts
  
  machine_type = "e2-micro"
}

# Secret pour les credentials Docker
resource "google_secret_manager_secret" "docker_credentials" {
  count = var.docker_registry_credentials != null ? 1 : 0
  
  secret_id = "${lower(var.project_name)}-${var.environment}-docker-credentials"
  
  replication {
    auto {}
  }
  
  labels = local.normalized_labels
}

resource "google_secret_manager_secret_version" "docker_credentials" {
  count = var.docker_registry_credentials != null ? 1 : 0
  
  secret = google_secret_manager_secret.docker_credentials[0].id
  
  secret_data = jsonencode({
    auths = {
      "${var.docker_registry_credentials.server}" = {
        username = var.docker_registry_credentials.username
        password = var.docker_registry_credentials.password
        auth     = base64encode("${var.docker_registry_credentials.username}:${var.docker_registry_credentials.password}")
      }
    }
  })
} 