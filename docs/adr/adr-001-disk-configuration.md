# ADR 001: Disk Configuration for Proxmox VMs

**Status:** Accepted
**Date:** 2025-01-07

## Context

Proxmox virtual machines provisioned via Terraform require a predictable and reproducible disk layout.
VMs should separate the OS disk from data disks to simplify upgrades, resilience, and scalability.

## Decision

* Use **three disks**:

    1. **Primary Disk (`scsi0`)** — Ubuntu Cloud Image, boot OS.
    2. **Secondary Disk (`scsi1`)** — Additional storage, mounted at `/mnt/data`.
    3. **EFI Disk (`efi_disk`)** — Required for UEFI boot.

* **Cloud-Init** configures `scsi1` on first boot:

    * Formats as `ext4`
    * Creates `/mnt/data`
    * Updates `/etc/fstab`

* Add Terraform lifecycle rule to **ignore changes** in `disk[0].file_id` to prevent unnecessary VM re-creation when cloud images update.

```hcl
lifecycle {
  ignore_changes = [disk[0].file_id]
}
```

## Consequences

* Ensures clean separation of OS and data.
* Prevents destructive VM rebuilds when updating cloud images.
* Provides flexibility for resizing and extending data disks.