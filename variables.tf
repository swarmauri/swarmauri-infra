variable "proxmox_ip" {
  description = "Proxmox server IP address"
}

variable "proxmox_user" {
  description = "Proxmox user with SSH access"
}

variable "proxmox_password" {
  description = "Password for Proxmox user SSH access"
  sensitive   = true
}


variable "iso_url" {
  default     = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  description = "URL of the Ubuntu cloud image ISO"
}

variable "iso_path" {
  default     = "/mnt/pve/local-ssd/template/iso/jammy-server-cloudimg-amd64.qcow2"
  description = "Path where the ISO will be stored on the Proxmox server"
}

variable "template_id" {
  default     = 9001
  description = "ID for the template VM"
}

variable "vm_count" {
  default     = 4
  description = "Number of VMs to create from the template"
}

variable "vm_ids" {
  type        = list(number)
  default     = [100, 101, 102, 103]
  description = "List of unique VM IDs for each VM clone"
}

variable "vm_names" {
  type        = list(string)
  default     = ["stybk", "clsrm", "btnt", "rgplt"]
  description = "List of VM names for each clone"
}

variable "ips" {
  type        = list(string)
  default     = ["149.255.38.123/28", "149.255.38.124/28", "149.255.38.125/28", "149.255.38.126/28"]
  description = "List of unique IP addresses for each VM"
}

variable "gateways" {
  type        = list(string)
  default     = ["172.81.41.129", "172.81.41.129", "172.81.41.129", "172.81.41.129"]
  description = "List of gateways for each VM"
}

variable "ssh_public_key_path" {
  default     = "/mnt/pve/local-ssd/private/cobycloud.pub"
  description = "Path to the SSH public key"
}
