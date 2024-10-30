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

/* Uses Cloud-Init options from Proxmox 5.2 */
resource "proxmox_vm_qemu" "cloudinit-test" {
  name        = "ubt-01"
  desc        = "tf description"
  target_node = var.proxmox_node

  clone = "ci-ubuntu-template"

  # The destination resource pool for the new VM
  pool = "pool0"
  cores   = 3
  sockets = 1
  memory  = 2560

  ssh_user        = "root"
  ssh_private_key = <<EOF
-----BEGIN RSA PRIVATE KEY-----
private ssh key root
-----END RSA PRIVATE KEY-----
EOF

  os_type   = "cloud-init"
  ipconfig0 = "ip=10.0.2.99/16,gw=10.0.2.2"

  sshkeys = <<EOF
ssh-rsa AABB3NzaC1kj...key1
ssh-rsa AABB3NzaC1kj...key2
EOF

  provisioner "remote-exec" {
    inline = [
      "ip a"
    ]
  }
}

# Modify path for templatefile and use the recommended extension of .tftpl for syntax hylighting in code editors.
resource "local_file" "cloud_init_user_data_file" {
  count    = var.vm_count
  content  = "content"
  filename = "test-filename.cfg"
}

resource "null_resource" "cloud_init_config_files" {
  count = var.vm_count
  connection {
    type     = "ssh"
    user     = "${var.pve_user}"
    password = "${var.pve_password}"
    host     = "${var.proxmox_node}-${count}"
  }

  provisioner "file" {
    source      = local_file.cloud_init_user_data_file[count.index].filename
    destination = "/var/lib/vz/snippets/user_data_vm-${count.index}.yml"
  }
}



/* Uses custom eth1 user-net SSH portforward */
resource "proxmox_vm_qemu" "preprovision-test" {
  name        = "ppt-test"
  desc        = "tf description"
  target_node = var.proxmox_node

  clone = "terraform-ubuntu1404-template"

  # The destination resource pool for the new VM
  pool = "pool0"

  cores    = var.cores
  sockets  = var.sockets
  # Same CPU as the Physical host, possible to add cpu flags
  # Ex: "host,flags=+md-clear;+pcid;+spec-ctrl;+ssbd;+pdpe1gb"
  cpu      = "host"
  numa     = false
  memory   = 2560
  scsihw   = "lsi"
  # Boot from hard disk (c), CD-ROM (d), network (n)
  boot     = "cdn"
  # It's possible to add this type of material and use it directly
  # Possible values are: network,disk,cpu,memory,usb
  hotplug  = "network,disk,usb"
  # Default boot disk
  bootdisk = "virtio0"
  # HA, you need to use a shared disk for this feature (ex: rbd)
  hastate  = ""

  #Display
  vga {
    type   = "std"
    #Between 4 and 512, ignored if type is defined to serial
    memory = 4
  }

  network {
    model = "virtio"
  }
  network {
    model  = "virtio"
    bridge = "vmbr1"
  }
  disk {
    slot         = "scsi0"
    type         = "disk"
    storage      = "local-lvm"
    size         = "4G"
    backup       = true
  }
  # Serial interface of type socket is used by xterm.js
  # You will need to configure your guest system before being able to use it
  serial {
    id   = 0
    type = "socket"
  }
  ssh_forward_ip  = "10.0.0.1"
  ssh_user        = "terraform"
  ssh_private_key = <<EOF
-----BEGIN RSA PRIVATE KEY-----
private ssh key terraform
-----END RSA PRIVATE KEY-----
EOF

  os_type           = "ubuntu"
  os_network_config = <<EOF
auto eth0
iface eth0 inet dhcp
EOF

  connection {
    type        = "ssh"
    user        = self.ssh_user
    private_key = self.ssh_private_key
    host        = self.ssh_host
    port        = self.ssh_port
  }

  provisioner "remote-exec" {
    inline = [
      "ip a"
    ]
  }
}
