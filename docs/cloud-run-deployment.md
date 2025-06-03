# Guide de Déploiement Cloud Run

Ce guide détaille le processus de déploiement de l'application Spring Boot sur Cloud Run avec l'infrastructure Terraform.

## 🚀 Processus de Déploiement

### 1. Déploiement via Terraform

Le déploiement initial se fait via Terraform qui configure toute l'infrastructure :

```bash
# Déploiement complet
make apply ENV=dev

# Ou déploiement par étapes
make deploy-base ENV=dev     # Infrastructure de base
make deploy-database ENV=dev # Base de données
make deploy-app ENV=dev      # Application Cloud Run
```

### 2. Déploiement via Cloud Build

Pour les mises à jour de l'application, utilisez Cloud Build :

```bash
# Déclencher un build depuis le repository
gcloud builds submit --config=cloudbuild.yaml

# Avec des variables personnalisées
gcloud builds submit \
  --config=cloudbuild.yaml \
  --substitutions=_ENVIRONMENT=dev,_MEMORY=1Gi
```

### 3. Déploiement Direct via gcloud

Pour un déploiement rapide d'une nouvelle image :

```bash
# Déploiement simple
gcloud run deploy data-centralization-dev-service \
  --image=europe-west1-docker.pkg.dev/PROJECT/REPO/app:latest \
  --region=europe-west1

# Déploiement avec toutes les configurations
gcloud run deploy data-centralization-dev-service \
  --image=europe-west1-docker.pkg.dev/PROJECT/REPO/app:latest \
  --region=europe-west1 \
  --service-account=SERVICE_ACCOUNT@PROJECT.iam.gserviceaccount.com \
  --set-env-vars="SPRING_PROFILES_ACTIVE=dev" \
  --set-secrets="DB_PASS=db-password:latest" \
  --vpc-connector=vpc-connector \
  --vpc-egress=private-ranges-only \
  --memory=512Mi \
  --cpu=1000m \
  --min-instances=0 \
  --max-instances=5
```

## 🔧 Configuration Cloud Run

### Variables d'Environnement Automatiques

L'infrastructure Terraform configure automatiquement :

| Variable | Source | Description |
|----------|--------|-------------|
| `SPRING_PROFILES_ACTIVE` | Terraform | Profil Spring (dev/staging/prod) |
| `DB_NAME` | Module Cloud SQL | Nom de la base de données |
| `DB_USER` | Module Cloud SQL | Utilisateur de l'application |
| `INSTANCE_CONNECTION_NAME` | Module Cloud SQL | Connexion Cloud SQL |
| `DB_PASS` | Secret Manager | Mot de passe (secret) |

### Configuration Réseau

```hcl
# VPC Connector configuré automatiquement
vpc_access {
  connector = var.vpc_connector_name
  egress    = "PRIVATE_RANGES_ONLY"
}
```

### Scaling par Environnement

| Environnement | Min Instances | Max Instances | CPU | Mémoire |
|---------------|---------------|---------------|-----|---------|
| **Dev** | 0 | 5 | 1000m | 512Mi |
| **Staging** | 1 | 10 | 1000m | 1Gi |
| **Prod** | 2 | 100 | 2000m | 2Gi |

## 📦 Gestion des Images Docker

### 1. Build Local

```bash
# Build de l'image
docker build -t app:latest .

# Tag pour Artifact Registry
docker tag app:latest europe-west1-docker.pkg.dev/PROJECT/REPO/app:latest

# Push vers Artifact Registry
docker push europe-west1-docker.pkg.dev/PROJECT/REPO/app:latest
```

### 2. Build via Cloud Build

```yaml
# cloudbuild.yaml
steps:
- name: 'gcr.io/cloud-builders/docker'
  args: ['build', '-t', '${_IMAGE_URL}', '.']
- name: 'gcr.io/cloud-builders/docker'
  args: ['push', '${_IMAGE_URL}']
```

### 3. Versioning des Images

```bash
# Tag avec version
docker tag app:latest europe-west1-docker.pkg.dev/PROJECT/REPO/app:1.2.3

# Tag avec commit SHA
docker tag app:latest europe-west1-docker.pkg.dev/PROJECT/REPO/app:${SHORT_SHA}
```

## 🔄 Stratégies de Déploiement

### 1. Déploiement Blue/Green

```bash
# Déployer une nouvelle révision sans trafic
gcloud run deploy SERVICE_NAME \
  --image=NEW_IMAGE \
  --no-traffic

# Migrer le trafic graduellement
gcloud run services update-traffic SERVICE_NAME \
  --to-revisions=NEW_REVISION=50,OLD_REVISION=50

# Basculer complètement
gcloud run services update-traffic SERVICE_NAME \
  --to-latest
```

### 2. Déploiement Canary

```bash
# Déployer avec 10% du trafic
gcloud run deploy SERVICE_NAME \
  --image=NEW_IMAGE \
  --traffic=10

# Augmenter le trafic si tout va bien
gcloud run services update-traffic SERVICE_NAME \
  --to-revisions=NEW_REVISION=50,OLD_REVISION=50
```

