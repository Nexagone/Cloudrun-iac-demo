# Service Cloud Run
resource "google_cloud_run_v2_service" "main" {
  name     = "${var.project_name}-${var.environment}-service"
  location = var.region
  
  deletion_protection = var.environment == "prod" ? true : false
  
  template {
    service_account = var.service_account_email
    
    # Configuration du scaling
    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }
    
    # Configuration des volumes pour Cloud SQL
    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [var.sql_connection_name]
      }
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
        value = "localhost"  # Utilisation de localhost car Cloud SQL est monté localement
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
      
      # Configuration des volumes
      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }
      
      # Health check personnalisé
      startup_probe {
        http_get {
          path = var.health_check_path
          port = var.port
        }
        initial_delay_seconds = 30
        timeout_seconds      = 10
        period_seconds       = 10
        failure_threshold    = 3
      }
      
      # Configuration des credentials Docker si fournis
      dynamic "image_pull_credentials" {
        for_each = var.docker_registry_credentials != null ? [1] : []
        content {
          secret_name = google_secret_manager_secret.docker_credentials[0].secret_id
        }
      }
      
      liveness_probe {
        http_get {
          path = var.health_check_path
          port = var.port
        }
        initial_delay_seconds = 60
        timeout_seconds      = 10
        period_seconds       = 30
        failure_threshold    = 3
      }
    }
    
    # Configuration réseau
    vpc_access {
      connector = var.vpc_connector_name
      egress    = "PRIVATE_RANGES_ONLY"
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
  
  labels = var.labels
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
  
  name          = "${var.project_name}-${var.environment}-connector"
  region        = var.region
  ip_cidr_range = var.vpc_connector_cidr
  network       = var.network_name
  
  min_instances = 2
  max_instances = 10
  
  machine_type = "e2-micro"
}

# Secret pour les credentials Docker
resource "google_secret_manager_secret" "docker_credentials" {
  count = var.docker_registry_credentials != null ? 1 : 0
  
  secret_id = "${var.project_name}-${var.environment}-docker-credentials"
  
  replication {
    auto {}
  }
  
  labels = var.labels
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