output "kubeconfig" {
  description = "Kubernetes configuration"
  value       = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive   = true
}

output "talosconfig" {
  description = "Talos configuration"
  value       = yamlencode(talos_machine_secrets.this.client_configuration)
  sensitive   = true
}

output "controlplane_ips" {
  description = "Control plane node IPs"
  value       = [for node in var.controlplane_nodes : node.ip]
}

output "worker_ips" {
  description = "Worker node IPs"
  value       = [for node in var.worker_nodes : node.ip]
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint"
  value       = var.cluster_endpoint
}
