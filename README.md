# Infrastructure as Code - Centralisation de Données

Cette infrastructure Terraform déploie une architecture complète sur Google Cloud Platform pour un projet de centralisation de données avec une API Spring Boot sur Cloud Run et une base de données PostgreSQL sur Cloud SQL.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Cloud Run     │    │   Cloud SQL     │    │   Monitoring    │
│   (Spring Boot) │────│   (PostgreSQL)  │    │   & Alerting    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
         ┌─────────────────────────────────────────────────┐
         │              VPC Network                        │
         │  ┌─────────────┐  ┌─────────────┐  ┌──────────┐ │
         │  │  Services   │  │  Database   │  │   NAT    │ │
         │  │   Subnet    │  │   Subnet    │  │ Gateway  │ │
         │  └─────────────┘  └─────────────┘  └──────────┘ │
         └─────────────────────────────────────────────────┘
```

## 📁 Structure du Projet

```
terraform/
├── environments/           # Configurations par environnement
│   ├── dev/               # Environnement de développement
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   ├── outputs.tf
│   │   └── backend.conf
│   ├── staging/           # Environnement de staging
│   └── prod/              # Environnement de production
├── modules/               # Modules Terraform réutilisables
│   ├── networking/        # VPC, sous-réseaux, firewall
│   ├── cloud-sql/         # Base de données PostgreSQL
│   ├── cloud-run/         # Service Cloud Run
│   ├── iam/              # Service Accounts et permissions
│   └── monitoring/        # Dashboards et alertes
└── shared/
    └── backend.tf         # Configuration backend partagée
```

## 🚀 Démarrage Rapide

### Prérequis

1. **Google Cloud SDK** installé et configuré
2. **Terraform** >= 1.5 installé
3. **Projet GCP** créé avec facturation activée
4. **Bucket GCS** pour le state Terraform

### Configuration Initiale

#### Option 1: Script Automatique (Recommandé)

1. **Exécuter le script de configuration**
```bash
# Pour le développement
./scripts/setup-environment.sh dev

# Pour le staging
./scripts/setup-environment.sh staging

# Pour la production
./scripts/setup-environment.sh prod
```

Le script va automatiquement :
- Copier le fichier d'exemple `terraform.tfvars.example` vers `terraform.tfvars`
- Vous guider pour modifier les valeurs obligatoires
- Créer le bucket GCS pour le state Terraform
- Initialiser Terraform

#### Option 2: Configuration Manuelle

1. **Cloner le repository**
```bash
git clone <repository-url>
cd terraform
```

2. **Configurer les variables pour votre environnement**
```bash
# Copier le fichier d'exemple
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
```

3. **Modifier les valeurs dans `terraform.tfvars`**
```hcl
# Configuration obligatoire
project_id      = "votre-project-id-dev"
alert_email     = "votre-email@entreprise.com"

# Configuration optionnelle
slack_webhook_url = "https://hooks.slack.com/services/..."
authorized_networks = [
  {
    name  = "office"
    value = "203.0.113.0/24"  # Votre IP office
  }
]
```

4. **Créer le bucket pour le state**
```bash
PROJECT_ID="votre-project-id-dev"
gsutil mb -p $PROJECT_ID gs://terraform-state-dev-data-centralization
gsutil versioning set on gs://terraform-state-dev-data-centralization
```

5. **Initialiser Terraform**
```bash
terraform init -backend-config=backend.conf
```

### Déploiement

Une fois la configuration terminée, vous pouvez déployer l'infrastructure :

#### Via Makefile (Recommandé)
```bash
# Planifier les changements
make plan ENV=dev

# Déployer l'infrastructure complète
make apply ENV=dev

# Ou déploiement par étapes
make deploy-base ENV=dev      # Infrastructure de base
make deploy-database ENV=dev  # Base de données
make deploy-app ENV=dev      # Application Cloud Run
make deploy-monitoring ENV=dev # Monitoring
```

#### Via Terraform Direct
```bash
cd terraform/environments/dev

