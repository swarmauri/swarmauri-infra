terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "2.9.11"  # Specify the appropriate version
    }
  }
}

provider "proxmox" {
  pm_api_url    = var.proxmox_api_url
  pm_user       = var.proxmox_user
  pm_password   = var.proxmox_password
}

# Null Resource to Download the Ubuntu ISO
resource "null_resource" "download_ubuntu_iso" {
  provisioner "local-exec" {
    command = <<EOT
      curl -L -o /tmp/ubuntu-22.04-live-server-amd64.iso ${var.ubuntu_iso}
    EOT
  }

  triggers = {
    ubuntu_iso = var.ubuntu_iso
  }
}

# Creating VMs
resource "proxmox_vm_qemu" "vm" {
  count        = var.vm_count
  name         = "ubuntu-vm-${count.index + 100}"
  target_node  = var.proxmox_node
  cores        = var.cores
  sockets      = var.sockets
  memory       = var.memory

  network {
    model  = "virtio"
    bridge = var.bridge
  }

  disk {
    slot      = 0
    size      = element(var.disk_sizes, 0)
    type      = "scsi"
    storage   = "local-lvm"  # Storage for the OS disk
  }

  disk {
    slot      = 1
    size      = element(var.disk_sizes, 1)
    type      = "scsi"
    storage   = proxmox_storage.local_ssd.storage  # Reference to local-ssd storage
  }

  os_type     = "cloud-init"
  iso         = "/tmp/ubuntu-22.04-live-server-amd64.iso"  # Reference to the downloaded ISO

  # Define the `cloud-init` configuration for the VM
  ciuser      = var.cloud_user
  cipassword  = var.cloud_password  # Optional: If a password is needed
  sshkeys     = var.ssh_keys  # Cloud-init SSH keys
  
  # Other optional cloud-init settings (unattended upgrades, custom scripts, etc.)
  cicustom = {
    "user_data" = <<-EOF
      #cloud-config
      package_update: true
      packages:
        - git
    EOF
  }
}
