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

## 3. Configuration du projet

```bash
# Lister les projets
gcloud projects list

# Définir le projet par défaut
gcloud config set project VOTRE_PROJECT_ID

# Vérifier la configuration
gcloud config list
```

## 4. Gestion des comptes de facturation

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

## 5. Configuration Terraform

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

## 6. Vérification finale

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