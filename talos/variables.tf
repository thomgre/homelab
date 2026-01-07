# Proxmox Configuration
variable "proxmox_api_url" {
  description = "Proxmox API URL (main cluster node)"
  type        = string
}

variable "proxmox_user" {
  description = "Proxmox username"
  type        = string
}

variable "proxmox_password" {
  description = "Proxmox password"
  type        = string
  sensitive   = true
}

variable "proxmox_ssh_password" {
  description = "Proxmox SSH root password"
  type        = string
  sensitive   = true
}

# Cluster Configuration
variable "cluster_name" {
  description = "Name of the Talos cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "Kubernetes API endpoint"
  type        = string
}

# Node Configuration
variable "controlplane_nodes" {
  description = "Control plane node configuration"
  type = map(object({
    ip           = string
    cores        = number
    memory       = number
    disk         = number
    vmid         = number
    proxmox_node = string
  }))
}

variable "worker_nodes" {
  description = "Worker node configuration"
  type = map(object({
    ip           = string
    cores        = number
    memory       = number
    disk         = number
    vmid         = number
    proxmox_node = string
  }))
}

# Network Configuration
variable "network_gateway" {
  description = "Network gateway"
  type        = string
}

variable "network_cidr" {
  description = "Network CIDR"
  type        = string
}

# Template Configuration
variable "talos_template_id" {
  description = "Talos VM template ID for cloning (optional - will create from ISO if not provided)"
  type        = number
  default     = null
}

variable "talos_iso_file" {
  description = "Talos ISO file path in Proxmox storage (used when not cloning)"
  type        = string
  default     = "local:iso/metal-amd64.iso"
}