# Planifier le déploiement
terraform plan -var-file=terraform.tfvars

# Appliquer les changements
terraform apply -var-file=terraform.tfvars
```

#### Vérification Post-Déploiement
```bash
# Vérifier les outputs
make output ENV=dev

# Tester l'application
make test-health ENV=dev

# Voir les logs
make logs ENV=dev
```

## 🔧 Configuration des Modules

### Module Networking
- **VPC** avec sous-réseaux privés
- **Cloud NAT** pour les sorties internet
- **Firewall rules** restrictives
- **Private Service Connect** pour Cloud SQL

### Module Cloud SQL
- **PostgreSQL 14** avec haute disponibilité
- **Backups automatiques** avec rétention configurable
- **Point-in-time recovery** activé
- **Réplicas de lecture** pour la production
- **Monitoring** et insights activés

### Module Cloud Run
- **Autoscaling** configuré par environnement
- **Variables d'environnement** sécurisées
- **Health checks** personnalisés
- **Connexion sécurisée** à Cloud SQL
- **VPC Connector** pour le réseau privé

### Module IAM
- **Service Accounts** avec permissions minimales
- **Workload Identity** pour l'authentification
- **Séparation des rôles** par service

### Module Monitoring
- **Dashboards** Cloud Monitoring
- **Alertes** sur métriques critiques
- **Uptime checks** sur les endpoints
- **Log sinks** vers BigQuery
- **Notifications** Slack/Email

## 🌍 Gestion Multi-Environnements

### Environnement Dev (`dev`)
- **Ressources minimales** pour économiser
- **Instances** : db-custom-1-2048, 0-5 instances Cloud Run
- **Deletion protection** désactivée
- **Logs** non archivés longue durée
- **Budget** : 100€/mois
- **HA Cloud SQL** : Désactivée
- **Réplicas lecture** : 0

### Environnement Staging (`staging`)
- **Configuration intermédiaire**
- **Instances** : db-custom-2-4096, 1-10 instances Cloud Run
- **Deletion protection** activée
- **Logs** archivés 30 jours
- **Tests de charge** possibles
- **Budget** : 250€/mois
- **HA Cloud SQL** : Activée
- **Réplicas lecture** : 1

### Environnement Production (`prod`)
- **Haute disponibilité** obligatoire
- **Instances** : db-custom-4-8192, 2-100 instances Cloud Run
- **Réplicas de lecture** Cloud SQL (x2)
- **CPU always allocated** Cloud Run
- **Monitoring renforcé** avec SMS
- **Backups cross-region** (30 jours)
- **Deletion protection** obligatoire
- **SSL strict mode** activé
- **Audit logs** complets (90 jours)
- **Budget** : 500€/mois
- **Sécurité renforcée** : pgAudit, KMS

#### Spécificités Production
```hcl
# Configuration critique production
high_availability          = true
read_replica_count         = 2
backup_cross_region        = true
deletion_protection        = true
require_ssl               = true
ssl_mode                  = "ENCRYPTED_ONLY"
enable_pgaudit            = true
log_statement             = "all"
cloud_run_min_instances   = 2
cloud_run_cpu_throttling  = false
enable_audit_logs         = true
log_retention_days        = 90
```

## 📊 Variables d'Environnement

### Variables Obligatoires
```hcl
project_id      = "ID du projet GCP"
project_name    = "Nom du projet"
billing_account = "ID du compte de facturation"
```

### Variables de Configuration
```hcl
# Réseau
services_subnet_cidr = "10.1.0.0/24"
database_subnet_cidr = "10.2.0.0/24"

# Cloud SQL
db_tier = "db-f1-micro"  # dev
db_tier = "db-n1-standard-2"  # prod

# Cloud Run
min_instances = 0  # dev
min_instances = 1  # prod
max_instances = 5  # dev
max_instances = 100  # prod

