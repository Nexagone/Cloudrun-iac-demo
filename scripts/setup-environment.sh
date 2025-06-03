#!/bin/bash
# Script de configuration d'environnement
# Usage: ./scripts/setup-environment.sh [dev|staging|prod]

set -euo pipefail

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
ENVIRONMENT=${1:-}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Fonction d'aide
show_help() {
    cat << EOF
🚀 Script de Configuration d'Environnement

Usage: $0 [ENVIRONMENT]

ENVIRONMENT:
    dev      - Environnement de développement
    staging  - Environnement de staging/test
    prod     - Environnement de production

Exemples:
    $0 dev      # Configure l'environnement dev
    $0 staging  # Configure l'environnement staging
    $0 prod     # Configure l'environnement prod

Ce script va:
1. Copier le fichier terraform.tfvars.example vers terraform.tfvars
2. Vous guider pour modifier les valeurs nécessaires
3. Créer le bucket GCS pour le state Terraform
4. Initialiser Terraform

EOF
}

# Validation des arguments
if [[ -z "$ENVIRONMENT" ]]; then
    echo -e "${RED}❌ Erreur: Environnement requis${NC}"
    show_help
    exit 1
fi

if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo -e "${RED}❌ Erreur: Environnement invalide '$ENVIRONMENT'${NC}"
    echo -e "${YELLOW}   Environnements valides: dev, staging, prod${NC}"
    exit 1
fi

echo -e "${BLUE}🚀 Configuration de l'environnement ${ENVIRONMENT}${NC}"
echo ""

# Répertoire de l'environnement
ENV_DIR="$PROJECT_ROOT/terraform/environments/$ENVIRONMENT"

if [[ ! -d "$ENV_DIR" ]]; then
    echo -e "${RED}❌ Erreur: Répertoire $ENV_DIR non trouvé${NC}"
    exit 1
fi

cd "$ENV_DIR"

# Étape 1: Copier le fichier de configuration
echo -e "${YELLOW}📋 Étape 1: Configuration des variables Terraform${NC}"

if [[ -f "terraform.tfvars" ]]; then
    echo -e "${YELLOW}⚠️  Le fichier terraform.tfvars existe déjà${NC}"
    read -p "Voulez-vous le remplacer? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}ℹ️  Conservation du fichier existant${NC}"
    else
        cp terraform.tfvars.example terraform.tfvars
        echo -e "${GREEN}✅ Fichier terraform.tfvars mis à jour${NC}"
    fi
else
    cp terraform.tfvars.example terraform.tfvars
    echo -e "${GREEN}✅ Fichier terraform.tfvars créé${NC}"
fi

# Étape 2: Guide de configuration
echo ""
echo -e "${YELLOW}📝 Étape 2: Personnalisation des variables${NC}"
echo ""
echo -e "${BLUE}Vous devez maintenant modifier le fichier terraform.tfvars${NC}"
echo -e "${BLUE}Variables OBLIGATOIRES à modifier:${NC}"
echo ""

case $ENVIRONMENT in
    dev)
        echo -e "  ${GREEN}project_id${NC}    = \"votre-project-id-dev\""
        echo -e "  ${GREEN}alert_email${NC}   = \"dev-team@votre-entreprise.com\""
        ;;
    staging)
        echo -e "  ${GREEN}project_id${NC}    = \"votre-project-id-staging\""
        echo -e "  ${GREEN}alert_email${NC}   = \"staging-team@votre-entreprise.com\""
        echo -e "  ${GREEN}slack_webhook_url${NC} = \"https://hooks.slack.com/...\""
        ;;
    prod)
        echo -e "  ${RED}project_id${NC}    = \"votre-project-id-production\""
        echo -e "  ${RED}alert_email${NC}   = \"ops-team@votre-entreprise.com\""
        echo -e "  ${RED}slack_webhook_url${NC} = \"https://hooks.slack.com/...\""
        echo -e "  ${RED}sms_number${NC}    = \"+33123456789\""
        echo -e "  ${RED}authorized_networks${NC} = [...vos IPs...]"
        ;;
esac

echo ""
read -p "Voulez-vous ouvrir le fichier maintenant? [Y/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    if command -v code >/dev/null 2>&1; then
        code terraform.tfvars
    elif command -v nano >/dev/null 2>&1; then
        nano terraform.tfvars
    elif command -v vim >/dev/null 2>&1; then
        vim terraform.tfvars
    else
        echo -e "${YELLOW}⚠️  Aucun éditeur trouvé. Modifiez manuellement:${NC}"
        echo -e "${BLUE}   $ENV_DIR/terraform.tfvars${NC}"
    fi
