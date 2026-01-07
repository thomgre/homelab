# Download Talos ISO to all Proxmox nodes
resource "proxmox_virtual_environment_file" "talos_disk" {
  for_each = toset(["proxmox-01", "proxmox-02", "proxmox-03"])
  
  content_type = "iso"
  datastore_id = "local"
  node_name    = each.key

  source_file {
    path = "https://factory.talos.dev/image/dc7b152cb3ea99b821fcb7340ce7168313ce393d663740b791c36f6e95fc8586/v1.9.5/nocloud-amd64.iso"
  }
}

# Generate Talos machine secrets
resource "talos_machine_secrets" "this" {}

# Local configuration patches
locals {
  # Extract IP from cluster endpoint URL
  cluster_endpoint_ip = regex("https://([^:]+):", var.cluster_endpoint)[0]
  controlplane_patch = <<-EOT
machine:
  network:
    nameservers:
      - 8.8.8.8
      - 1.1.1.1
  time:
    servers:
      - time.cloudflare.com
  install:
    disk: /dev/sda
    image: factory.talos.dev/installer/dc7b152cb3ea99b821fcb7340ce7168313ce393d663740b791c36f6e95fc8586:v1.9.5
  registries:
    mirrors:
      docker.io:
        endpoints:
          - https://registry-1.docker.io
      gcr.io:
        endpoints:
          - https://gcr.io
      ghcr.io:
        endpoints:
          - https://ghcr.io
      k8s.gcr.io:
        endpoints:
          - https://registry.k8s.io
      quay.io:
        endpoints:
          - https://quay.io
  kubelet:
    extraArgs: {}

cluster:
  network:
    cni:
      name: none
    podSubnets:
      - 10.244.0.0/16
    serviceSubnets:
      - 10.96.0.0/12
  proxy:
    extraArgs:
      nodeport-addresses: 192.168.1.0/24
  etcd:
    advertisedSubnets:
      - 192.168.1.0/24
  inlineManifests:
    - name: cilium-install
      contents: |
        ---
        apiVersion: rbac.authorization.k8s.io/v1
        kind: ClusterRoleBinding
        metadata:
          name: cilium-install
        roleRef:
          apiGroup: rbac.authorization.k8s.io
          kind: ClusterRole
          name: cluster-admin
        subjects:
        - kind: ServiceAccount
          name: cilium-install
          namespace: kube-system
        ---
        apiVersion: v1
        kind: ServiceAccount
        metadata:
          name: cilium-install
          namespace: kube-system
        ---
        apiVersion: batch/v1
        kind: Job
        metadata:
          name: cilium-install
          namespace: kube-system
        spec:
          backoffLimit: 10
          template:
            metadata:
              labels:
                app: cilium-install
            spec:
              restartPolicy: OnFailure
              tolerations:
                - operator: Exists
                - effect: NoSchedule
                  operator: Exists
                - effect: NoExecute
                  operator: Exists
                - effect: PreferNoSchedule
                  operator: Exists
                - key: node-role.kubernetes.io/control-plane
                  operator: Exists
                  effect: NoSchedule
                - key: node-role.kubernetes.io/control-plane
                  operator: Exists
                  effect: NoExecute
                - key: node-role.kubernetes.io/control-plane
                  operator: Exists
                  effect: PreferNoSchedule
              affinity:
                nodeAffinity:
                  requiredDuringSchedulingIgnoredDuringExecution:
                    nodeSelectorTerms:
                      - matchExpressions:
                          - key: node-role.kubernetes.io/control-plane
                            operator: Exists
              serviceAccount: cilium-install
              serviceAccountName: cilium-install
              hostNetwork: true
              containers:
              - name: cilium-install
                image: quay.io/cilium/cilium-cli:latest
                env:
                - name: KUBERNETES_SERVICE_HOST
                  valueFrom:
                    fieldRef:
                      apiVersion: v1
                      fieldPath: status.podIP
                - name: KUBERNETES_SERVICE_PORT
                  value: "6443"
                command:
                  - cilium
                  - install
                  - --version=1.18.0
                  - --set
                  - ipam.mode=kubernetes
                  - --set
                  - kubeProxyReplacement=false
                  - --set
                  - securityContext.capabilities.ciliumAgent={CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}
                  - --set
                  - securityContext.capabilities.cleanCiliumState={NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}
                  - --set
                  - cgroup.autoMount.enabled=false
                  - --set
                  - cgroup.hostRoot=/sys/fs/cgroup
                  - --set
                  - k8sServiceHost=${local.cluster_endpoint_ip}
                  - --set
                  - k8sServicePort=6443
EOT

  worker_patch = <<-EOT
machine:
  network:
    nameservers:
      - 8.8.8.8
      - 1.1.1.1
  time:
    servers:
      - time.cloudflare.com
  install:
    disk: /dev/sda
    image: factory.talos.dev/installer/dc7b152cb3ea99b821fcb7340ce7168313ce393d663740b791c36f6e95fc8586:v1.9.5
  registries:
    mirrors:
      docker.io:
        endpoints:
          - https://registry-1.docker.io
      gcr.io:
        endpoints:
          - https://gcr.io
      ghcr.io:
        endpoints:
          - https://ghcr.io
      k8s.gcr.io:
        endpoints:
          - https://registry.k8s.io
      quay.io:
        endpoints:
          - https://quay.io
  kubelet:
    extraArgs: {}
EOT
}

