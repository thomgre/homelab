variable "cluster_name" {
  description = "Name of the Talos cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "Kubernetes API endpoint"
  type        = string
}

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

variable "network_gateway" {
  description = "Network gateway"
  type        = string
}

variable "network_cidr" {
  description = "Network CIDR"
  type        = string
}

variable "allow_workloads_on_controlplane" {
  description = "Allow workloads on control plane nodes"
  type        = bool
  default     = true
}