### 3. Rollback Rapide

```bash
# Lister les révisions
gcloud run revisions list --service=SERVICE_NAME

# Rollback vers une révision précédente
gcloud run services update-traffic SERVICE_NAME \
  --to-revisions=PREVIOUS_REVISION=100
```

## 🏥 Health Checks et Monitoring

### Configuration des Health Checks

```hcl
# Dans le module Cloud Run
startup_probe {
  http_get {
    path = "/actuator/health"
    port = 8080
  }
  initial_delay_seconds = 30
  timeout_seconds      = 10
  period_seconds       = 10
  failure_threshold    = 3
}

liveness_probe {
  http_get {
    path = "/actuator/health"
    port = 8080
  }
  initial_delay_seconds = 60
  timeout_seconds      = 10
  period_seconds       = 30
  failure_threshold    = 3
}
```

### Vérification Post-Déploiement

```bash
# Test du health check
curl -f https://SERVICE_URL/actuator/health

# Vérification des métriques
curl https://SERVICE_URL/actuator/metrics

# Test des endpoints applicatifs
curl https://SERVICE_URL/api/data
```

## 🔐 Sécurité du Déploiement

### Service Account

```bash
# Vérifier les permissions du service account
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --format="table(bindings.role)" \
  --filter="bindings.members:serviceAccount:SA_EMAIL"
```

### Secrets et Variables

```bash
# Lister les secrets accessibles
gcloud secrets list

# Vérifier l'accès aux secrets
gcloud secrets versions access latest --secret="SECRET_NAME"

# Tester les variables d'environnement
gcloud run services describe SERVICE_NAME \
  --format="export" | grep -A 50 "env:"
```

## 📊 Monitoring du Déploiement

### Logs de Déploiement

```bash
# Logs Cloud Build
gcloud logging read "resource.type=build AND resource.labels.build_id=BUILD_ID"

# Logs Cloud Run pendant le déploiement
gcloud logging read "resource.type=cloud_run_revision AND timestamp>=2024-01-01T00:00:00Z"
```

### Métriques de Performance

```bash
# Métriques de latence
gcloud logging read "resource.type=cloud_run_revision AND httpRequest.latency>1s"

# Métriques d'erreurs
gcloud logging read "resource.type=cloud_run_revision AND httpRequest.status>=400"
```

## 🚨 Dépannage du Déploiement

### Problèmes Courants

#### 1. Erreur de Démarrage

```bash
# Vérifier les logs de démarrage
gcloud logging read "resource.type=cloud_run_revision AND textPayload:ERROR"

# Solutions courantes :
# - Vérifier les variables d'environnement
# - Contrôler la connectivité à Cloud SQL
# - Valider les permissions du service account
```

#### 2. Timeout de Déploiement

```bash
# Augmenter le timeout
gcloud run deploy SERVICE_NAME \
  --timeout=900

# Optimiser l'image Docker
# - Utiliser des images de base plus légères
# - Réduire la taille de l'application
# - Optimiser le temps de démarrage JVM
```

#### 3. Problèmes de Connectivité

```bash
# Vérifier le VPC Connector
gcloud compute networks vpc-access connectors describe CONNECTOR_NAME \
  --region=REGION

# Tester la connectivité réseau
gcloud run services replace service.yaml
```

### Commandes de Debug

```bash
# Obtenir les détails complets du service
gcloud run services describe SERVICE_NAME \
  --region=REGION \
  --format=export > service-config.yaml

# Vérifier l'état des révisions
gcloud run revisions list \
  --service=SERVICE_NAME \
  --region=REGION

# Analyser les métriques de performance
gcloud monitoring metrics list \
  --filter="resource.type=cloud_run_revision"
```

## 🔄 Automatisation CI/CD

### Pipeline GitLab CI

```yaml
deploy:
  stage: deploy
  script:
    - gcloud auth activate-service-account --key-file=$GCP_SERVICE_KEY
    - gcloud builds submit --config=cloudbuild.yaml
  only:
    - main
```

### Pipeline GitHub Actions

```yaml
- name: Deploy to Cloud Run
  uses: google-github-actions/deploy-cloudrun@v1
  with:
    service: ${{ env.SERVICE_NAME }}
    image: ${{ env.IMAGE_URL }}
    region: ${{ env.REGION }}
```

### Hooks de Déploiement

```bash
# Pre-deploy hook
#!/bin/bash
echo "Validation pre-déploiement..."
terraform plan -detailed-exitcode

# Post-deploy hook
#!/bin/bash
echo "Tests post-déploiement..."
curl -f $SERVICE_URL/actuator/health
```

## 📚 Ressources Complémentaires

- [Documentation Cloud Run](https://cloud.google.com/run/docs)
- [Guide Cloud Build](https://cloud.google.com/build/docs)
- [Bonnes Pratiques Docker](https://docs.docker.com/develop/dev-best-practices/)
- [Spring Boot sur Cloud Run](https://cloud.google.com/run/docs/quickstarts/build-and-deploy/deploy-java-service) 