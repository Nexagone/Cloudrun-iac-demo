# Configuration Cloud SQL

Guide complet pour la configuration et la gestion de l'instance PostgreSQL Cloud SQL dans le cadre du projet de centralisation de données.

## 🗄️ Architecture Cloud SQL

### Instance Principale

```hcl
# Configuration automatique via Terraform
google_sql_database_instance "main" {
  name             = "${var.environment}-postgres-instance"
  database_version = "POSTGRES_14"
  region          = var.region
  
  settings {
    tier                        = var.database_tier
    availability_type           = var.high_availability ? "REGIONAL" : "ZONAL"
    disk_type                  = "PD_SSD"
    disk_size                  = var.disk_size
    disk_autoresize           = true
    disk_autoresize_limit     = var.max_disk_size
    
    backup_configuration {
      enabled                        = true
      start_time                    = "03:00"
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
      backup_retention_settings {
        retained_backups = 30
      }
    }
    
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                              = var.vpc_network
      enable_private_path_for_google_cloud_services = true
    }
  }
}
```

### Configuration par Environnement

| Paramètre | Dev | Staging | Production |
|-----------|-----|---------|------------|
| **Instance** | db-custom-1-2048 | db-custom-2-4096 | db-custom-4-8192 |
| **Stockage** | 20 GB | 50 GB | 100 GB |
| **HA** | Désactivée | Activée | Activée |
| **Réplicas** | 0 | 1 | 2 |
| **Backups** | 7 jours | 14 jours | 30 jours |

## 🔧 Configuration Initiale

### 1. Création via Terraform

```bash
# Déploiement de l'infrastructure de base
make deploy-database ENV=dev

# Vérification du déploiement
terraform output -state=environments/dev/terraform.tfstate database_connection_name
```

### 2. Configuration Manuelle Post-Déploiement

```bash
# Connexion à l'instance
gcloud sql connect INSTANCE_NAME --user=postgres

# Création de l'utilisateur applicatif
CREATE USER app_user WITH PASSWORD 'SECURE_PASSWORD';

# Création de la base de données
CREATE DATABASE data_centralization OWNER app_user;

# Attribution des permissions
GRANT ALL PRIVILEGES ON DATABASE data_centralization TO app_user;
```

### 3. Configuration via Scripts d'Initialisation

```sql
-- scripts/init-database.sql
-- Création du schéma applicatif
CREATE SCHEMA IF NOT EXISTS app_schema;

-- Tables de l'application
CREATE TABLE app_schema.data_sources (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    url VARCHAR(500) NOT NULL,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE app_schema.extracted_data (
    id SERIAL PRIMARY KEY,
    source_id INTEGER REFERENCES app_schema.data_sources(id),
    data JSONB NOT NULL,
    extracted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'pending'
);

-- Index pour les performances
CREATE INDEX idx_extracted_data_source_id ON app_schema.extracted_data(source_id);
CREATE INDEX idx_extracted_data_status ON app_schema.extracted_data(status);
CREATE INDEX idx_extracted_data_extracted_at ON app_schema.extracted_data(extracted_at);

-- Permissions pour l'utilisateur applicatif
GRANT USAGE ON SCHEMA app_schema TO app_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA app_schema TO app_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA app_schema TO app_user;
```

## 🔐 Sécurité et Authentification

### Configuration des Secrets

```bash
# Création du secret pour le mot de passe
gcloud secrets create db-password \
  --data-file=- <<< "SECURE_DATABASE_PASSWORD"

# Attribution des permissions au service account
gcloud secrets add-iam-policy-binding db-password \
  --member="serviceAccount:SA_EMAIL" \
  --role="roles/secretmanager.secretAccessor"
```

### Authentification via Workload Identity

```hcl
# Configuration automatique dans le module IAM
resource "google_project_iam_member" "cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.app.email}"
}

resource "google_project_iam_member" "cloudsql_instance_user" {
  project = var.project_id
  role    = "roles/cloudsql.instanceUser"
  member  = "serviceAccount:${google_service_account.app.email}"
}
```

### Connexion Sécurisée depuis Cloud Run

```java
// Configuration Spring Boot (application.yml)
spring:
  datasource:
    url: jdbc:postgresql:///${DB_NAME}?cloudSqlInstance=${INSTANCE_CONNECTION_NAME}&socketFactory=com.google.cloud.sql.postgres.SocketFactory
    username: ${DB_USER}
    password: ${DB_PASS}
  jpa:
    database-platform: org.hibernate.dialect.PostgreSQLDialect
    hibernate:
      ddl-auto: validate
```

