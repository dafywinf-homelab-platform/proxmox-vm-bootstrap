# Proxmox VM Bootstrap – Design Specification (v0.4)

This document captures the key design, tooling, and automation decisions for the **Proxmox VM Bootstrap** repository.
It summarises the current setup so that future discussions can build upon a shared reference point.

---

## 1. Purpose

This repository provides an **infrastructure-as-code workflow** for provisioning Proxmox virtual machines with Terraform.

It automates the creation of Cloud-Init enabled Ubuntu templates and VM instances, including configuration of CPU, memory, disks, networking, and additional storage.

It is primarily tailored for **homelab Kubernetes (K3s) deployment**.

---

## 2. Repository Overview

**Key files and structure:**

* **`variables.tf`** → Central definition of VM instances via the `vms` map.
* **`main.tf` and supporting `.tf` files** → Terraform logic for provisioning Proxmox VMs.
* **`Makefile`** → Provides a reproducible toolchain for Terraform, linting, security scanning, and ShellCheck, all containerised with Docker.
* **`.github/workflows/`** → GitHub Actions workflows for validation and Renovate CI checks.
* **`.github/dependabot.yml`** → Dependabot configuration for Terraform providers and GitHub Actions.
* **`renovate.json5`** → Renovate configuration for keeping Makefile Docker image tags up to date.

**Defaults:**

* The default `vms` map is designed for the author’s personal homelab.
* Includes multiple **K3s masters**, **K3s workers**, and supporting servers.

---

## 3. VM Definitions

VMs are defined in `variables.tf` under the `vms` variable, which is a map of objects with the following keys:

* `vmid` (number)
* `ipv4_address` (string)
* `ipv4_gateway` (string)
* `cores` (number)
* `dedicated_memory` (number, MB)
* `floating_memory` (number, MB)
* `scsi0_size_gb` (number)
* `scsi1_size_gb` (number)
* `started` (bool)

The default configuration provisions a K3s cluster and related infrastructure VMs.

---

## 4. Tooling via Makefile

The **Makefile** provides a consistent interface for developers and CI:

* **Dockerised tooling** (versions pinned in `Makefile`, updated by Renovate):

  * Terraform
  * TFLint
  * TFSec
  * ShellCheck

* **Targets:**

  * `validate` → Runs all checks (fmt, validate, tflint, tfsec, shellcheck)
  * `fmt` → Checks Terraform formatting
  * `init` → Terraform init (no backend)
  * `validate-tf` → Terraform validate
  * `tflint` → Linter
  * `tfsec` → Security scan (soft fail)
  * `shellcheck` → Validate shell scripts
  * `clean` → Remove `.terraform` and lock files
  * `check-makefile-tags` → Ensures pinned image tags are present

---

## 5. GitHub Actions Integration

* **Workflows:**

  * `.github/workflows/ci-validate.yaml` → Runs validation on push/PR/schedule.
  * `.github/workflows/renovate-check.yml` → Runs Renovate locally to confirm Makefile regex parsing works.

    * Fails CI if no dependencies are extracted (`depCount = 0`).
    * Triggered only on changes to `Makefile` or `renovate.json5`.

* **Triggers:**

  * On push to `main`
  * On pull requests to `main`
  * Weekly scheduled run

* **Jobs:**

  * Checkout repo
  * (Optional) login to GHCR for Docker pulls
  * Run `make validate`
  * Run Renovate parse check

**Badge:** README includes a build status badge linked to `ci-validate`.

---

## 6. Dependency Management

### Dependabot

* Config file: `.github/dependabot.yml`
* Responsibilities:

  * Keep Terraform providers/modules up to date
  * Keep GitHub Actions up to date

### Renovate

* Config file: `renovate.json5`
* Responsibilities:

  * Keep pinned Docker image versions in `Makefile` up to date
  * Weekly update window (Sunday 03:00–05:00 UK)
  * Uses `custom.regex` manager restricted to root `Makefile`
  * Groups toolchain images into a single PR
  * Semantic commits, `replace` range strategy

**Note:** Labels (`dependencies`, `gha`, `terraform`, `docker`, `renovate`) must exist in the repo.

---

## 7. Design Notes

* **Disk layout:** (see [ADR-001](adr/adr-001-disk-configuration.md))

  * Primary disk (`scsi0`) holds the OS.
  * Secondary disk (`scsi1`) is for additional storage, auto-formatted and mounted at `/mnt/data`.
  * EFI disk included for UEFI boot.
  * Consequence: Ubuntu cloud image updates are ignored (VMs require patching separately).

* **mDNS (Avahi):** (see [ADR-002](adr/adr-002-mdns-avahi.md))
  Used to simplify VM host discovery on the LAN. Hosts can be reached via `<hostname>.local` without DNS setup.
  Supported across macOS, most Linux distributions, and modern Windows versions (with Bonjour/mDNSResponder).

* **Terraform lifecycle ignore (`disk[0].file_id`):** (see [ADR-003](adr/adr-003-handling-cloud-image-updates.md))
  Used to avoid destructive VM recreation when upstream Ubuntu cloud images are updated.

* **Cloud-Init:**
  Configures users, SSH keys, packages, Avahi, and additional disk formatting/mounting.

* **Memory model:**
  Differentiates between `dedicated_memory` and `floating_memory` to control ballooning.

* **Networking:**
  Defaults to DHCP and mDNS (`hostname.local`).

* **Git ignore policy:**
  `.terraform/`, `terraform.tfstate`, and backups excluded from Git.

---

## 8. Summary

This repo provides a reproducible, automated workflow for managing Proxmox VMs with Terraform, with CI validation via GitHub Actions and dependency updates via **Dependabot and Renovate**.

It is optimised for homelab **K3s Kubernetes clusters**, but can be adapted for other workloads by editing the `vms` map and variables.

---

## 9. Versioning

* **v0.1** → Initial spec with pinned `:latest` Docker images and Dependabot.
* **v0.2** → Introduced Renovate with custom regex manager, CI Renovate check, and explicit pinned versions.
* **v0.3** → Documentation updated to remove exact versions; `Makefile` is source of truth.
* **v0.4** → Added design decisions for disk layout, mDNS (Avahi), and lifecycle ignore on `disk[0].file_id`. Linked to ADRs for traceability.