# Monitoring
notification_emails = ["team@entreprise.com"]
slack_webhook_url = "https://hooks.slack.com/..."
```

## 🔐 Sécurité

### Bonnes Pratiques Implémentées
- **Réseau privé** uniquement
- **Secrets** dans Secret Manager
- **Service Accounts** dédiés
- **Firewall rules** restrictives
- **Audit logs** activés
- **Encryption at rest** par défaut

### Permissions IAM
```
Cloud Run Service Account:
- secretmanager.secretAccessor
- cloudsql.client
- logging.logWriter
- monitoring.metricWriter

Cloud Build Service Account:
- storage.admin
- run.admin
- secretmanager.secretAccessor
- iam.serviceAccountUser
```

## 📈 Monitoring et Alertes

### Métriques Surveillées
- **Latence** des requêtes (P95)
- **Taux d'erreur** (4xx/5xx)
- **Utilisation CPU/Mémoire**
- **Connexions** Cloud SQL
- **Disponibilité** du service

### Seuils d'Alerte (Production)
```
Latence: > 2000ms
Erreurs: > 5/min
CPU: > 80%
Mémoire: > 80%
Connexions SQL: > 80
```

## 🚀 CI/CD avec Cloud Build

### Pipeline de Déploiement
1. **Build** de l'image Docker
2. **Push** vers Artifact Registry
3. **Deploy** sur Cloud Run
4. **Tests** post-déploiement
5. **Rollback** automatique si échec

### Configuration Cloud Build
```yaml
steps:
- name: 'gcr.io/cloud-builders/docker'
  args: ['build', '-t', '${_IMAGE_URL}', '.']
- name: 'gcr.io/cloud-builders/docker'
  args: ['push', '${_IMAGE_URL}']
- name: 'gcr.io/cloud-builders/gcloud'
  args: ['run', 'deploy', '${_SERVICE_NAME}', 
         '--image', '${_IMAGE_URL}',
         '--region', '${_REGION}']
```

## 🔄 Commandes Utiles

### Terraform
```bash
# Initialisation avec backend spécifique
terraform init -backend-config=environments/dev/backend.conf

# Plan avec variables d'environnement
terraform plan -var-file=environments/dev/terraform.tfvars

# Apply avec auto-approve (CI/CD)
terraform apply -auto-approve -var-file=environments/prod/terraform.tfvars

# Détruire des ressources spécifiques
terraform destroy -target=module.monitoring

# Importer une ressource existante
terraform import module.cloud_sql.google_sql_database_instance.main projects/PROJECT/instances/INSTANCE

# Voir les outputs
terraform output
```

### GCloud
```bash
# Se connecter à Cloud SQL
gcloud sql connect INSTANCE_NAME --user=postgres

# Voir les logs Cloud Run
gcloud logging read "resource.type=cloud_run_revision"

# Déployer une nouvelle version
gcloud run deploy SERVICE_NAME --image=IMAGE_URL --region=REGION
```

## 🐛 Dépannage

### Problèmes Courants

1. **Erreur de permissions**
```bash
# Vérifier les permissions du service account
gcloud projects get-iam-policy PROJECT_ID
```

2. **Problème de réseau**
```bash
# Vérifier la connectivité VPC
gcloud compute networks describe VPC_NAME
```

3. **Erreur Cloud SQL**
```bash
# Vérifier les logs Cloud SQL
gcloud logging read "resource.type=cloudsql_database"
```

### Logs Utiles
```bash
# Logs Cloud Run
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=SERVICE_NAME"

# Logs Cloud SQL
gcloud logging read "resource.type=cloudsql_database"

# Logs VPC
gcloud logging read "resource.type=gce_subnetwork"
```

## 📚 Documentation Supplémentaire

- [Guide de déploiement Cloud Run](docs/cloud-run-deployment.md)
- [Configuration Cloud SQL](docs/cloud-sql-setup.md)
- [Monitoring et alertes](docs/monitoring-setup.md)
- [Sécurité et bonnes pratiques](docs/security-guidelines.md)

## 🤝 Contribution

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/AmazingFeature`)
3. Commit les changements (`git commit -m 'Add AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 📞 Support

Pour toute question ou problème :
- 📧 Email: contact@nexagone.fr