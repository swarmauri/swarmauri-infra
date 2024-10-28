 terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "2.9.11"
    }
  }
}

provider "proxmox" {
  pm_api_url           = var.proxmox_api_url
  pm_api_token_id      = var.proxmox_user
  pm_api_token_secret  = var.proxmox_password
  pm_tls_insecure      = false
  pm_debug             = true
}

# Download the Ubuntu ISO directly into the Proxmox ISO storage directory
resource "null_resource" "download_ubuntu_iso" {
  provisioner "local-exec" {
    command = "sudo curl -L -o /var/lib/vz/template/iso/ubuntu-22.04-live-server-amd64.iso ${var.ubuntu_iso}"
  }
  triggers = {
    ubuntu_iso = var.ubuntu_iso
  }
}



# Step 1: Create the Base VM (used as a template for cloning)
resource "proxmox_vm_qemu" "base_vm" {
  name         = "ubuntu-base-vm"
  target_node  = var.proxmox_node
  cores        = var.cores
  sockets      = var.sockets
  memory       = var.memory
  os_type      = "cloud-init"


  

  # Attach ISO as a CD-ROM
  disk {
    slot      = 2                # Use an available slot for CD-ROM
    storage   = "local"
    type      = "ide"
    iso          = "local:iso/ubuntu-22.04-live-server-amd64.iso"  # Assuming it's in the "local" storage pool
    media     = "cdrom"
    size      = "2G"
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  disk {
    slot      = 0
    size      = var.disk_sizes[0]
    type      = "scsi"
    storage   = "local-lvm"
  }

  disk {
    slot      = 1
    size      = var.disk_sizes[1]
    type      = "scsi"
    storage   = "local"
  }

  # No cloud-init parameters here, only in clones
  provisioner "local-exec" {
    command = "qm stop ${self.id}"
  }
}


# Step 2: Clone the Base VM to Create Additional VMs
resource "proxmox_vm_qemu" "vm" {
  count        = var.vm_count
  name         = "ubuntu-vm-${count.index + 100}"
  target_node  = var.proxmox_node
  clone        = proxmox_vm_qemu.base_vm.id  # Clone from the base VM

  cores        = var.cores
  sockets      = var.sockets
  memory       = var.memory

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  # OS disk (no need to redefine size or storage as it’s inherited from the clone)
  disk {
    slot      = 0
    size      = var.disk_sizes[0]
    type      = "scsi"
    storage   = "local-lvm"
  }

  disk {
    slot      = 1
    size      = var.disk_sizes[1]
    type      = "scsi"
    storage   = "local"
  }

  os_type     = "cloud-init"
  ciuser      = var.cloud_user
  sshkeys     = var.ssh_keys
}
