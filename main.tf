resource "proxmox_virtual_environment_download_file" "ubuntu_cloud_image" {
  content_type = "iso"
  datastore_id = var.storage
  node_name    = var.proxmox_node
  url          = var.cloud_image
}

resource "proxmox_virtual_environment_vm" "ubuntu_vm" {

  for_each = var.vms


  name        = each.key
  description = "Based on: ${var.cloud_image}"
  node_name   = var.proxmox_node
  vm_id       = each.value.vmid
  tags        = var.tags

  initialization {
    dns {
      servers = ["192.168.86.1"]
    }
    ip_config {
      ipv4 {
        address = each.value.ipv4_address
        gateway = each.value.ipv4_gateway
      }
    }

    user_data_file_id = proxmox_virtual_environment_file.user_data_cloud_config.id
    meta_data_file_id = proxmox_virtual_environment_file.metadata_cloud_config[each.key].id
  }

  bios = "ovmf"

  startup {
    order      = "3"
    up_delay   = "60"
    down_delay = "60"
  }

  cpu {
    cores = each.value.cores
    numa  = true
    type  = "x86-64-v2-AES" # recommended for modern CPUs
  }

  # set equal to dedicated to enable ballooning
  memory {
    dedicated = each.value.dedicated_memory
    floating  = each.value.floating_memory
  }

  machine = "q35"

  disk {
    interface    = "scsi0"
    datastore_id = var.storage
    file_id      = proxmox_virtual_environment_download_file.ubuntu_cloud_image.id
    discard      = "on"
    size         = each.value.scsi0_size_gb
  }

  disk {
    interface    = "scsi1"
    datastore_id = var.storage
    file_format  = "raw"
    size         = each.value.scsi1_size_gb
    discard      = "on"
  }

  efi_disk {
    datastore_id = var.storage
  }

  network_device {
    bridge = "vmbr0"
  }

  operating_system {
    type = "l26"
  }

  serial_device {
    device = "socket"
  }

  vga {
    type = "serial0"
  }

  agent {
    enabled = true
    trim    = true
    timeout = "2m"
  }

  keyboard_layout = "en-gb"
  template        = var.is_template

  lifecycle {
    ignore_changes = [
      disk[0].file_id,
      initialization[0].user_data_file_id
    ]
  }

}

resource "proxmox_virtual_environment_file" "metadata_cloud_config" {
  for_each = var.vms

  content_type = "snippets"
  datastore_id = var.storage
  node_name    = var.proxmox_node

  source_raw {
    data = <<-EOF
    #cloud-config
    local-hostname: "${each.key}"
    EOF

    file_name = "metadata-cloud-config-${each.key}.yaml"
  }
}

resource "proxmox_virtual_environment_file" "user_data_cloud_config" {
  content_type = "snippets"
  datastore_id = var.storage
  node_name    = var.proxmox_node

  source_raw {
    data = <<-EOF
    #cloud-config
    # https://registry.terraform.io/providers/bpg/proxmox/latest/docs/guides/cloud-init

    autoinstall:
      version: 1

    users:
      - default
      - name: ubuntu
        groups:
          - sudo
        shell: /bin/bash
        ssh_authorized_keys:
          - ${trimspace(file(var.ssh_proxmox_vm_public_key_path))}
        sudo: ALL=(ALL) NOPASSWD:ALL

    runcmd:
      - apt update
      - apt full-upgrade -y  # Ensures all packages are upgraded
      - apt autoremove -y    # Cleans up unnecessary dependencies      
      - apt install -y qemu-guest-agent net-tools avahi-daemon
      - timedatectl set-timezone $var.timezone
      - systemctl enable ssh
      - systemctl enable avahi-daemon

      # Disk Configuration and Formatting
      - |
        DISK="/dev/sdb"
        MOUNT_POINT="/mnt/data"

        echo "Starting disk setup for $DISK"

        if [ -b "$DISK" ]; then
            echo "Disk $DISK detected. Formatting..."

            # Create GPT Partition Table and Partition
            parted "$DISK" --script mklabel gpt
            parted "$DISK" --script mkpart primary ext4 1MiB 100%
            partprobe "$DISK"
            sleep 5

            # Verify Partition
            lsblk

            # Format Partition
            echo "Creating ext4 filesystem on $DISK1"
            mkfs.ext4 "$DISK"1

            # Mount Partition
            mkdir -p "$MOUNT_POINT"
            echo "Updating /etc/fstab"
            echo "$DISK"1 "$MOUNT_POINT" ext4 defaults 0 2 >> /etc/fstab

            echo "Mounting all filesystems"
            mount -a

            echo "Disk $DISK successfully formatted and mounted at $MOUNT_POINT"
        else
            echo "Disk $DISK not found. Skipping disk setup."
        fi

      # Final Reboot
      - reboot
  EOF

    file_name = "user-data-cloud-config.yaml"
  }
}
