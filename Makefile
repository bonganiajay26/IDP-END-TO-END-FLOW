.PHONY: test tf-init tf-validate tf-plan bootstrap lint

test:
	cd sample-service && python -m pytest -q

tf-init:
	terraform -chdir=infra/terraform init

tf-validate: tf-init
	terraform -chdir=infra/terraform fmt -check -recursive
	terraform -chdir=infra/terraform validate

tf-plan: tf-init
	terraform -chdir=infra/terraform plan

bootstrap:
	./bootstrap/install-argocd.sh
