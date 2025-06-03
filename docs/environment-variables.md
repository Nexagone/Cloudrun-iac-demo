# Variables d'Environnement - Application Spring Boot

Ce document décrit toutes les variables d'environnement utilisées par l'application Spring Boot déployée sur Cloud Run.

## 🔧 Variables de Configuration Terraform

Ces variables sont automatiquement configurées par Terraform lors du déploiement :

### Variables de Base de Données

| Variable | Description | Exemple | Obligatoire |
|----------|-------------|---------|-------------|
| `DB_NAME` | Nom de la base de données | `app_db` | ✅ |
| `DB_USER` | Utilisateur de la base de données | `app_user` | ✅ |
| `DB_PASS` | Mot de passe (depuis Secret Manager) | `***` | ✅ |
| `INSTANCE_CONNECTION_NAME` | Nom de connexion Cloud SQL | `project:region:instance` | ✅ |

### Variables d'Application

| Variable | Description | Exemple | Obligatoire |
|----------|-------------|---------|-------------|
| `SPRING_PROFILES_ACTIVE` | Profil Spring actif | `dev`, `staging`, `prod` | ✅ |
| `SERVER_PORT` | Port d'écoute du serveur | `8080` | ✅ |

## 🎯 Variables Personnalisées

Ces variables peuvent être configurées dans le fichier `terraform.tfvars` :

### APIs Externes

| Variable | Description | Exemple | Par Défaut |
|----------|-------------|---------|------------|
| `EXTERNAL_API_URL` | URL de l'API externe | `https://api.exemple.com` | - |
| `EXTERNAL_API_KEY` | Clé d'API externe | `sk-...` | - |
| `EXTERNAL_API_TIMEOUT` | Timeout des requêtes (ms) | `30000` | `10000` |

### Google Sheets API

| Variable | Description | Exemple | Par Défaut |
|----------|-------------|---------|------------|
| `SHEETS_API_ENABLED` | Activer l'API Sheets | `true`, `false` | `true` |
| `SHEETS_SPREADSHEET_ID` | ID du spreadsheet | `1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms` | - |
| `SHEETS_RANGE` | Plage de cellules | `Sheet1!A1:E` | `Sheet1!A:Z` |

### Configuration de Logging

| Variable | Description | Exemple | Par Défaut |
|----------|-------------|---------|------------|
| `LOG_LEVEL` | Niveau de log | `DEBUG`, `INFO`, `WARN`, `ERROR` | `INFO` |
| `LOG_FORMAT` | Format des logs | `JSON`, `PLAIN` | `JSON` |
| `LOG_INCLUDE_MDC` | Inclure le MDC | `true`, `false` | `true` |

### Configuration de Cache

| Variable | Description | Exemple | Par Défaut |
|----------|-------------|---------|------------|
| `CACHE_ENABLED` | Activer le cache | `true`, `false` | `true` |
| `CACHE_TTL_SECONDS` | TTL du cache (secondes) | `3600` | `1800` |
| `CACHE_MAX_SIZE` | Taille max du cache | `1000` | `500` |

### Configuration de Sécurité

| Variable | Description | Exemple | Par Défaut |
|----------|-------------|---------|------------|
| `SECURITY_ENABLED` | Activer la sécurité | `true`, `false` | `true` |
| `JWT_SECRET` | Secret JWT | `secret-key` | - |
| `JWT_EXPIRATION` | Expiration JWT (ms) | `86400000` | `3600000` |

### Configuration de Monitoring

| Variable | Description | Exemple | Par Défaut |
|----------|-------------|---------|------------|
| `METRICS_ENABLED` | Activer les métriques | `true`, `false` | `true` |
| `HEALTH_CHECK_PATH` | Chemin du health check | `/actuator/health` | `/actuator/health` |
| `MANAGEMENT_PORT` | Port de management | `8081` | `8080` |

## 🔒 Variables Sensibles

Ces variables contiennent des informations sensibles et sont gérées via Secret Manager :

### Secrets Automatiques (Terraform)

- `DB_PASS` : Mot de passe de la base de données
- `DB_ROOT_PASS` : Mot de passe root de la base de données

### Secrets Personnalisés

Pour ajouter des secrets personnalisés :

1. **Créer le secret dans Secret Manager** :
```bash
echo -n "ma-valeur-secrete" | gcloud secrets create mon-secret --data-file=-
```

2. **Ajouter dans le module Cloud Run** :
```hcl
env {
  name = "MON_SECRET"
  value_source {
    secret_key_ref {
      secret  = "mon-secret"
      version = "latest"
    }
  }
}
```

## 📝 Configuration par Environnement

### Développement (`dev`)

```bash
SPRING_PROFILES_ACTIVE=dev
LOG_LEVEL=DEBUG
CACHE_ENABLED=false
SECURITY_ENABLED=false
EXTERNAL_API_URL=https://api.dev.exemple.com
```

