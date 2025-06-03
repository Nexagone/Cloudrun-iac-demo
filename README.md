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

1. **Cloner le repository**
```bash
git clone <repository-url>
cd terraform
```

2. **Configurer les variables**
```bash
# Copier et modifier le fichier tfvars
cp environments/dev/terraform.tfvars.example environments/dev/terraform.tfvars
```

3. **Modifier les valeurs dans `terraform.tfvars`**
```hcl
project_id      = "votre-project-id-dev"
project_name    = "data-centralization"
billing_account = "VOTRE-BILLING-ACCOUNT-ID"

notification_emails = [
  "votre-email@entreprise.com"
]
```

4. **Créer le bucket pour le state**
```bash
gsutil mb gs://terraform-state-votre-project-id-dev
gsutil versioning set on gs://terraform-state-votre-project-id-dev
```

### Déploiement

1. **Initialiser Terraform**
```bash
cd environments/dev
terraform init -backend-config=backend.conf
```

2. **Planifier le déploiement**
```bash
terraform plan -var-file=terraform.tfvars
```

3. **Appliquer les changements**
```bash
terraform apply -var-file=terraform.tfvars
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

### Environnement Dev
- **Ressources minimales** pour économiser
- **Deletion protection** désactivée
- **Logs** non archivés
- **Budget** : 100€/mois

### Environnement Staging
- **Configuration intermédiaire**
- **Deletion protection** activée
- **Logs** archivés
- **Tests de charge** possibles

### Environnement Production
- **Haute disponibilité** activée
- **Réplicas de lecture** Cloud SQL
- **CPU always allocated** Cloud Run
- **Monitoring renforcé**
- **Backups cross-region**

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