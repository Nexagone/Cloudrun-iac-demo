# Guide GCP CLI et Terraform - Résumé

## 1. Installation gcloud CLI

### Ubuntu/Debian
```bash
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

### macOS
```bash
brew install --cask google-cloud-sdk
```

## 2. Authentification

```bash
# Connexion interactive
gcloud auth login

# Pour Terraform (Application Default Credentials)
gcloud auth application-default login
```

## 2.1 Nettoyage des credentials
````
gcloud auth revoke --all
gcloud config unset account
````

## 3. Configuration du projet

```bash
# Lister les projets
gcloud projects list

# Définir le projet par défaut
gcloud config set project VOTRE_PROJECT_ID

# Vérifier la configuration
gcloud config list
```

## 4. Gestion des rôles IAM

### Vérifier les rôles existants
```bash
# Lister tous les rôles d'un projet
gcloud projects get-iam-policy VOTRE_PROJECT_ID --format='table(bindings.role,bindings.members)'

# Format plus détaillé
gcloud projects get-iam-policy VOTRE_PROJECT_ID
```

### Ajouter des rôles
```bash
# Ajouter un rôle à un utilisateur
gcloud projects add-iam-policy-binding VOTRE_PROJECT_ID \
    --member="user:utilisateur@example.com" \
    --role="roles/serviceusage.serviceUsageAdmin"

# Rôles couramment nécessaires pour Terraform
# - roles/owner ou roles/editor (administration générale)
# - roles/serviceusage.serviceUsageAdmin (gestion des APIs)
# - roles/storage.admin (pour le backend GCS)
# - roles/compute.admin (pour les ressources Compute)
```

## 5. Gestion des comptes de facturation

### Consulter les comptes de facturation
```bash
# Lister tous les comptes
gcloud billing accounts list

# Voir le compte lié au projet
gcloud billing projects describe VOTRE_PROJECT_ID
```

### Via la Console GCP
- Menu hamburger → **Facturation**
- Voir tous les comptes et projets associés

### Lier un projet à un compte de facturation
```bash
gcloud billing projects link VOTRE_PROJECT_ID --billing-account=ACCOUNT_ID
```

## 6. Configuration Terraform

### Provider Google
```hcl
provider "google" {
  project = "votre-project-id"
  region  = "europe-west1"
}
```

### Référencer un compte de facturation
```hcl
data "google_billing_account" "account" {
  display_name = "Mon Compte de Facturation"
  open         = true
}
```

## 7. Gestion des ressources avec Terraform

### Commandes de base
```bash
# Initialiser le projet
terraform init

# Vérifier la configuration
terraform fmt
terraform validate

# Planifier les changements
terraform plan -var-file=terraform.tfvars

# Appliquer les changements
terraform apply -var-file=terraform.tfvars

# Détruire les ressources
terraform destroy -var-file=terraform.tfvars
```

### Bonnes pratiques
- Toujours utiliser des fichiers `.tfvars` pour les variables d'environnement
- Vérifier le plan avant d'appliquer les changements
- Utiliser des workspaces pour gérer plusieurs environnements
- Activer le versioning sur le bucket de stockage du state
- Utiliser des modules pour réutiliser le code

## 8. Vérification finale

```bash
# Tester la connexion
gcloud auth list
gcloud config get-value project

# Puis utiliser Terraform
terraform init
terraform plan
terraform apply
```

## ⚠️ Points importants

- Les **Application Default Credentials** sont nécessaires pour Terraform
- Un **compte de facturation actif** est requis pour la plupart des ressources GCP
- Vérifiez toujours votre configuration avant d'exécuter Terraform