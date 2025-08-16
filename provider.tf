terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.81.0"
    }
  }
  required_version = ">= 1.0"
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  username = var.proxmox_username
  password = var.proxmox_password

  # https://github.com/bpg/terraform-provider-proxmox/issues/1610
  # random_vm_ids      = true
  # random_vm_id_start = 90000
  # random_vm_id_end = 90999

  # because self-signed TLS certificate is in use at present
  insecure = true

  tmp_dir = "/var/tmp"

  ssh {
    agent    = true
    username = var.proxmox_ssh_username
  }
}
