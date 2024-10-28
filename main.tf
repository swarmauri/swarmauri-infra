terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "2.9.11"
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

# Variables
variable "proxmox_api_url" {}
variable "proxmox_user" {}
variable "proxmox_password" {}
variable "proxmox_node" {}
variable "cores" { default = 2 }
variable "sockets" { default = 1 }
variable "memory" { default = 2048 }
variable "disk_sizes" { default = ["10G", "20G"] }
variable "vm_count" { default = 3 }
variable "cloud_user" { default = "ubuntu" }
variable "ssh_keys" {}
variable "ubuntu_iso" {
  default = "https://releases.ubuntu.com/22.04/ubuntu-22.04-live-server-amd64.iso"
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

# Step 2: Create the Base VM (used as a template for cloning)
resource "proxmox_vm_qemu" "base_vm" {
  name         = "ubuntu-base-vm"
  target_node  = var.proxmox_node
  cores        = var.cores
  sockets      = var.sockets
  memory       = var.memory
  os_type      = "cloud-init"

  iso          = "local:iso/ubuntu-22.04-live-server-amd64.iso"  # Assuming it's in the "local" storage pool

  # Attach ISO as a CD-ROM for base installation
  disk {
    slot      = 2
    storage   = "local"
    type      = "ide"
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

  # Stop the base VM after creation for cloning
  provisioner "local-exec" {
    command = "qm stop ${self.id}"
  }
}

# Step 3: Define the Cloud-Init Disk
locals {
  vm_name          = "ubuntu-vm"
  pve_node         = var.proxmox_node
  iso_storage_pool = "local"
}

resource "proxmox_cloud_init_disk" "ci" {
  name      = local.vm_name
  pve_node  = local.pve_node
  storage   = local.iso_storage_pool

  meta_data = yamlencode({
    instance_id    = sha1(local.vm_name)
    local-hostname = local.vm_name
  })

  user_data = <<-EOT
  #cloud-config
  users:
    - default
  ssh_authorized_keys:
    - ${var.ssh_keys}
  EOT

  network_config = yamlencode({
    version = 1
    config = [{
      type = "physical"
      name = "eth0"
      subnets = [{
        type            = "static"
        address         = "192.168.1.100/24"
        gateway         = "192.168.1.1"
        dns_nameservers = [
          "1.1.1.1",
          "8.8.8.8"
        ]
      }]
    }]
  })
}

# Step 4: Clone the Base VM to Create Additional VMs
resource "proxmox_vm_qemu" "vm" {
  count        = var.vm_count
  name         = "ubuntu-vm-${count.index + 100}"
  target_node  = var.proxmox_node
  clone        = proxmox_vm_qemu.base_vm.id  # Clone from the base VM

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

  # OS disk (inherited from the clone)
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

  # Attach the cloud-init disk as a CD-ROM for configuration
  cdrom {
    file = proxmox_cloud_init_disk.ci.id  # Attach the generated cloud-init disk
  }
}
