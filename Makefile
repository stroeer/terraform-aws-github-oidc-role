all: fmt validate tflint

.PHONY: fmt
fmt: ## Checks config files against canonical format
	@echo "+ $@"
	@terraform fmt -check=true -recursive

.PHONY: validate
validate: ## Validates the Terraform files
	@echo "+ $@"
	terraform init -backend=false > /dev/null; \
	terraform validate || exit 1 ;\

.PHONY: tflint
tflint: ## Runs tflint on all Terraform files
	@echo "+ $@"
	@tflint --init
	terraform init -backend=false -lockfile=readonly > /dev/null; \
	tflint --format=compact --config=.tflint.hcl || exit 1;\