fi

# Attendre la confirmation
echo ""
echo -e "${YELLOW}⏸️  Modifiez le fichier terraform.tfvars puis appuyez sur Entrée pour continuer...${NC}"
read

# Étape 3: Validation de la configuration
echo -e "${YELLOW}🔍 Étape 3: Validation de la configuration${NC}"

# Vérifier project_id
PROJECT_ID=$(grep '^project_id' terraform.tfvars | cut -d'"' -f2)
if [[ "$PROJECT_ID" == "votre-project-id-"* ]]; then
    echo -e "${RED}❌ project_id non configuré${NC}"
    exit 1
fi

# Vérifier alert_email
ALERT_EMAIL=$(grep '^alert_email' terraform.tfvars | cut -d'"' -f2)
if [[ "$ALERT_EMAIL" == *"@example.com" ]]; then
    echo -e "${RED}❌ alert_email non configuré${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Configuration validée${NC}"
echo -e "${BLUE}   Project ID: $PROJECT_ID${NC}"
echo -e "${BLUE}   Alert Email: $ALERT_EMAIL${NC}"

# Étape 4: Création du bucket GCS
echo ""
echo -e "${YELLOW}🪣 Étape 4: Création du bucket GCS pour le state Terraform${NC}"

BUCKET_NAME="terraform-state-${ENVIRONMENT}-data-centralization"

# Vérifier si le bucket existe
if gsutil ls -b "gs://${BUCKET_NAME}" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Bucket gs://${BUCKET_NAME} existe déjà${NC}"
else
    echo -e "${BLUE}📦 Création du bucket gs://${BUCKET_NAME}${NC}"
    
    # Créer le bucket
    gsutil mb -p "$PROJECT_ID" -c STANDARD -l europe-west1 "gs://${BUCKET_NAME}"
    
    # Activer le versioning
    gsutil versioning set on "gs://${BUCKET_NAME}"
    
    # Configuration de sécurité pour prod
    if [[ "$ENVIRONMENT" == "prod" ]]; then
        gsutil lifecycle set - "gs://${BUCKET_NAME}" << EOF
{
  "rule": [
    {
      "action": {"type": "Delete"},
      "condition": {
        "age": 365,
        "isLive": false
      }
    }
  ]
}
EOF
    fi
    
    echo -e "${GREEN}✅ Bucket créé et configuré${NC}"
fi

# Étape 5: Initialisation Terraform
echo ""
echo -e "${YELLOW}🔧 Étape 5: Initialisation Terraform${NC}"

if terraform init -backend-config=backend.conf; then
    echo -e "${GREEN}✅ Terraform initialisé avec succès${NC}"
else
    echo -e "${RED}❌ Erreur lors de l'initialisation Terraform${NC}"
    exit 1
fi

# Étape 6: Validation Terraform
echo ""
echo -e "${YELLOW}✅ Étape 6: Validation de la configuration Terraform${NC}"

if terraform validate; then
    echo -e "${GREEN}✅ Configuration Terraform valide${NC}"
else
    echo -e "${RED}❌ Configuration Terraform invalide${NC}"
    exit 1
fi

# Résumé final
echo ""
echo -e "${GREEN}🎉 Configuration terminée avec succès!${NC}"
echo ""
echo -e "${BLUE}Prochaines étapes:${NC}"
echo -e "  1. ${YELLOW}Planifier:${NC} terraform plan -var-file=terraform.tfvars"
echo -e "  2. ${YELLOW}Déployer:${NC} terraform apply -var-file=terraform.tfvars"
echo ""
echo -e "${BLUE}Ou utilisez le Makefile:${NC}"
echo -e "  ${YELLOW}make plan ENV=$ENVIRONMENT${NC}"
echo -e "  ${YELLOW}make apply ENV=$ENVIRONMENT${NC}"
echo ""

if [[ "$ENVIRONMENT" == "prod" ]]; then
    echo -e "${RED}⚠️  ATTENTION PRODUCTION:${NC}"
    echo -e "${RED}   - Vérifiez TOUTES les configurations${NC}"
    echo -e "${RED}   - Testez d'abord en staging${NC}"
    echo -e "${RED}   - Planifiez la fenêtre de maintenance${NC}"
    echo ""
fi

echo -e "${GREEN}Configuration de l'environnement $ENVIRONMENT terminée! 🚀${NC}" 