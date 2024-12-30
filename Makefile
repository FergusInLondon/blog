.PHONY: terraform

terraform:
	cd terraform && terraform init
	cd terraform && terraform fmt
	cd terraform && terraform validate
	cd terraform && terraform plan

dev:
	cd hugo && hugo server
