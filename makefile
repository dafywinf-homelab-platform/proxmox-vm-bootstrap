# ---- Tool images (pin versions for reproducibility)
TF_IMAGE        ?= hashicorp/terraform:latest
TFLINT_IMAGE    ?= ghcr.io/terraform-linters/tflint:latest
TFSEC_IMAGE     ?= aquasec/tfsec:latest
SHELLCHECK_IMAGE?= koalaman/shellcheck:latest

# ---- Container runtime (Docker or Podman)
DOCKER ?= docker

# ---- Common mounts & flags
# Use CURDIR (GNU make) for a portable absolute path
MOUNT   = -v $(CURDIR):/workspace -w /workspace
NET     = --network=host
ENVVARS = -e TF_IN_AUTOMATION=1

RUN_TF      = $(DOCKER) run --rm $(NET) $(ENVVARS) $(MOUNT) $(TF_IMAGE)
RUN_TFLINT  = $(DOCKER) run --rm $(NET)         $(MOUNT) $(TFLINT_IMAGE)
RUN_TFSEC   = $(DOCKER) run --rm $(NET)         $(MOUNT) $(TFSEC_IMAGE)
RUN_SHCHECK = $(DOCKER) run --rm                $(MOUNT) $(SHELLCHECK_IMAGE)

# ---- Files
SHELL_SCRIPTS ?= $(wildcard *.sh) auto-deploy.sh

.PHONY: help validate fmt init validate-tf tflint tfsec shellcheck clean

help:
	@echo "Targets:"
	@echo "  make validate      - run fmt, terraform validate, tflint, tfsec, shellcheck"
	@echo "  make fmt           - terraform fmt -check -recursive"
	@echo "  make init          - terraform init -backend=false"
	@echo "  make validate-tf   - terraform validate"
	@echo "  make tflint        - run TFLint"
	@echo "  make tfsec         - run tfsec (soft-fail)"
	@echo "  make shellcheck    - shellcheck *.sh if present"
	@echo "  make clean         - remove .terraform and lockfile"

validate: fmt validate-tf tflint tfsec shellcheck

fmt:
	$(RUN_TF) fmt -check -recursive

init:
	$(RUN_TF) init -backend=false

validate-tf: init
	$(RUN_TF) validate -no-color

tflint:
	$(RUN_TFLINT) --no-color

tfsec:
	# --soft-fail so info/warnings don't break your flow; drop flag to enforce
	$(RUN_TFSEC) --no-color --soft-fail

shellcheck:
	@if [ -n "$(SHELL_SCRIPTS)" ]; then \
	  for f in $(SHELL_SCRIPTS); do \
	    if [ -f $$f ]; then echo "ShellCheck $$f"; $(RUN_SHCHECK) $$f; fi; \
	  done \
	else \
	  echo "No shell scripts to check."; \
	fi

clean:
	rm -rf .terraform .terraform.lock.hcl
