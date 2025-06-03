#!/bin/bash

# Script de setup automatique pour l'infrastructure Terraform
# Usage: ./scripts/setup.sh [dev|staging|prod]

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
ENVIRONMENT=${1:-dev}
PROJECT_NAME="data-centralization"
REGION="europe-west1"

# Fonctions utilitaires
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Vérification des prérequis
check_prerequisites() {
    log_step "Vérification des prérequis..."
    
    # Vérifier gcloud
    if ! command -v gcloud &> /dev/null; then
        log_error "gcloud CLI n'est pas installé. Veuillez l'installer : https://cloud.google.com/sdk/docs/install"
        exit 1
    fi
    
    # Vérifier terraform
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform n'est pas installé. Veuillez l'installer : https://terraform.io/downloads"
        exit 1
    fi
    
    # Vérifier la version de Terraform
    TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
    if [[ $(echo "$TERRAFORM_VERSION 1.5.0" | tr " " "\n" | sort -V | head -n1) != "1.5.0" ]]; then
        log_error "Terraform version >= 1.5.0 requis. Version actuelle: $TERRAFORM_VERSION"
        exit 1
    fi
    
    # Vérifier l'authentification gcloud
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1 &> /dev/null; then
        log_error "Vous n'êtes pas authentifié avec gcloud. Exécutez: gcloud auth login"
        exit 1
    fi
    
    log_info "Tous les prérequis sont satisfaits ✅"
}

# Configuration du projet GCP
setup_gcp_project() {
    log_step "Configuration du projet GCP..."
    
    # Demander l'ID du projet
    read -p "Entrez l'ID du projet GCP: " PROJECT_ID
    if [[ -z "$PROJECT_ID" ]]; then
        log_error "L'ID du projet est requis"
        exit 1
    fi
    
    # Définir le projet par défaut
    gcloud config set project "$PROJECT_ID"
    
    # Demander l'ID du compte de facturation
    read -p "Entrez l'ID du compte de facturation: " BILLING_ACCOUNT
    if [[ -z "$BILLING_ACCOUNT" ]]; then
        log_error "L'ID du compte de facturation est requis"
        exit 1
    fi
    
    # Activer la facturation
    gcloud beta billing projects link "$PROJECT_ID" --billing-account="$BILLING_ACCOUNT"
    
    log_info "Projet GCP configuré: $PROJECT_ID"
}

# Activation des APIs
enable_apis() {
    log_step "Activation des APIs GCP..."
    
    APIS=(
        "run.googleapis.com"
        "sql-component.googleapis.com"
        "sqladmin.googleapis.com"
        "secretmanager.googleapis.com"
        "compute.googleapis.com"
        "servicenetworking.googleapis.com"
        "logging.googleapis.com"
        "monitoring.googleapis.com"
        "bigquery.googleapis.com"
        "cloudbuild.googleapis.com"
        "artifactregistry.googleapis.com"
        "vpcaccess.googleapis.com"
        "cloudresourcemanager.googleapis.com"
        "iam.googleapis.com"
    )
    
    for api in "${APIS[@]}"; do
        log_info "Activation de $api..."
        gcloud services enable "$api"
    done
    
    log_info "Toutes les APIs ont été activées ✅"
}

# Création du bucket pour le state Terraform
create_terraform_bucket() {
    log_step "Création du bucket pour le state Terraform..."
    
    BUCKET_NAME="terraform-state-${PROJECT_ID}-${ENVIRONMENT}"
    
    # Vérifier si le bucket existe déjà
    if gsutil ls -b "gs://$BUCKET_NAME" &> /dev/null; then
        log_warn "Le bucket $BUCKET_NAME existe déjà"
    else
        # Créer le bucket
        gsutil mb -p "$PROJECT_ID" -c STANDARD -l "$REGION" "gs://$BUCKET_NAME"
        
        # Activer le versioning
        gsutil versioning set on "gs://$BUCKET_NAME"
        
        # Configurer la politique de rétention
        gsutil lifecycle set - "gs://$BUCKET_NAME" <<EOF
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "Delete"},
        "condition": {
          "age": 90,
          "isLive": false
        }
      }
    ]
  }
}
EOF
        
        log_info "Bucket créé: gs://$BUCKET_NAME ✅"
    fi
}

