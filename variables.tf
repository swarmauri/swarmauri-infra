variable "proxmox_api_url" {
  description = "The API URL for Proxmox."
  type        = string
}

variable "proxmox_user" {
  description = "The username for Proxmox."
  type        = string
}

variable "proxmox_password" {
  description = "The password for Proxmox."
  type        = string
}

variable "proxmox_node" {
  description = "The name of the Proxmox node."
  type        = string
}

variable "vm_count" {
  description = "The number of VMs to create."
  type        = number
}

variable "cores" {
  description = "Number of CPU cores for each VM."
  type        = number
}

variable "memory" {
  description = "Memory in MB for each VM."
  type        = number
}

variable "sockets" {
  description = "Number of sockets for each VM."
  type        = number
}

variable "disk_sizes" {
  description = "List of disk sizes in GB for each VM."
  type        = list(number)
}

variable "bridge" {
  description = "The network bridge for VMs."
  type        = string
}

variable "cloud_user" {
  description = "The username for the cloud-init user."
  type        = string
}

variable "ssh_keys" {
  description = "SSH public key for cloud-init user."
  type        = string
}

variable "ubuntu_iso" {
  description = "The link to the Ubuntu ISO."
  type        = string
}
