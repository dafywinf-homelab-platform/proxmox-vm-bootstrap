# Proxmox VM Bootstrap

[![CI - Validate](https://github.com/dafywinf-homelab-platform/proxmox-vm-bootstrap/actions/workflows/ci-validate.yaml/badge.svg)](https://github.com/dafywinf-homelab-platform/proxmox-vm-bootstrap/actions/workflows/ci-validate.yaml)

This repository provides an infrastructure-as-code framework for bootstrapping virtual machines on Proxmox using
Terraform. It automates the creation of cloud-init enabled Ubuntu templates and VM instances, including configuration of
CPU, memory, disks, networking, and optional additional storage. The setup ensures reproducible builds with linting and
security checks via a Dockerised Makefile toolchain, and integrates with GitHub Actions and Dependabot for automated
validation and dependency management.

## VM Definitions

All virtual machines are defined centrally in the [`variables.tf`](./variables.tf) file under the `vms` variable.
This map specifies the configuration for each VM — including CPU, memory, disk sizes, networking, and whether the VM
should be started automatically.

The default configuration provided in this repository reflects **my personal homelab environment**, which is primarily
geared towards deploying and experimenting with **Kubernetes (K3s)** clusters. Out of the box, the `vms` variable
includes definitions for:

* A set of **K3s master nodes**
* A set of **K3s worker nodes**
* Supporting infrastructure VMs (e.g. monitoring, collaboration tools)

You can freely adjust the `vms` map to match your own lab or production requirements, adding or removing hosts as
needed.

---

# Pre-Conditions

### Create Secret for Proxmox Password

Create a file secrets.tfvars in the base directory of this repo:

```sh
#secrets.tfvars content
proxmox_password = "XXXXXXX"
```

### Generate SSH Keys

Create new set of SSH keys if you don't already have a key pair you want to use:

```sh
# Generate a new key pair
ssh-keygen -t ed25519 -C "your_email@example.com" -f ~/.ssh/id_ed25519_proxmox_vm

# Ensure the SSH agent is running
eval "$(ssh-agent -s)"

# Add your private key to the agent
ssh-add ~/.ssh/id_ed25519_proxmox_vm
```

### Update Variables

The content of variables.tf will need to be updated

🖥️ Virtual Machines (vms)
A map of VM configurations, allowing fine-tuned control of each instance.

- vmid (number): Unique VM identifier.
- ipv4_address (string): IPv4 address (e.g., dhcp).
- ipv4_gateway (string): IPv4 gateway address.
- cores (number): Number of CPU cores assigned.
- dedicated_memory (number): Dedicated memory in MB.
- floating_memory (number): Floating memory in MB.
- scsi0_size_gb (number): Disk size for the primary SCSI storage (GB).
- scsi1_size_gb (number): Disk size for the secondary SCSI storage (GB).

Note: I found that I had to downgrade the bgp provider and set the VMIDs statically due to this
issue: https://github.com/bpg/terraform-provider-proxmox/issues/1610.

#### Memory Type Differences

1. Dedicated Memory (dedicated)
   Represents the guaranteed amount of RAM allocated to the VM.
   Acts as the minimum memory assigned to the VM, ensuring it always has this much available.
   If set equal to floating, then memory ballooning is disabled (the VM always gets a fixed amount of RAM).
2. Floating Memory (floating)
   Defines the maximum memory the VM can use.
   Enables ballooning, which allows the VM to dynamically adjust its memory usage based on demand and availability.
   If greater than dedicated, Proxmox can reclaim unused memory and reallocate it to other VMs.

<br/>

# Adding a new Host 🔥

The hosts that are deployed is driven be the variable `vms` found in `variables.tf`. To add a host update this data
structure.

```js
  default
= {

    "docker-compose-server" = {
        vmid = 1006, ipv4_address = "dhcp", ipv4_gateway = "", cores = 2, dedicated_memory = 8192,
        floating_memory = 2048, scsi0_size_gb = 10, scsi1_size_gb = 0
    }
}
```

## **VM Configuration: `docker-compose-server`**

### **General Information**

- **VM Name:** `docker-compose-server`
- **VM ID:** `1006`
- **Hostname:** `docker-compose-server`
- **mDNS Name:** `docker-compose-server.local`

### **Compute Resources**

- **CPU:** `2 cores`
- **Memory:**
    - **Dedicated:** `8GB (8192MB)`
    - **Floating:** `2GB (2048MB)` (Ballooning enabled)

### **Storage**

- **Primary Disk (`scsi0`):** `10GB`
- **Secondary Disk (`scsi1`):** `30GB`

### **Networking**

- **IPv4 Address:** `DHCP` (Dynamically assigned)
- **IPv4 Gateway:** Not specified (May be assigned via DHCP)
- **Network Interface:** Attached to `vmbr0` (Proxmox bridge)

### **Additional Configurations**

- **BIOS:** `OVMF` (UEFI boot)
- **Machine Type:** `q35` (Modern hardware emulation)
- **Cloud-Init Metadata:** Configured via Terraform
- **Proxmox Guest Agent:** Enabled (`agent { enabled = true }`)
- **Disk TRIM (Discard):** Enabled for storage efficiency

This setup defines a lightweight, dynamically allocated VM suitable for **Docker Compose workloads**, with mDNS access
via `docker-compose-server.local`. 🚀

<br/>

# Execute Terraform

To deploy the template execute the Terraform

```sh
terraform init
terraform plan -var-file="secrets.tfvars"
terraform apply -var-file="secrets.tfvars" --auto-approve
```

# Accessing Servers

The created hosts will be available on the local network via `<hostname>.local` where the hostname is the key in the vms
map. Your public key (setup as a pre-condition) is automatically added to each host.

```
 ➜  proxmox-infrastructure git:(main) ✗ ssh ubuntu@docker-compose-server.local
The authenticity of host 'docker-compose-server.local (fe80::be24:11ff:fed9:998d%en0)' can't be established.
ED25519 key fingerprint is SHA256:i+/+M6AoSc0qpJQjMs47hjg2FokkD6qaQrJAP4xXXXX.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'docker-compose-server.local' (ED25519) to the list of known hosts.
Welcome to Ubuntu 24.04.1 LTS (GNU/Linux 6.8.0-52-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Sun Feb  2 11:59:38 UTC 2025

  System load:  0.08              Processes:             131
  Usage of /:   23.5% of 8.65GB   Users logged in:       0
  Memory usage: 2%                IPv4 address for eth0: 192.168.86.73
  Swap usage:   0%

Expanded Security Maintenance for Applications is not enabled.

0 updates can be applied immediately.

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status



The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

ubuntu@docker-compose-server:~$
```

## SSH Errors

If you have previously associated the hostname with a host key, key verification will fail:

```sh
# Host key for docker-compose-server.local has changed and you have requested strict checking.
# Host key verification failed.
```

Remove the ssh key from hosts.

```sh
# Host key for docker-compose-server.local has changed and you have requested strict checking.
# Host key verification failed.

ssh-keygen -R docker-compose-server.local
```



# 🛠 Development & CI Tooling

This repository includes tooling to make working with Terraform and shell scripts reproducible and consistent across
environments.

## Makefile

A **Makefile** is provided to standardise common developer tasks. Instead of installing Terraform, TFLint, tfsec, or
ShellCheck locally, these are run inside pinned Docker containers.

### Available targets

```sh
make help
```

Outputs:

* `make validate` → runs fmt, validate, tflint, tfsec, and shellcheck
* `make fmt` → check Terraform formatting
* `make init` → initialise Terraform (no backend)
* `make validate-tf` → run Terraform validate
* `make tflint` → run TFLint rules
* `make tfsec` → run tfsec (soft-fail by default)
* `make shellcheck` → run ShellCheck against `*.sh` files
* `make clean` → remove `.terraform` and lock files

Because all tooling runs in Docker containers with pinned versions, developers and CI runners will always use the same
versions.

### Example usage

```sh
make validate
```

---

## GitHub Actions Integration

This repository includes a GitHub Actions workflow that automatically runs the Makefile validation steps.

* **When it runs**

    * On every pull request
    * On pushes to `main`
    * On a weekly schedule (Monday at 06:00 UTC)

* **What it does**

    * Checks out the repo
    * Logs into GHCR (for pulling tool images)
    * Runs `make validate` to ensure:

        * Terraform is correctly formatted and validates
        * TFLint rules pass
        * tfsec security scan passes
        * Shell scripts pass ShellCheck

Results are visible in the **Actions** tab of the repository.

---

## Dependabot

Dependabot is enabled to keep dependencies up to date:

* **Terraform providers and modules**
* **GitHub Actions workflows**
* **Dockerfiles** (if you add any later)

Dependabot automatically raises pull requests when new versions are available. You can review and merge them to stay
current.

---

✅ **Summary**:

* Use the **Makefile** locally for consistent tooling.
* GitHub Actions automatically runs these checks on PRs and pushes.
* Dependabot keeps providers and GitHub Actions up to date.

---


# Design Notes 🤓

## **Disk and Mount Configuration Summary**

This Terraform configuration provisions a **Proxmox virtual machine** with the following disk and mount setup:

### **Disks Created**

1. **Primary Disk (`scsi0`)**

    - **Purpose:** Boot disk containing the **Ubuntu cloud image**.
    - **Size:** Defined in `each.value.scsi0_size_gb`.
    - **Source:** Downloads the cloud image from `var.cloud_image`.
    - **Filesystem:** Determined by the Ubuntu cloud image.
    - **Storage Location:** Stored in `var.storage`.

2. **Secondary Disk (`scsi1`)**

    - **Purpose:** Additional data storage.
    - **Size:** Defined in `each.value.scsi1_size_gb`.
    - **Format:** **Raw disk** (`file_format = "raw"`).
    - **Storage Location:** Stored in `var.storage`.
    - **Filesystem:** Initially unformatted, but configured in **Cloud-Init**.

3. **EFI Disk (`efi_disk`)**
    - **Purpose:** Required for UEFI boot.
    - **Storage Location:** Stored in `var.storage`.
    - **Size:** Managed automatically by Proxmox.

---

### **Mount Configuration**

The **Cloud-Init script** (`user_data_cloud_config.yaml`) includes a setup to configure the secondary disk (`/dev/sdb`):

1. **Checks for the existence of `/dev/sdb`** (Secondary Disk).
2. **Formats the disk** with the following setup:
    - **Partition Table:** GPT
    - **Partition Type:** Primary
    - **Filesystem:** ext4
3. **Creates a mount point at `/mnt/data`**.
4. **Updates `/etc/fstab`** to persist the mount across reboots.
5. **Mounts the disk automatically** at `/mnt/data`.

---

## 📦 Resizing VM Disks via Terraform and Guest OS Commands

This section documents how to increase the size of VM disks managed via Terraform in Proxmox, and how to apply those
changes inside the guest VM (e.g. Ubuntu).

---

### ✏️ Step 1 – Update Disk Size in `variables.tf`

To increase disk size, update the `scsi1_size_gb` value for the target VM in your `variables.tf` file.

**Example:**

```hcl
"k3s-worker-1" = {
  vmid             = 1004,
  ipv4_address     = "dhcp",
  ipv4_gateway     = "",
  cores            = 3,
  dedicated_memory = 8192,
  floating_memory  = 2048,
  scsi0_size_gb    = 32,
  scsi1_size_gb    = 250  # <- updated from 20 to 250
}
```

---

### ⚙️ Step 2 – Apply the Terraform Change

Run:

```bash
terraform apply -var-file="secrets.tfvars"
```

> Note: Terraform updates the **virtual disk size in Proxmox**, but **does not modify the partition or filesystem inside
the guest**. This must be done manually (next step).

---

### 🧰 Step 3 – Resize the Partition and Filesystem in the Guest VM

SSH into the VM and perform the following steps:

#### 1. Verify disk size before resizing

```bash
lsblk -b /dev/sdb
```

You should see the new disk size (e.g. `268435456000` bytes = 250 GB), but the partition `/dev/sdb1` will still be
small (e.g. 20 GB).

---

#### 2. Resize the partition to fill the disk

```bash
sudo growpart /dev/sdb 1
```

Example output:

```
CHANGED: partition=1 start=2048 old: size=41938944 end=41940991 new: size=524285919 end=524287966
```

---

#### 3. Resize the filesystem (ext4)

```bash
sudo resize2fs /dev/sdb1
```

Expected output:

```
Filesystem at /dev/sdb1 is mounted on /mnt/data; on-line resizing required
The filesystem on /dev/sdb1 is now XXXXXXXX blocks long.
```

---

#### 4. Confirm the change

```bash
df -h /mnt/data
```

Example:

```
Filesystem      Size  Used Avail Use% Mounted on
/dev/sdb1       246G  6.0G  240G   3% /mnt/data
```

### 📎 Notes

* These steps assume:

    * The data disk is attached as `scsi1`, mapped to `/dev/sdb`.
    * The filesystem is `ext4`.
    * The partition is `/dev/sdb1` and is mounted at `/mnt/data`.

* Ensure these tools are installed:

  ```bash
  sudo apt install -y cloud-guest-utils e2fsprogs
  ```

* If using `xfs`, replace `resize2fs` with `xfs_growfs`.




# **Supporting Notes**

✅ The **primary disk (`scsi0`)** is used for the OS and booting.  
✅ The **secondary disk (`scsi1`)** is configured for additional storage and auto-mounted at `/mnt/data`.  
✅ **EFI disk** is required for UEFI-based VM booting.  
✅ **Cloud-Init ensures secondary disk is formatted and mounted** on first boot.

This setup provides a **clean separation between the OS and additional storage**, ensuring flexibility for future disk
expansions.

## Why Install mDNS (Avahi) on Your Server?

Installing mDNS (Multicast DNS), facilitated by the Avahi Daemon, allows your server to broadcast its hostname and
services seamlessly across your local network without requiring a central DNS server or manual IP address configuration.
This makes it incredibly easy for devices like macOS, Windows, and Linux machines to discover and connect to your server
using a simple hostname (your-hostname.local) instead of remembering complex IP addresses. With mDNS, services such as
SSH, HTTP, Samba, and printer sharing become instantly accessible to other devices on the same network. Whether you're
running a home server, a development environment, or a lightweight local cloud setup, mDNS significantly simplifies
connectivity, reduces configuration overhead, and improves usability across diverse devices.

mDNS ensures that hostnames are automatically registered on the local network e.g. on the client Mac:

```sh
ssh ubuntu@docker-compose-server.local
```

## **Ignoring Cloud Image Updates in Terraform to Prevent VM Recreation**

### **Why Ignoring `disk[0].file_id` is Necessary**

In this Terraform Proxmox configuration, a **cloud image** is downloaded and attached to VMs as their primary disk (
`scsi0`). The issue arises when the cloud image (`proxmox_virtual_environment_download_file.ubuntu_cloud_image`) is *
*updated or changed**.

If Terraform detects a change in `file_id` (which happens when the image URL is updated), it will trigger a **recreation
** of all VMs using this image. This is undesirable because:

- **Terraform will attempt to destroy and recreate most VMs**, leading to unnecessary downtime.
- **Existing workloads could be lost** if not backed up.
- **Cloud-init customization may have to be reapplied**, disrupting services.

### **How Terraform Handles Changes to the Cloud Image**

#### **Without `ignore_changes = [disk[0].file_id]`**

- Terraform sees the cloud image update as a fundamental infrastructure change.
- It **marks all dependent VMs for destruction and recreation**.
- This can cause **unnecessary downtime and data loss**.

#### **With `ignore_changes = [disk[0].file_id]`**

- Terraform **ignores changes** to the `file_id` of the first disk (`scsi0`).
- The **VMs remain running**, and Terraform does **not trigger unnecessary recreations**.
- This allows you to update the cloud image **without impacting existing VMs**.

### **Terraform Configuration**

The following `lifecycle` rule ensures Terraform does not track changes to the base image:

```hcl
lifecycle {
  ignore_changes = [disk[0].file_id]
}
```



