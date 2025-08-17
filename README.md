# Proxmox VM Bootstrap

[![CI - Validate](https://github.com/dafywinf-homelab-platform/proxmox-vm-bootstrap/actions/workflows/ci-validate.yaml/badge.svg)](https://github.com/dafywinf-homelab-platform/proxmox-vm-bootstrap/actions/workflows/ci-validate.yaml)
[![Renovate - Validate](https://github.com/dafywinf-homelab-platform/proxmox-vm-bootstrap/actions/workflows/renovate-validate.yaml/badge.svg)](https://github.com/dafywinf-homelab-platform/proxmox-vm-bootstrap/actions/workflows/renovate-validate.yaml)

This repository provides an **infrastructure-as-code framework** for bootstrapping virtual machines on Proxmox using
Terraform. It automates the creation of Cloud-Init enabled Ubuntu templates and VM instances, including CPU, memory,
networking, and optional additional storage.

The setup ensures reproducible builds with linting and security checks via a **Dockerised Makefile toolchain**, and integrates with **GitHub Actions, Dependabot, and Renovate** for validation and dependency management.

---

## Features

* Terraform definitions for Proxmox VMs (CPU, memory, networking, storage)
* Cloud-Init enabled Ubuntu templates
* Makefile-based toolchain (Terraform, TFLint, TFSec, ShellCheck) with **pinned versions** (kept fresh by Renovate)
* Automated validation via GitHub Actions
* Dependency management with Dependabot and Renovate

---

## VM Definitions

All virtual machines are defined centrally in [`variables.tf`](./variables.tf) under the `vms` variable.
This map specifies the configuration for each VM — CPU, memory, disk sizes, networking, and startup behaviour.

The default configuration reflects **my personal homelab**, geared towards **K3s Kubernetes clusters**. Out of the box, it provisions:

* A set of **K3s master nodes**
* A set of **K3s worker nodes**
* Supporting infrastructure VMs (monitoring, collaboration, etc.)

You can freely adjust the `vms` map to match your own lab or production needs.

---

## Repository Overview

* **`variables.tf`** → Central definition of VM instances
* **`main.tf` & `.tf` modules** → Terraform logic for VM creation
* **`Makefile`** → Toolchain (Terraform/TFLint/TFSec/ShellCheck via Docker)
* **`.github/workflows/`** → CI validation & Renovate checks
* **`.github/dependabot.yml`** → Dependency updates for Terraform + GitHub Actions
* **`renovate.json5`** → Keeps pinned Makefile tool versions fresh

---

## Getting Started

### Pre-conditions

1. **Create Secret for Proxmox Password**
   Create `secrets.tfvars` in the repo root:

   ```hcl
   proxmox_password = "XXXXXXX"
   ```

2. **Generate SSH Keys**

   ```sh
   ssh-keygen -t ed25519 -C "your_email@example.com" -f ~/.ssh/id_ed25519_proxmox_vm
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_ed25519_proxmox_vm
   ```

3. **Update VM Definitions** in [`variables.tf`](./variables.tf).

---

### Deploy a VM

```sh
terraform init
terraform plan -var-file="secrets.tfvars"
terraform apply -var-file="secrets.tfvars" --auto-approve
```

Hosts are accessible on the LAN via `<hostname>.local` (thanks to mDNS/Avahi).

Example:

```sh
ssh ubuntu@docker-compose-server.local
```

---

## Development & CI Tooling

Run checks locally:

```sh
make validate
```

Available targets:

* `validate` → fmt, validate, tflint, tfsec, shellcheck
* `fmt` → Terraform formatting
* `tflint` → Terraform linting
* `tfsec` → Security scanning
* `shellcheck` → Shell script linting

All tools are run via Docker, with pinned versions kept up to date by Renovate.

GitHub Actions runs these validations on **push, PR, and schedule**.

---

## Further Reading

For **design rationale** and **trade-offs**, see the [docs/adr](./docs/adr/01-architectural-decision-records.md) directory:

* [ADR-001: Disk Configuration for Proxmox VMs](./docs/adr/adr-001-disk-configuration.md)
* [ADR-002: Disk and mDNS Design](./docs/adr/adr-002-mdns-avahi.md)
* [ADR-003: Handling Cloud Image Updates](./docs/adr/adr-003-handling-cloud-image-updates.md)

For the full system view, see the [Design Specification](./docs/01-design-specification.md).

