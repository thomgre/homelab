locals {
  kubeconfig_path = "${path.module}/kubeconfig"
  talosconfig_path = "${path.module}/talosconfig"
}

# Create Talos cluster
module "talos_cluster" {
  source = "./modules/talos-cluster"
  
  cluster_name     = var.cluster_name
  cluster_endpoint = var.cluster_endpoint
  
  controlplane_nodes = var.controlplane_nodes
  worker_nodes       = var.worker_nodes
  talos_template_id  = var.talos_template_id
  talos_iso_file     = var.talos_iso_file
  network_gateway    = var.network_gateway
  network_cidr       = var.network_cidr
  
  allow_workloads_on_controlplane = true
}

# Save configurations locally
resource "local_file" "kubeconfig" {
  content  = module.talos_cluster.kubeconfig
  filename = local.kubeconfig_path
  
  provisioner "local-exec" {
    command = "chmod 600 ${local.kubeconfig_path}"
  }
}

resource "local_file" "talosconfig" {
  content  = module.talos_cluster.talosconfig
  filename = local.talosconfig_path
  
  provisioner "local-exec" {
    command = "chmod 600 ${local.talosconfig_path}"
  }
}

# Wait for cluster nodes to be ready before deploying applications
resource "null_resource" "wait_for_cluster_ready" {
  depends_on = [
    module.talos_cluster.talos_machine_bootstrap,
    local_file.kubeconfig
  ]

  provisioner "local-exec" {
    command = <<EOT
      export KUBECONFIG=${local.kubeconfig_path}
      
      # Wait for API server to respond and nodes to appear
      echo "Waiting for Kubernetes API and nodes..."
      for i in {1..60}; do
        if kubectl get nodes >/dev/null 2>&1; then
          NODE_COUNT=$(kubectl get nodes --no-headers | wc -l)
          echo "Found $NODE_COUNT nodes"
          if [ "$NODE_COUNT" -ge 3 ]; then
            echo "All expected nodes are present!"
            break
          fi
        fi
        echo "Attempt $i: Waiting for all nodes to appear, retrying in 10 seconds..."
        sleep 10
      done
      
      # Now wait for all nodes to be ready
      echo "Waiting for all nodes to be Ready..."
      kubectl wait --for=condition=Ready nodes --all --timeout=600s
      
      echo "Cluster is ready! Node status:"
      kubectl get nodes -o wide
    EOT
  }

  triggers = {
    kubeconfig = local_file.kubeconfig.id
  }
}

# Create ArgoCD namespace
resource "null_resource" "argocd_namespace" {
  depends_on = [null_resource.wait_for_cluster_ready]

  provisioner "local-exec" {
    command = <<EOT
      export KUBECONFIG=${local.kubeconfig_path}
      kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f - --validate=false
    EOT
  }

  triggers = {
    cluster_ready = null_resource.wait_for_cluster_ready.id
  }
}

# Create ArgoCD SSH deploy key secret
resource "null_resource" "argocd_repo_secret" {
  depends_on = [null_resource.argocd_namespace]

  provisioner "local-exec" {
    command = <<EOT
      export KUBECONFIG=${local.kubeconfig_path}
      kubectl create secret generic argocd-repo-secret \
        --from-literal=type=git \
        --from-literal=url=git@github.com:thomgre/homelab.git \
        --from-literal=name=k8s-homelab \
        --from-file=sshPrivateKey=${pathexpand("~/.ssh/argocd_deploy_key")} \
        --namespace=argocd \
        --dry-run=client -o yaml | kubectl apply -f - --validate=false
      
      kubectl label secret argocd-repo-secret argocd.argoproj.io/secret-type=repository -n argocd
    EOT
  }

  triggers = {
    namespace = null_resource.argocd_namespace.id
    key_file = filesha256(pathexpand("~/.ssh/argocd_deploy_key"))
  }
}

# Deploy ArgoCD using kubectl apply
resource "null_resource" "argocd_install" {
  depends_on = [
    null_resource.argocd_namespace,
    null_resource.argocd_repo_secret
  ]

  provisioner "local-exec" {
    command = <<EOT
      export KUBECONFIG=${local.kubeconfig_path}
      kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
      
      # Wait for ArgoCD to be ready
      kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
    EOT
  }

  triggers = {
    namespace = null_resource.argocd_namespace.id
    secret = null_resource.argocd_repo_secret.id
  }
}

# Wait for ArgoCD CRDs to be ready
resource "null_resource" "wait_for_argocd_crds" {
  depends_on = [null_resource.argocd_install]

  provisioner "local-exec" {
    command = <<EOT
      export KUBECONFIG=${local.kubeconfig_path}
      
      # Wait for ApplicationSet CRD to be available
      kubectl wait --for condition=established --timeout=60s crd/applicationsets.argoproj.io
      kubectl wait --for condition=established --timeout=60s crd/applications.argoproj.io
      
      # Wait for ArgoCD server to be ready
      kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
    EOT
  }

  triggers = {
    argocd_install = null_resource.argocd_install.id
  }
}

# Create default AppProject (required for ArgoCD applications)
resource "null_resource" "argocd_default_project" {
  depends_on = [null_resource.wait_for_argocd_crds]
  
  provisioner "local-exec" {
    command = <<EOT
      export KUBECONFIG=${local.kubeconfig_path}
      cat <<YAML | kubectl apply -f - --validate=false
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: default
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  description: Default project
  sourceRepos:
  - '*'
  destinations:
  - namespace: '*'
    server: '*'
  clusterResourceWhitelist:
  - group: '*'
    kind: '*'
  namespaceResourceWhitelist:
  - group: '*'
    kind: '*'
YAML
    EOT
  }

  triggers = {
    crds_ready = null_resource.wait_for_argocd_crds.id
  }
}

# Deploy root ArgoCD application
resource "null_resource" "argocd_root_app" {
  depends_on = [
    null_resource.argocd_default_project,
    null_resource.argocd_repo_secret
  ]
  
  provisioner "local-exec" {
    command = <<EOT
      export KUBECONFIG=${local.kubeconfig_path}
      kubectl apply -f ${path.module}/../bootstrap/root-app.yaml --validate=false
    EOT
  }

  triggers = {
    project = null_resource.argocd_default_project.id
    secret = null_resource.argocd_repo_secret.id
    root_app_file = filesha256("${path.module}/../bootstrap/root-app.yaml")
  }
}

# Get ArgoCD admin password via null_resource
resource "null_resource" "argocd_admin_password" {
  depends_on = [null_resource.argocd_install]
  
  provisioner "local-exec" {
    command = <<EOT
      export KUBECONFIG=${local.kubeconfig_path}
      # Wait for the secret to be available
      kubectl wait --for=condition=complete --timeout=300s job -l app.kubernetes.io/name=argocd-server -n argocd || true
      # The password will be accessible via: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
    EOT
  }

  triggers = {
    argocd_install = null_resource.argocd_install.id
  }
}


