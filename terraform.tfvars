proxmox_api_url    = "https://your-proxmox-url:8006/api2/json"
proxmox_user       = "your-user@pam"
proxmox_password   = "your-password"
proxmox_node       = "proxmox-node-name"
vm_count           = 3
cores              = 4
memory             = 8192
sockets            = 1
disk_sizes         = [50, 100]
bridge             = "vmbr0"
cloud_user         = "ubuntu"
cloud_password     = "your-password"
ssh_keys           = "ssh-rsa your-ssh-key"
ubuntu_iso         = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-live-server-amd64.iso"