# Generate Talos machine configurations
data "talos_machine_configuration" "control_plane" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = var.cluster_endpoint
  machine_type       = "controlplane"
  kubernetes_version = "v1.29.3"
  talos_version      = "v1.9.5"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  
  config_patches = [
    local.controlplane_patch,    
  ]
}

data "talos_machine_configuration" "worker" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = var.cluster_endpoint
  machine_type       = "worker"
  kubernetes_version = "v1.29.3"
  talos_version      = "v1.9.5"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  
  config_patches = [
    local.worker_patch,
    
    yamlencode({
      cluster = {
        network = {
          cni = {
            name = "none"
          }
        },
        proxy = {
          extraArgs = {
            "nodeport-addresses" = "192.168.1.0/24"
          }
        }
      }
    })
  ]
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = [for node in var.controlplane_nodes : node.ip]
  nodes                = [for node in var.controlplane_nodes : node.ip]
}

# Create control plane VMs
resource "proxmox_virtual_environment_vm" "control_plane_nodes" {
  count       = length(var.controlplane_nodes)
  name        = keys(var.controlplane_nodes)[count.index]
  description = "Talos Kubernetes control plane node"
  node_name   = values(var.controlplane_nodes)[count.index].proxmox_node
  vm_id       = values(var.controlplane_nodes)[count.index].vmid

  cpu {
    cores = values(var.controlplane_nodes)[count.index].cores
    type  = "host"
  }
  memory {
    dedicated = values(var.controlplane_nodes)[count.index].memory
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_file.talos_disk[values(var.controlplane_nodes)[count.index].proxmox_node].id
    interface    = "scsi0"
    ssd          = true
    size         = values(var.controlplane_nodes)[count.index].disk
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  agent {
    enabled = true
  }

  initialization {
    datastore_id = "local-lvm"
    ip_config {
      ipv4 {
        address = "${values(var.controlplane_nodes)[count.index].ip}/${var.network_cidr}"
        gateway = var.network_gateway
      }
    }
  }
}

# Create worker VMs
resource "proxmox_virtual_environment_vm" "worker_nodes" {
  count       = length(var.worker_nodes)
  name        = keys(var.worker_nodes)[count.index]
  description = "Talos Kubernetes worker node"
  node_name   = values(var.worker_nodes)[count.index].proxmox_node
  vm_id       = values(var.worker_nodes)[count.index].vmid

  cpu {
    cores = values(var.worker_nodes)[count.index].cores
    type  = "host"
  }
  memory {
    dedicated = values(var.worker_nodes)[count.index].memory
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_file.talos_disk[values(var.worker_nodes)[count.index].proxmox_node].id
    interface    = "scsi0"
    size         = values(var.worker_nodes)[count.index].disk
    ssd          = true
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  agent {
    enabled = true
  }

  initialization {
    datastore_id = "local-lvm"
    ip_config {
      ipv4 {
        address = "${values(var.worker_nodes)[count.index].ip}/${var.network_cidr}"
        gateway = var.network_gateway
      }
    }
  }
}

# Apply configuration to control plane
resource "talos_machine_configuration_apply" "control_plane" {
  depends_on = [
    proxmox_virtual_environment_vm.control_plane_nodes
  ]
  count                = length(var.controlplane_nodes)
  client_configuration = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.control_plane.machine_configuration
  node                 = values(var.controlplane_nodes)[count.index].ip
  
  config_patches = [
    yamlencode({
      machine = {
        network = {
          interfaces = [
            {
              interface = "eth0"
              addresses = ["${values(var.controlplane_nodes)[count.index].ip}/${var.network_cidr}"]
              routes = [
                {
                  network = "0.0.0.0/0"
                  gateway = var.network_gateway
                }
              ]
            }
          ]
          kubespan = {
            enabled = false
          }
        }
        kubelet = {
          extraArgs = {
            "node-ip" = values(var.controlplane_nodes)[count.index].ip
          }
        }
      }
    })
  ]
}

# Apply configuration to workers
resource "talos_machine_configuration_apply" "worker" {
  depends_on = [
    proxmox_virtual_environment_vm.worker_nodes
  ]
  count                = length(var.worker_nodes)
  client_configuration = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  node                 = values(var.worker_nodes)[count.index].ip
  
  config_patches = [
    yamlencode({
      machine = {
        network = {
          interfaces = [
            {
              interface = "eth0"
              addresses = ["${values(var.worker_nodes)[count.index].ip}/${var.network_cidr}"]
              routes = [
                {
                  network = "0.0.0.0/0"
                  gateway = var.network_gateway
                }
              ]
            }
          ]
          kubespan = {
            enabled = false
          }
        }
        kubelet = {
          extraArgs = {
            "node-ip" = values(var.worker_nodes)[count.index].ip
          }
        }
      }
    })
  ]
}

# Bootstrap cluster
resource "talos_machine_bootstrap" "this" {
  depends_on = [
    talos_machine_configuration_apply.control_plane,
    talos_machine_configuration_apply.worker
  ]
  
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = values(var.controlplane_nodes)[0].ip
}

# Generate kubeconfig
resource "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.this
  ]
  
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = values(var.controlplane_nodes)[0].ip
}

# Save talosconfig
resource "local_file" "talosconfig" {
  content  = data.talos_client_configuration.this.talos_config
  filename = "${path.module}/../../talosconfig"
}

# Save kubeconfig
resource "local_file" "kubeconfig" {
  content  = talos_cluster_kubeconfig.this.kubeconfig_raw
  filename = "${path.module}/../../kubeconfig"
}