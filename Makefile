.PHONY: plan apply destroy, port-forward

GREEN := \033[32m
RED := \033[31m
RESET := \033[0m

include .env

init:
	@echo "$(GREEN)Initializing Terraform..kk.$(RESET)"
	terraform init -upgrade

plan:
	@echo "$(GREEN)Starting Terraform plan...$(RESET)"
	terraform plan -out=plan.out

apply:
	terraform apply -auto-approve plan.out

port-forward:
	kubectl port-forward service/$(SERVICE_NAME) 8080:80

destroy:
	terraform destroy -auto-approve