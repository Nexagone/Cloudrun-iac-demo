# Configuration des Environnements Terraform

Ce répertoire contient la configuration Terraform pour les différents environnements de l'application de centralisation de données.

## Structure

```
environments/
├── dev/
│   ├── main.tf
│   ├── variables.tf
│   └── terraform.tfvars
├── staging/
│   ├── main.tf
│   ├── variables.tf
│   └── terraform.tfvars
└── prod/
    ├── main.tf
    ├── variables.tf
    └── terraform.tfvars
```

## Configuration des Variables

### Variables Communes

Pour chaque environnement, vous devez configurer les variables suivantes dans le fichier `terraform.tfvars` :

1. Configuration du Projet :
   ```hcl
   project_id      = "votre-projet-id"
   project_name    = "data-centralization"
   billing_account = "VOTRE-COMPTE-FACTURATION"
   ```

2. Configuration Docker :
   ```hcl
   docker_registry = {
     server   = "registry.example.com"
     username = "votre-username"
     password = "votre-password"
   }
   docker_image_url = "registry.example.com/votre-app:tag"
   ```

### Spécificités par Environnement

#### Développement (dev)
- Configuration minimale
- Pas de haute disponibilité
- Budget limité
- Monitoring moins strict

#### Staging
- Configuration intermédiaire
- Haute disponibilité optionnelle
- Monitoring plus strict
- Budget modéré

#### Production
- Configuration complète
- Haute disponibilité activée
- Réplicas de lecture
- Monitoring strict
- Budget plus élevé

## Variables d'Environnement Spring Boot

Les variables d'environnement suivantes sont automatiquement configurées pour l'application Spring Boot :

```hcl
SPRING_DATASOURCE_HOST     = "localhost"  # Cloud SQL est monté localement
SPRING_DATASOURCE_PORT     = "5432"
SPRING_DATASOURCE_DB       = var.database_name
SPRING_DATASOURCE_USERNAME = var.database_user
SPRING_DATASOURCE_PASSWORD = [Géré via Secret Manager]
```

## Utilisation

1. Naviguez dans le répertoire de l'environnement souhaité :
   ```bash
   cd environments/[dev|staging|prod]
   ```

2. Initialisez Terraform :
   ```bash
   terraform init -backend-config=backend.conf
   ```

3. Vérifiez le plan :
   ```bash
   terraform plan
   ```

4. Appliquez la configuration :
   ```bash
   terraform apply
   ```

## Notes Importantes

1. Les secrets (mots de passe, credentials) sont gérés via Google Secret Manager
2. La base de données est accessible uniquement via le réseau privé
3. Les backups sont activés par défaut dans tous les environnements
4. Le monitoring est configuré avec des seuils adaptés à chaque environnement
5. Les variables d'environnement Spring Boot sont automatiquement configurées

## 📁 Structure des Environnements

```
environments/
├── dev/                    # Environnement de développement
│   ├── main.tf            # Configuration principale
│   ├── variables.tf       # Définition des variables
│   ├── terraform.tfvars.example  # 📝 Modèle de configuration
│   ├── terraform.tfvars   # 🔒 Configuration réelle (généré)
│   ├── outputs.tf         # Outputs de l'environnement
│   └── backend.conf       # Configuration backend GCS
├── staging/                # Environnement de staging
└── prod/                   # Environnement de production
```

## 🚀 Démarrage Rapide

### Option 1: Script Automatisé (Recommandé)

```bash
# Depuis la racine du projet
./scripts/setup-environment.sh dev
```

Ce script va automatiquement :
1. Copier `terraform.tfvars.example` vers `terraform.tfvars`
2. Vous guider pour la configuration
3. Créer le bucket GCS pour le state
4. Initialiser Terraform

### Option 2: Configuration Manuelle

```bash
# Choisir votre environnement
cd dev  # ou staging / prod

# Copier le fichier d'exemple
cp terraform.tfvars.example terraform.tfvars

# Modifier les valeurs (voir section Variables)
nano terraform.tfvars

# Créer le bucket pour le state Terraform
PROJECT_ID="votre-project-id"
gsutil mb -p $PROJECT_ID gs://terraform-state-dev-data-centralization

# Initialiser Terraform
terraform init -backend-config=backend.conf
```

