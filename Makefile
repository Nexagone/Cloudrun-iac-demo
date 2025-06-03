# Makefile pour l'infrastructure Terraform
.PHONY: help init plan apply destroy clean format validate

# Variables par défaut
ENV ?= dev
REGION ?= europe-west1

# Couleurs pour l'affichage
RED=\033[0;31m
GREEN=\033[0;32m
YELLOW=\033[1;33m
NC=\033[0m # No Color

help: ## Affiche cette aide
	@echo "Infrastructure Terraform - Centralisation de Données"
	@echo ""
	@echo "Usage: make [target] ENV=[dev|staging|prod]"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

init: ## Initialise Terraform pour l'environnement spécifié
	@echo "${GREEN}🚀 Initialisation de Terraform pour l'environnement $(ENV)${NC}"
	cd terraform/environments/$(ENV) && \
	terraform init -backend-config=backend.conf

plan: ## Planifie les changements Terraform
	@echo "${YELLOW}📋 Planification des changements pour l'environnement $(ENV)${NC}"
	cd terraform/environments/$(ENV) && \
	terraform plan -var-file=terraform.tfvars

apply: ## Applique les changements Terraform
	@echo "${GREEN}🔧 Application des changements pour l'environnement $(ENV)${NC}"
	cd terraform/environments/$(ENV) && \
	terraform apply -var-file=terraform.tfvars

apply-auto: ## Applique les changements automatiquement (pour CI/CD)
	@echo "${GREEN}🤖 Application automatique pour l'environnement $(ENV)${NC}"
	cd terraform/environments/$(ENV) && \
	terraform apply -auto-approve -var-file=terraform.tfvars

destroy: ## Détruit l'infrastructure
	@echo "${RED}💥 Destruction de l'infrastructure pour l'environnement $(ENV)${NC}"
	@echo "${RED}⚠️  ATTENTION: Cette action est irréversible!${NC}"
	@read -p "Êtes-vous sûr? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		cd terraform/environments/$(ENV) && \
		terraform destroy -var-file=terraform.tfvars; \
	fi

output: ## Affiche les outputs Terraform
	@echo "${GREEN}📤 Outputs pour l'environnement $(ENV)${NC}"
	cd terraform/environments/$(ENV) && \
	terraform output

format: ## Formate le code Terraform
	@echo "${GREEN}🎨 Formatage du code Terraform${NC}"
	terraform fmt -recursive terraform/

validate: ## Valide la configuration Terraform
	@echo "${GREEN}✅ Validation de la configuration Terraform${NC}"
	cd terraform/environments/$(ENV) && \
	terraform validate

clean: ## Nettoie les fichiers temporaires
	@echo "${GREEN}🧹 Nettoyage des fichiers temporaires${NC}"
	find terraform/ -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	find terraform/ -name "*.tfstate*" -type f -delete 2>/dev/null || true
	find terraform/ -name ".terraform.lock.hcl" -type f -delete 2>/dev/null || true

# Commandes spécifiques aux modules
plan-networking: ## Planifie uniquement le module networking
	cd terraform/environments/$(ENV) && \
	terraform plan -target=module.networking -var-file=terraform.tfvars

plan-cloud-sql: ## Planifie uniquement le module cloud-sql
	cd terraform/environments/$(ENV) && \
	terraform plan -target=module.cloud_sql -var-file=terraform.tfvars

plan-cloud-run: ## Planifie uniquement le module cloud-run
	cd terraform/environments/$(ENV) && \
	terraform plan -target=module.cloud_run -var-file=terraform.tfvars

plan-monitoring: ## Planifie uniquement le module monitoring
	cd terraform/environments/$(ENV) && \
	terraform plan -target=module.monitoring -var-file=terraform.tfvars

# Commandes de déploiement par étapes
deploy-base: ## Déploie l'infrastructure de base (networking + iam)
	@echo "${GREEN}🏗️  Déploiement de l'infrastructure de base${NC}"
	cd terraform/environments/$(ENV) && \
	terraform apply -target=module.networking -target=module.iam -var-file=terraform.tfvars

deploy-database: ## Déploie la base de données
	@echo "${GREEN}🗄️  Déploiement de la base de données${NC}"
	cd terraform/environments/$(ENV) && \
	terraform apply -target=module.cloud_sql -var-file=terraform.tfvars

deploy-app: ## Déploie l'application
	@echo "${GREEN}🚀 Déploiement de l'application${NC}"
	cd terraform/environments/$(ENV) && \
	terraform apply -target=module.cloud_run -var-file=terraform.tfvars

deploy-monitoring: ## Déploie le monitoring
	@echo "${GREEN}📊 Déploiement du monitoring${NC}"
	cd terraform/environments/$(ENV) && \
	terraform apply -target=module.monitoring -var-file=terraform.tfvars

# Commandes de gestion des secrets
show-secrets: ## Affiche les noms des secrets
	@echo "${GREEN}🔐 Secrets pour l'environnement $(ENV)${NC}"
	cd terraform/environments/$(ENV) && \
	terraform output db_password_secret_name

# Commandes de monitoring
dashboard: ## Ouvre le dashboard de monitoring
	@echo "${GREEN}📊 Ouverture du dashboard${NC}"
	cd terraform/environments/$(ENV) && \
	open $$(terraform output -raw dashboard_url)

logs: ## Affiche les logs Cloud Run
	@echo "${GREEN}📝 Logs Cloud Run pour l'environnement $(ENV)${NC}"
	cd terraform/environments/$(ENV) && \
	gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=$$(terraform output -raw cloud_run_service_account | cut -d'-' -f1-3)-service" --limit=50

# Commandes de test
test-health: ## Teste le health check de l'application
	@echo "${GREEN}🏥 Test du health check${NC}"
	cd terraform/environments/$(ENV) && \
	curl -f $$(terraform output -raw cloud_run_url)/actuator/health

# Commandes pour tous les environnements
init-all: ## Initialise tous les environnements
	@for env in dev staging prod; do \
		echo "${GREEN}Initialisation de $$env${NC}"; \
		make init ENV=$$env; \
	done

plan-all: ## Planifie tous les environnements
	@for env in dev staging prod; do \
		echo "${YELLOW}Planification de $$env${NC}"; \
		make plan ENV=$$env; \
	done

format-all: ## Formate tout le code
	@echo "${GREEN}🎨 Formatage de tout le code${NC}"
	terraform fmt -recursive .

validate-all: ## Valide tous les environnements
	@for env in dev staging prod; do \
		echo "${GREEN}Validation de $$env${NC}"; \
		make validate ENV=$$env; \
	done 