### Staging (`staging`)

```bash
SPRING_PROFILES_ACTIVE=staging
LOG_LEVEL=INFO
CACHE_ENABLED=true
SECURITY_ENABLED=true
EXTERNAL_API_URL=https://api.staging.exemple.com
```

### Production (`prod`)

```bash
SPRING_PROFILES_ACTIVE=prod
LOG_LEVEL=WARN
CACHE_ENABLED=true
SECURITY_ENABLED=true
EXTERNAL_API_URL=https://api.exemple.com
```

## 🔧 Configuration Spring Boot

### application.yml

```yaml
spring:
  profiles:
    active: ${SPRING_PROFILES_ACTIVE:dev}
  
  datasource:
    url: jdbc:postgresql:///${DB_NAME}?socketFactory=com.google.cloud.sql.postgres.SocketFactory&cloudSqlInstance=${INSTANCE_CONNECTION_NAME}
    username: ${DB_USER}
    password: ${DB_PASS}
    driver-class-name: org.postgresql.Driver
  
  jpa:
    hibernate:
      ddl-auto: validate
    show-sql: false
    properties:
      hibernate:
        dialect: org.hibernate.dialect.PostgreSQLDialect

server:
  port: ${SERVER_PORT:8080}

logging:
  level:
    root: ${LOG_LEVEL:INFO}
    com.entreprise.app: ${LOG_LEVEL:INFO}
  pattern:
    console: "%d{yyyy-MM-dd HH:mm:ss} - %msg%n"

management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
  endpoint:
    health:
      show-details: always

app:
  external-api:
    url: ${EXTERNAL_API_URL:}
    timeout: ${EXTERNAL_API_TIMEOUT:10000}
  
  sheets:
    enabled: ${SHEETS_API_ENABLED:true}
    spreadsheet-id: ${SHEETS_SPREADSHEET_ID:}
    range: ${SHEETS_RANGE:Sheet1!A:Z}
  
  cache:
    enabled: ${CACHE_ENABLED:true}
    ttl-seconds: ${CACHE_TTL_SECONDS:1800}
    max-size: ${CACHE_MAX_SIZE:500}
```

### application-dev.yml

```yaml
spring:
  jpa:
    show-sql: true
    hibernate:
      ddl-auto: create-drop

logging:
  level:
    org.springframework.web: DEBUG
    org.hibernate.SQL: DEBUG
```

### application-prod.yml

```yaml
spring:
  jpa:
    hibernate:
      ddl-auto: validate

logging:
  level:
    org.springframework.web: WARN
```

## 🚀 Déploiement

### Via Terraform

Les variables sont automatiquement configurées dans le module Cloud Run :

```hcl
environment_variables = {
  "EXTERNAL_API_URL"   = "https://api.exemple.com"
  "SHEETS_API_ENABLED" = "true"
  "LOG_LEVEL"         = "INFO"
  "CACHE_ENABLED"     = "true"
}
```

### Via Cloud Build

```yaml
substitutions:
  _EXTERNAL_API_URL: 'https://api.exemple.com'
  _LOG_LEVEL: 'INFO'

steps:
- name: 'gcr.io/cloud-builders/gcloud'
  args: [
    'run', 'deploy', '${_SERVICE_NAME}',
    '--set-env-vars', 'EXTERNAL_API_URL=${_EXTERNAL_API_URL}',
    '--set-env-vars', 'LOG_LEVEL=${_LOG_LEVEL}'
  ]
```

### Via gcloud CLI

```bash
gcloud run deploy mon-service \
  --image=gcr.io/mon-projet/mon-app \
  --set-env-vars="EXTERNAL_API_URL=https://api.exemple.com" \
  --set-env-vars="LOG_LEVEL=INFO" \
  --set-secrets="DB_PASS=db-password:latest"
```

## 🔍 Debugging

### Vérifier les Variables

```bash
# Lister les variables d'environnement
gcloud run services describe mon-service --region=europe-west1 --format="value(spec.template.spec.template.spec.containers[0].env[].name)"

# Voir la configuration complète
gcloud run services describe mon-service --region=europe-west1
```

### Logs d'Application

```bash
# Voir les logs en temps réel
gcloud logging tail "resource.type=cloud_run_revision"

# Filtrer par service
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=mon-service"
```

## 📚 Références

- [Spring Boot Configuration](https://docs.spring.io/spring-boot/docs/current/reference/html/features.html#features.external-config)
- [Cloud Run Environment Variables](https://cloud.google.com/run/docs/configuring/environment-variables)
- [Secret Manager](https://cloud.google.com/secret-manager/docs)
- [Cloud SQL Connector](https://cloud.google.com/sql/docs/postgres/connect-run) 