## 📊 Variables de Configuration

### Variables Obligatoires

Ces variables **DOIVENT** être modifiées dans chaque environnement :

| Variable | Description | Exemple |
|----------|-------------|---------|
| `project_id` | ID du projet GCP | `"mon-projet-dev"` |
| `alert_email` | Email pour les alertes | `"team@entreprise.com"` |

### Variables par Environnement

#### Développement (`dev`)
- **Objectif** : Coûts minimisés, ressources légères
- **Particularités** :
  - Scale to zero (min_instances = 0)
  - Pas de haute disponibilité
  - Logs courts (7 jours)
  - Budget : 100€/mois

#### Staging (`staging`) 
- **Objectif** : Tests et validation
- **Particularités** :
  - Haute disponibilité activée
  - 1 réplica de lecture
  - Logs moyens (30 jours)
  - Budget : 250€/mois

#### Production (`prod`)
- **Objectif** : Performance et fiabilité maximales
- **Particularités** :
  - 2 instances minimum toujours actives
  - 2 réplicas de lecture
  - Sécurité maximale (SSL strict, audit)
  - Logs longs (90 jours)
  - Budget : 500€/mois

## 🔐 Sécurité des Configurations

### Fichiers Sensibles

⚠️ **IMPORTANT** : Ne commitez jamais ces fichiers :

```bash
# Fichiers exclus par .gitignore
terraform.tfvars          # Configuration réelle
*.tfstate                 # État Terraform
*.tfstate.backup          # Sauvegardes d'état
.terraform/               # Cache Terraform
```

### Bonnes Pratiques

1. **Utilisez toujours les fichiers `.example`** comme base
2. **Vérifiez les permissions** avant le déploiement
3. **Testez en dev** avant staging/prod
4. **Documentez les changements** critiques

## 🎯 Différences par Environnement

| Aspect | Dev | Staging | Prod |
|--------|-----|---------|------|
| **Cloud SQL** | 1 vCPU, 2GB | 2 vCPU, 4GB | 4 vCPU, 8GB |
| **HA Cloud SQL** | ❌ | ✅ | ✅ |
| **Cloud Run Min** | 0 | 1 | 2 |
| **Cloud Run Max** | 5 | 10 | 100 |
| **SSL Mode** | Flexible | Encrypted | Encrypted Only |
| **Audit Logs** | ❌ | ✅ | ✅ + pgAudit |
| **Backups** | 7 jours | 14 jours | 30 jours |
| **Monitoring** | Basic | Enhanced | Critical |

## 🔧 Commandes Utiles

### Makefile (depuis la racine)

```bash
# Initialiser un environnement
make init ENV=dev

# Planifier les changements
make plan ENV=dev

# Déployer
make apply ENV=dev

# Détruire (attention!)
make destroy ENV=dev
```

### Terraform Direct

```bash
cd environments/dev

# Plan
terraform plan -var-file=terraform.tfvars

# Apply
terraform apply -var-file=terraform.tfvars

# Outputs
terraform output

# Détruire une ressource spécifique
terraform destroy -target=module.monitoring
```

## 🐛 Dépannage

### Erreurs Communes

1. **Bucket état non trouvé**
   ```bash
   # Créer le bucket manquant
   gsutil mb gs://terraform-state-dev-data-centralization
   ```

2. **Permissions insuffisantes**
   ```bash
   # Vérifier l'authentification
   gcloud auth list
   gcloud config set project VOTRE-PROJECT-ID
   ```

3. **Variables non définies**
   ```bash
   # Vérifier le fichier tfvars
   grep "votre-project" terraform.tfvars
   ```

### Logs Utiles

```bash
# Logs Terraform
terraform apply -var-file=terraform.tfvars -auto-approve 2>&1 | tee deploy.log

# Logs Cloud Run
gcloud logging read "resource.type=cloud_run_revision"

# État du déploiement
terraform show
```

## 📚 Ressources

- [Documentation Terraform](https://terraform.io/docs)
- [Provider Google Cloud](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Guide Cloud Run](https://cloud.google.com/run/docs)
- [Guide Cloud SQL](https://cloud.google.com/sql/docs) 