# Configuration des fichiers Terraform
setup_terraform_files() {
    log_step "Configuration des fichiers Terraform..."
    
    ENV_DIR="terraform/environments/$ENVIRONMENT"
    
    # Créer le fichier backend.conf
    cat > "$ENV_DIR/backend.conf" <<EOF
bucket = "terraform-state-${PROJECT_ID}-${ENVIRONMENT}"
prefix = "terraform/state/${ENVIRONMENT}"
EOF
    
    # Créer le fichier terraform.tfvars s'il n'existe pas
    if [[ ! -f "$ENV_DIR/terraform.tfvars" ]]; then
        # Demander l'email pour les notifications
        read -p "Entrez votre email pour les notifications: " NOTIFICATION_EMAIL
        
        cat > "$ENV_DIR/terraform.tfvars" <<EOF
# Configuration du projet
project_id      = "$PROJECT_ID"
project_name    = "$PROJECT_NAME"
billing_account = "$BILLING_ACCOUNT"

# Labels
team        = "platform"
cost_center = "engineering"

# Configuration notification
notification_emails = [
  "$NOTIFICATION_EMAIL"
]

# Variables d'environnement pour l'application
environment_variables = {
  "EXTERNAL_API_URL"   = "https://api.$ENVIRONMENT.exemple.com"
  "SHEETS_API_ENABLED" = "true"
  "LOG_LEVEL"         = "INFO"
}

# Configuration spécifique $ENVIRONMENT
enable_log_sink = $([ "$ENVIRONMENT" = "prod" ] && echo "true" || echo "false")
budget_amount   = $([ "$ENVIRONMENT" = "prod" ] && echo "500" || echo "100")
EOF
        
        log_info "Fichier terraform.tfvars créé ✅"
    else
        log_warn "Le fichier terraform.tfvars existe déjà"
    fi
}

# Initialisation de Terraform
init_terraform() {
    log_step "Initialisation de Terraform..."
    
    cd "terraform/environments/$ENVIRONMENT"
    
    # Initialiser Terraform
    terraform init -backend-config=backend.conf
    
    # Valider la configuration
    terraform validate
    
    log_info "Terraform initialisé ✅"
    
    cd - > /dev/null
}

# Planification
plan_terraform() {
    log_step "Planification des changements..."
    
    cd "terraform/environments/$ENVIRONMENT"
    
    terraform plan -var-file=terraform.tfvars -out=tfplan
    
    log_info "Plan créé: tfplan ✅"
    
    cd - > /dev/null
}

# Application (optionnelle)
apply_terraform() {
    log_step "Application des changements..."
    
    read -p "Voulez-vous appliquer les changements maintenant? [y/N] " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd "terraform/environments/$ENVIRONMENT"
        
        terraform apply tfplan
        
        log_info "Infrastructure déployée ✅"
        
        # Afficher les outputs importants
        echo ""
        log_info "=== OUTPUTS IMPORTANTS ==="
        terraform output cloud_run_url
        terraform output dashboard_url
        terraform output artifact_registry_repo
        
        cd - > /dev/null
    else
        log_info "Application annulée. Vous pouvez l'exécuter plus tard avec:"
        log_info "cd terraform/environments/$ENVIRONMENT && terraform apply tfplan"
    fi
}

# Fonction principale
main() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    Setup Infrastructure                      ║"
    echo "║                  Centralisation de Données                  ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    log_info "Environnement: $ENVIRONMENT"
    log_info "Région: $REGION"
    echo ""
    
    # Vérifier l'environnement
    if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
        log_error "Environnement invalide. Utilisez: dev, staging ou prod"
        exit 1
    fi
    
    # Exécuter les étapes
    check_prerequisites
    setup_gcp_project
    enable_apis
    create_terraform_bucket
    setup_terraform_files
    init_terraform
    plan_terraform
    apply_terraform
    
    echo ""
    log_info "🎉 Setup terminé avec succès!"
    log_info "📚 Consultez le README.md pour plus d'informations"
    log_info "🔧 Utilisez le Makefile pour les opérations courantes"
}

# Exécuter le script principal
main "$@" 