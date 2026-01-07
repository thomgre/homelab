terraform {
  required_version = ">= 1.0"
  
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.4"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }
}

# Proxmox Provider
provider "proxmox" {
  endpoint = var.proxmox_api_url
  api_token = "${var.proxmox_user}=${var.proxmox_password}"
  insecure = true
  
  ssh {
    agent    = false
    username = "root"
    password = var.proxmox_ssh_password
  }
}

# Talos Provider
provider "talos" {}

# Note: No Kubernetes or kubectl providers configured.
# Following roeldev/iac-talos-cluster approach: use null_resource with kubectl commands
# to avoid the chicken-and-egg problem of connecting to a cluster that doesn't exist yet.
