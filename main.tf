terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.1-rc4"  # Ensure compatibility with your setup
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_user
  pm_api_token_secret = var.proxmox_password
  pm_tls_insecure     = false
  pm_debug            = true
}



# Step 1: Download the Ubuntu ISO
resource "null_resource" "download_ubuntu_iso" {
  provisioner "local-exec" {
    command = "sudo curl -L -o /var/lib/vz/template/iso/ubuntu-22.04-live-server-amd64.iso ${var.ubuntu_iso}"
  }
  triggers = {
    ubuntu_iso = var.ubuntu_iso
  }
}

# Step 2: Create the Base VM Template
resource "proxmox_vm_qemu" "base_vm" {
  name         = "ubuntu-base-vm"
  target_node  = var.proxmox_node
  cores        = var.cores
  sockets      = var.sockets
  memory       = var.memory
  os_type      = "cloud-init"

  # Attach ISO as a CD-ROM for base installation
  disks {
    ide {
      ide2 {
        cdrom {
          iso = "local:iso/ubuntu-22.04-live-server-amd64.iso"
        }
      }
    }
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  disks {
    scsi {
      scsi0 {
        size    = var.disk_sizes[0]
        storage = "local-lvm"
      }
      scsi1 {
        size    = var.disk_sizes[1]
        storage = "local"
      }
    }
  }

  provisioner "local-exec" {
    command = "qm stop ${self.id}"
  }
}

# Step 3: Clone the Base VM with Cloud-Init Disk
resource "proxmox_vm_qemu" "vm" {
  count        = var.vm_count
  name         = "ubuntu-vm-${count.index + 100}"
  target_node  = var.proxmox_node
  clone        = proxmox_vm_qemu.base_vm.id

  cores        = var.cores
  sockets      = var.sockets
  memory       = var.memory
  os_type      = "cloud-init"
  ciuser       = var.cloud_user
  sshkeys      = var.ssh_keys

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  # Attach a Cloud-Init disk as a CD-ROM
  disks {
    scsi {
      scsi0 {
        cdrom {
          iso = "local:cloudinit"
        }
      }
    }
  }

  # Set static IP and gateway through cloud-init IP configuration
  ipconfig0 = "ip=192.168.1.${100 + count.index}/24,gw=192.168.1.1"

  disks {
    scsi {
      scsi1 {
        size    = var.disk_sizes[0]
        storage = "local-lvm"
      }
      scsi2 {
        size    = var.disk_sizes[1]
        storage = "local"
      }
    }
  }
}
