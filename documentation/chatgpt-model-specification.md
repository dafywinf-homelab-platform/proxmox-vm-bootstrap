# Proxmox VM Bootstrap – Model Specification

This document captures the key design, tooling, and automation decisions for the **Proxmox VM Bootstrap** repository. It summarises the current setup so that future discussions can build upon a shared reference point.

---

## 1. Purpose

This repository provides an **infrastructure-as-code workflow** for provisioning Proxmox virtual machines with Terraform. It automates the creation of Cloud-Init enabled Ubuntu templates and VM instances, including configuration of CPU, memory, disks, networking, and additional storage. It is primarily tailored for **homelab Kubernetes (K3s) deployment**.

---

## 2. Repository Overview

**Key files and structure:**

* **`variables.tf`** → Central definition of VM instances via the `vms` map.
* **`main.tf` and supporting `.tf` files** → Terraform logic for provisioning Proxmox VMs.
* **`Makefile`** → Provides a reproducible toolchain for Terraform, linting, security scanning, and ShellCheck, all containerised with pinned versions.
* **`.github/workflows/`** → GitHub Actions workflows that run validation automatically.
* **`.github/dependabot.yml`** → Dependabot configuration for Terraform providers and GitHub Actions.

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

* **Pinned Docker images:**

    * `terraform:1.8.5`
    * `tflint:v0.58.1` (migrated from deprecated bundle)
    * `tfsec:v1.28.12`
    * `shellcheck:v0.10.0`

* **Targets:**

    * `validate` → Runs all checks (fmt, validate, tflint, tfsec, shellcheck)
    * `fmt` → Checks Terraform formatting
    * `init` → Terraform init (no backend)
    * `validate-tf` → Terraform validate
    * `tflint` → Linter
    * `tfsec` → Security scan (soft fail)
    * `shellcheck` → Validate shell scripts
    * `clean` → Remove `.terraform` and lock files

---

## 5. GitHub Actions Integration

* **Workflow:** `.github/workflows/ci-validate.yaml`
* **Triggers:**

    * On push to `main`
    * On pull requests to `main`
    * Weekly scheduled run
* **Jobs:**

    * Checkout repo
    * (Optional) login to GHCR for Docker pulls
    * Run `make validate`

**Badge:** README includes a build status badge linked to this workflow.

---

## 6. Dependabot Integration

* Config file: `.github/dependabot.yml`
* Responsibilities:

    * Keep Terraform providers/modules up to date
    * Keep GitHub Actions up to date
    * (Optionally) manage Dockerfiles in the future

**Note:** Labels (`dependencies`, `gha`, `terraform`, `docker`) must exist in the repo before Dependabot can apply them.

---

## 7. Outstanding / Not Yet Integrated

* **Renovate**: Not currently integrated, but considered for future to automatically update pinned Docker image tags in the Makefile.
* **Label creation**: Requires manual setup or `gh label create` commands.

---

## 8. Design Notes

* **Terraform lifecycle ignore:** Used on `disk[0].file_id` to prevent unnecessary VM recreation when cloud image URLs change.
* **Cloud-Init:** Configures users, SSH keys, packages, Avahi (mDNS), and additional disk formatting/mounting.
* **Memory model:** Differentiates between `dedicated_memory` and `floating_memory` to control ballooning.
* **Networking:** Defaults to DHCP and mDNS (`hostname.local`).

---

## 9. Summary

This repo provides a reproducible, automated workflow for managing Proxmox VMs with Terraform, with CI validation via GitHub Actions and dependency updates via Dependabot. It is currently optimised for homelab **K3s Kubernetes clusters**, but can be adapted for other workloads by editing the `vms` map and variables.
