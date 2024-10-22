terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "2.9.11" # Ensure this is the latest stable version
    }
  }
}

provider "proxmox" {
  pm_api_url    = var.proxmox_api_url
  pm_user       = var.proxmox_user
  pm_password   = var.proxmox_password
  pm_node       = var.proxmox_node
}

resource "proxmox_vm_qemu" "ubuntu_vm" {
  count          = var.vm_count
  name           = "ubuntu-vm-${count.index + 100}"
  cores          = var.cores
  memory         = var.memory
  sockets        = var.sockets

  network_interface {
    model = "virtio"
    bridge = var.bridge
  }

  disk {
    size = "${element(var.disk_sizes, 0)}G"
    type = "scsi"
    storage = "local-lvm" # Replace with your storage name
  }

  disk {
    size = "${element(var.disk_sizes, 1)}G"
    type = "scsi"
    storage = "local-lvm" # Replace with your storage name
  }

  os_type = "cloud-init"
  iso = var.ubuntu_iso

  cloud_init {
    user = var.cloud_user
    password = var.cloud_password
    ssh_keys = [var.ssh_keys]
  }
}
