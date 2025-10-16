# 🏠 homelab
Homelab bare metal setup with Talos, Kubernetes and GitOps (ArgoCD)

## Hardware overview
**Control plane**
1x HP EliteDesk 800 G2 Mini - i3-6100T/ 4GB/ 120GB SSD

**Worker nodes**
1x HP EliteDesk 800 G2 Mini - i3-6100T/ 16GB RAM / 120GB SSD
1x HP EliteDesk 800 G2 Mini - i5-6500/ 8GB RAM / 500GB SSD

At first I will be using one control plane node to have similarity with a production environment and not running workloads on the control plane node. Resource wise it is important for the control plane node to have decent I/O performance for etcd.

To improve this setup I could extend the cluster with 2 more mini PC to have 5 nodes in total: 3 control plane nodes for high availability and 2 worker nodes. The odd number of control plane nodes prevents split-brain scenarios and provides fault tolerance.

### Cost breakdown
|   |   |   |
|---|---|---|
| HP EliteDesk i3 4GB |   | €99,-  |
| HP EliteDesk i3 16GB |   | €166,-  |
| HP EliteDesk i5 8GB |   | €85,-  | 
| GeekPi 8U Server Cabinet 10" | | €169.99 |
| GeekPi 12 Port Patch Panel | | €25.99 |
| GeekPi 10" 1U Server Rack Shelf (2PCS) | | €45.99 |
| GeekPi DC PDU 0.5U 7 Sockets| | €59.99 |
| MikroTik hEX S E60iUGS A | | €73.76 |
| | | |
| **TOTAL** | | €725,72 |

## Infrastructure

## Kubernetes bootstrap

## Infra applications

## Workload applications

## Considerations

### Proxmox, Talos and Kairos
Proxmox:

[Talos Linux](https://talos.dev/):

[Kairos](https://kairos.io/):

### k3s vs. k8s
This is not really a comparison since both have their place and use. I'm using my Homelab to learn and experiment with Kubernetes so therefor chose to use...suprise.. Kubernetes. K3s is really nice though for IoT and Edge computing use cases due to its low(er) resource use and simplicity while maintaining full Kubernetes API compatibility. Will be looking into k3s more in the future.

### GitOps decisions
I've decided to use ArgoCD because of its user friendly UI, demand in my local market and the ability to get ArgoCD certifications. Flux is also interesting though due to its modular architecture and the more lightweight, Kubernetes native approach.

### Secret management
