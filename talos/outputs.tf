output "cluster_info" {
  description = "Cluster connection information"
  value = {
    endpoint = var.cluster_endpoint
    controlplane_ips = module.talos_cluster.controlplane_ips
    worker_ips = module.talos_cluster.worker_ips
  }
}


output "kubeconfig_location" {
  description = "Location of kubeconfig file"
  value = local.kubeconfig_path
}

output "talosconfig_location" {
  description = "Location of talosconfig file"
  value = local.talosconfig_path
}

output "argocd_admin_password_command" {
  description = "Command to get ArgoCD admin password"
  value = "KUBECONFIG=${local.kubeconfig_path} kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}

output "argocd_access_info" {
  description = "ArgoCD access information"
  value = {
    url = "https://argocd.local (once nginx-ingress is deployed)"
    username = "admin"
    password_command = "KUBECONFIG=./kubeconfig kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
  }
}
