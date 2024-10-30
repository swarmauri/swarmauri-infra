resource "null_resource" "download_iso" {
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      host     = var.proxmox_ip
      user     = var.proxmox_user
      password = var.proxmox_password  # Use password instead of private_key
    }
    inline = [
      "wget ${var.iso_url} -O ${var.iso_path} -v"
    ]
  }
}

resource "null_resource" "create_template" {
  depends_on = [null_resource.download_iso]

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      host     = var.proxmox_ip
      user     = var.proxmox_user
      password = var.proxmox_password
    }
    inline = [
      "qm create ${var.template_id} --memory 4096 --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-pci --name template-cloud-init",
      "qm importdisk ${var.template_id} ${var.iso_path} local-lvm",
      "qm set ${var.template_id} --scsi0 local-lvm:vm-${var.template_id}-disk-0",
      "qm set ${var.template_id} --cores 4 --cpu host",
      "qm set ${var.template_id} --ide2 local-back:cloudinit",
      "qm set ${var.template_id} --boot order=scsi0",
      "qm set ${var.template_id} --serial0 socket",  # Serial for cloud-init
      "qm set ${var.template_id} --vga std",         # Set VGA type to std for GUI boot
      "qm set ${var.template_id} --cicustom 'user=local-back:snippets/template-cloud-init.yml'",
      "qm template ${var.template_id}"
    ]
  }
}


resource "null_resource" "create_vms" {
  depends_on = [null_resource.create_template]

  count = var.vm_count

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      host     = var.proxmox_ip
      user     = var.proxmox_user
      password = var.proxmox_password  # Use password instead of private_key
    }
    inline = [
      "CLONE_ID=${var.template_id}",
      "VM_ID=${var.vm_ids[count.index]}",
      "IP=${var.ips[count.index]}",
      "GW=${var.gateways[count.index]}",
      
      # Clone the VM from template
      "qm clone \"$CLONE_ID\" \"$VM_ID\" --name ${var.vm_names[count.index]}",
      
      # Configure the new VM
      "qm set \"$VM_ID\" --numa 1 --hotplug=memory,cpu,disk,usb,network --onboot 1 --agent 1",
      "qm set \"$VM_ID\" --ipconfig0 ip=\"$IP\",gw=\"$GW\" --nameserver 8.8.4.4",
      "qm set \"$VM_ID\" --sshkeys ${var.ssh_public_key_path}",
      
      # Resize the disk for the new VM
      "qm resize \"$VM_ID\" scsi0 30G",
      "qm resize \"$VM_ID\" scsi1 30G",
      
      # Start the VM
      "qm start \"$VM_ID\""
    ]
  }
}
