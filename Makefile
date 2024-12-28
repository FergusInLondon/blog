.PHONY: terraform

terraform:
	cd terraform && terraform init
	cd terraform && terraform fmt
	cd terraform && terraform validate

tf_plan: terraform
	source ./env && cd terraform && terraform plan

tf_deploy: tf_plan
	source ./env && cd terraform && terraform apply