## 📊 Monitoring et Performance

### Métriques Importantes

```bash
# CPU et mémoire
gcloud monitoring metrics list \
  --filter="resource.type=cloudsql_database AND metric.type=cloudsql.googleapis.com/database/cpu/utilization"

# Connexions actives
gcloud monitoring metrics list \
  --filter="metric.type=cloudsql.googleapis.com/database/postgresql/num_backends"

# Taille de la base de données
gcloud monitoring metrics list \
  --filter="metric.type=cloudsql.googleapis.com/database/disk/bytes_used"
```

### Configuration des Alertes

```hcl
# Alerte CPU élevé
resource "google_monitoring_alert_policy" "database_cpu_high" {
  display_name = "Cloud SQL - CPU élevé"
  
  conditions {
    display_name = "CPU > 80%"
    
    condition_threshold {
      filter         = "resource.type=\"cloudsql_database\""
      comparison     = "COMPARISON_GREATER_THAN"
      threshold_value = 0.8
      duration       = "300s"
      
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = [var.notification_channel_id]
}
```

### Optimisation des Performances

```sql
-- Configuration PostgreSQL optimisée
-- Augmenter les connexions partagées
ALTER SYSTEM SET max_connections = 200;

-- Optimiser la mémoire partagée
ALTER SYSTEM SET shared_buffers = '256MB';

-- Configuration pour les logs lents
ALTER SYSTEM SET log_min_duration_statement = 1000;
ALTER SYSTEM SET log_statement = 'all';

-- Rechargement de la configuration
SELECT pg_reload_conf();
```

## 🔄 Sauvegarde et Restauration

### Configuration des Sauvegardes Automatiques

```hcl
# Configuration automatique via Terraform
backup_configuration {
  enabled                        = true
  start_time                    = "03:00"
  location                      = var.backup_location
  point_in_time_recovery_enabled = true
  transaction_log_retention_days = 7
  
  backup_retention_settings {
    retained_backups = var.backup_retention_days
    retention_unit   = "COUNT"
  }
}
```

### Sauvegarde Manuelle

```bash
# Création d'une sauvegarde ponctuelle
gcloud sql backups create \
  --instance=INSTANCE_NAME \
  --description="Backup before deployment"

# Liste des sauvegardes disponibles
gcloud sql backups list --instance=INSTANCE_NAME

# Export vers Cloud Storage
gcloud sql export sql INSTANCE_NAME gs://BUCKET_NAME/backup-$(date +%Y%m%d-%H%M%S).sql \
  --database=data_centralization
```

### Restauration

```bash
# Restauration depuis une sauvegarde automatique
gcloud sql backups restore BACKUP_ID \
  --restore-instance=INSTANCE_NAME

# Restauration à un point dans le temps
gcloud sql backups restore BACKUP_ID \
  --restore-instance=INSTANCE_NAME \
  --backup-time=2024-01-15T10:00:00Z

# Import depuis Cloud Storage
gcloud sql import sql INSTANCE_NAME gs://BUCKET_NAME/backup.sql \
  --database=data_centralization
```

## 🏠 Réplicas de Lecture

### Configuration des Réplicas

```hcl
# Réplica de lecture pour la production
resource "google_sql_database_instance" "read_replica" {
  count                = var.environment == "prod" ? var.read_replica_count : 0
  name                 = "${var.environment}-postgres-replica-${count.index}"
  master_instance_name = google_sql_database_instance.main.name
  region              = var.region
  database_version    = "POSTGRES_14"
  
  replica_configuration {
    failover_target = false
  }
  
  settings {
    tier              = var.replica_tier
    availability_type = "ZONAL"
    disk_autoresize   = true
    
    ip_configuration {
      ipv4_enabled    = false
      private_network = var.vpc_network
    }
  }
}
```

### Utilisation des Réplicas

```java
// Configuration Spring Boot avec réplicas
@Configuration
public class DatabaseConfig {
    
    @Bean
    @Primary
    @ConfigurationProperties("spring.datasource.master")
    public DataSource masterDataSource() {
        return DataSourceBuilder.create().build();
    }
    
    @Bean
    @ConfigurationProperties("spring.datasource.replica")
    public DataSource replicaDataSource() {
        return DataSourceBuilder.create().build();
    }
    
    @Bean
    public JdbcTemplate masterJdbcTemplate(@Qualifier("masterDataSource") DataSource dataSource) {
        return new JdbcTemplate(dataSource);
    }
    
    @Bean
    public JdbcTemplate replicaJdbcTemplate(@Qualifier("replicaDataSource") DataSource dataSource) {
        return new JdbcTemplate(dataSource);
    }
}
```

