variable "proxmox_api_url" {
  description = "The API URL for the Proxmox server."
  type        = string
}

variable "proxmox_user" {
  description = "The username for the Proxmox server."
  type        = string
}

variable "proxmox_password" {
  description = "The password for the Proxmox server."
  type        = string
}

variable "proxmox_node" {
  description = "The Proxmox node name."
  type        = string
}

variable "vm_count" {
  description = "The number of VMs to create."
  type        = number
  default     = 3
}

variable "cores" {
  description = "Number of CPU cores for each VM."
  type        = number
  default     = 4
}

variable "memory" {
  description = "Memory in MB for each VM."
  type        = number
  default     = 8192
}

variable "sockets" {
  description = "Number of sockets for each VM."
  type        = number
  default     = 1
}

variable "disk_sizes" {
  description = "List of disk sizes in GB for each VM."
  type        = list(number)
  default     = [50, 100]
}

variable "bridge" {
  description = "The network bridge to use."
  type        = string
}

variable "cloud_user" {
  description = "The cloud-init username for the VMs."
  type        = string
}

variable "cloud_password" {
  description = "The cloud-init password for the VMs."
  type        = string
}

variable "ssh_keys" {
  description = "SSH public key for the VMs."
  type        = string
}

variable "ubuntu_iso" {
  description = "The ISO image to use for the VMs."
  type        = string
}
