variable "vms" {
  description = "Map of VMs to be created, including VMID, network config, CPU, memory and disk sizes"
  type = map(object({
    vmid             = number
    ipv4_address     = string
    ipv4_gateway     = string
    cores            = number
    dedicated_memory = number
    floating_memory  = number
    scsi0_size_gb    = number
    scsi1_size_gb    = number
    started          = bool
  }))
  default = {
    "k3s-master-1" = {
      vmid            = 1001, ipv4_address = "dhcp", ipv4_gateway = "", cores = 2, dedicated_memory = 2048,
      floating_memory = 2048, scsi0_size_gb = 32, scsi1_size_gb = 5, started = true
    }
    "k3s-master-2" = {
      vmid            = 1002, ipv4_address = "dhcp", ipv4_gateway = "", cores = 2, dedicated_memory = 2048,
      floating_memory = 2048, scsi0_size_gb = 32, scsi1_size_gb = 5, started = true
    }
    "k3s-master-3" = {
      vmid            = 1003, ipv4_address = "dhcp", ipv4_gateway = "", cores = 2, dedicated_memory = 2048,
      floating_memory = 2048, scsi0_size_gb = 32, scsi1_size_gb = 5, started = true
    }
    "k3s-worker-1" = {
      vmid            = 1004, ipv4_address = "dhcp", ipv4_gateway = "", cores = 3, dedicated_memory = 10000,
      floating_memory = 2048, scsi0_size_gb = 32, scsi1_size_gb = 250, started = true
    }
    "k3s-worker-2" = {
      vmid            = 1005, ipv4_address = "dhcp", ipv4_gateway = "", cores = 3, dedicated_memory = 10000,
      floating_memory = 2048, scsi0_size_gb = 32, scsi1_size_gb = 250, started = true
    }
    "monitoring-server" = {
      vmid            = 1006, ipv4_address = "dhcp", ipv4_gateway = "", cores = 2, dedicated_memory = 8192,
      floating_memory = 2048, scsi0_size_gb = 10, scsi1_size_gb = 30, started = false
    }
    "confluence-server" = {
      vmid            = 1007, ipv4_address = "dhcp", ipv4_gateway = "", cores = 2, dedicated_memory = 8192,
      floating_memory = 2048, scsi0_size_gb = 10, scsi1_size_gb = 30, started = false
    }

    # "octostar-installation-server" = {
    #   vmid            = 1008, ipv4_address = "dhcp", ipv4_gateway = "", cores = 4, dedicated_memory = 16384,
    #   floating_memory = 2048, scsi0_size_gb = 50, scsi1_size_gb = 30
    # }

  }
}

variable "cloud_image" {
  description = "Cloud Image Download Releases Path"
  type        = string
  default     = "https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img"
}

variable "is_template" {
  description = "Whether this resource is a template rather than a VM"
  type        = bool
  default     = false
}

variable "proxmox_username" {
  description = "Proxmox username used to authenticate"
  type        = string
  default     = "root@pam"
}

variable "proxmox_password" {
  description = "Proxmox password used to authenticate"
  type        = string
  sensitive   = true
}

variable "proxmox_ssh_username" {
  description = "Proxmox SSH username - used with local private key"
  type        = string
  default     = "root"
}

variable "proxmox_endpoint" {
  description = "Proxmox API URL"
  type        = string
  default     = "https://proxmox.local:8006/"
}

variable "proxmox_node" {
  description = "Proxmox node to deploy the VM"
  type        = string
  default     = "proxmox"
}

variable "ssh_proxmox_vm_public_key_path" {
  description = "Path to the SSH public key deployed to VMs"
  type        = string
  default     = "~/.ssh/id_ed25519_proxmox_vm.pub"
}

variable "storage" {
  description = "Storage location for the VM disks"
  type        = string
  default     = "local-ssd"
}

variable "user" {
  description = "Default Cloud-Init username"
  type        = string
  default     = "ubuntu"
}

variable "timezone" {
  description = "Timezone to set on the VM template"
  type        = string
  default     = "Europe/London"
}

variable "tags" {
  description = "Tags to associate with the template"
  type        = list(string)
  default     = ["cloudinit", "ubuntu", "noble-numbat", "terraform-generated"]
}