## 🔧 Maintenance et Mises à Jour

### Fenêtres de Maintenance

```hcl
# Configuration automatique
maintenance_window {
  day          = 1  # Dimanche
  hour         = 3  # 03:00 UTC
  update_track = "stable"
}
```

### Mise à Jour de Version

```bash
# Lister les versions disponibles
gcloud sql instances patch INSTANCE_NAME \
  --database-version=POSTGRES_15 \
  --async

# Surveillance de la mise à jour
gcloud sql operations list --instance=INSTANCE_NAME
```

### Scaling Vertical

```bash
# Augmentation des ressources
gcloud sql instances patch INSTANCE_NAME \
  --tier=db-custom-4-8192 \
  --async

# Augmentation du stockage
gcloud sql instances patch INSTANCE_NAME \
  --storage-size=200GB \
  --async
```

## 📈 Monitoring Avancé

### Métriques Personnalisées

```sql
-- Vue pour le monitoring applicatif
CREATE VIEW monitoring.database_stats AS
SELECT 
    schemaname,
    tablename,
    n_tup_ins as inserts,
    n_tup_upd as updates,
    n_tup_del as deletes,
    n_live_tup as live_rows,
    n_dead_tup as dead_rows,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM pg_stat_user_tables;

-- Fonction pour les métriques de performance
CREATE OR REPLACE FUNCTION monitoring.get_connection_stats()
RETURNS TABLE(
    total_connections INT,
    active_connections INT,
    idle_connections INT,
    longest_query_duration INTERVAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INT as total_connections,
        COUNT(*) FILTER (WHERE state = 'active')::INT as active_connections,
        COUNT(*) FILTER (WHERE state = 'idle')::INT as idle_connections,
        MAX(NOW() - query_start) as longest_query_duration
    FROM pg_stat_activity
    WHERE pid != pg_backend_pid();
END;
$$ LANGUAGE plpgsql;
```

### Dashboard Cloud Monitoring

```hcl
# Dashboard personnalisé
resource "google_monitoring_dashboard" "database_dashboard" {
  dashboard_json = jsonencode({
    displayName = "Cloud SQL - ${var.environment}"
    mosaicLayout = {
      tiles = [
        {
          width = 6
          height = 4
          widget = {
            title = "CPU Utilization"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloudsql_database\""
                    aggregation = {
                      alignmentPeriod = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
              }]
            }
          }
        }
      ]
    }
  })
}
```

## 🚨 Dépannage

### Problèmes de Connexion

```bash
# Vérifier l'état de l'instance
gcloud sql instances describe INSTANCE_NAME

# Tester la connectivité réseau
gcloud compute ssh INSTANCE_NAME --tunnel-through-iap

# Vérifier les logs de connexion
gcloud logging read "resource.type=cloudsql_database AND protoPayload.methodName=cloudsql.instances.connect"
```

### Problèmes de Performance

```sql
-- Identifier les requêtes lentes
SELECT 
    query,
    calls,
    total_time,
    mean_time,
    rows
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;

-- Vérifier les verrous
SELECT 
    blocked_locks.pid AS blocked_pid,
    blocked_activity.usename AS blocked_user,
    blocking_locks.pid AS blocking_pid,
    blocking_activity.usename AS blocking_user,
    blocked_activity.query AS blocked_statement,
    blocking_activity.query AS blocking_statement
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;
```

### Problèmes d'Espace Disque

```sql
-- Taille des tables
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Nettoyage automatique
VACUUM ANALYZE;

-- Réindexation
REINDEX DATABASE data_centralization;
```

## 📚 Ressources Complémentaires

- [Documentation Cloud SQL](https://cloud.google.com/sql/docs)
- [Guide PostgreSQL sur Cloud SQL](https://cloud.google.com/sql/docs/postgres)
- [Bonnes Pratiques Cloud SQL](https://cloud.google.com/sql/docs/postgres/best-practices)
- [Monitoring Cloud SQL](https://cloud.google.com/sql/docs/postgres/monitoring)
- [Sécurité Cloud SQL](https://cloud.google.com/sql/docs/postgres/security) 