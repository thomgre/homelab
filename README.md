# 🏠 homelab
Homelab bare metal setup with Talos, Kubernetes and GitOps (ArgoCD)

## Progress

- [x] Get hardware (3 nodes + switch)
- [x] Install Proxmox
- [x] Configure Proxmox basics + Cluster
- [x] Setup Terraform/OpenTofu templates
- [ ] IaC install of VMs and Talos Linux
- [ ] Setup Talos Linux
- [ ] Configure k8s basics
- [ ] Setup and run k8s bootstrap with ArgoCD
- [ ] Configure workloads
- [ ] Deploy workloads

## Hardware overview
1x HP EliteDesk 800 G2 Mini - i3-6100T/ 4GB/ 120GB SSD
1x HP EliteDesk 800 G2 Mini - i3-6100T/ 16GB RAM / 120GB SSD
1x HP EliteDesk 800 G2 Mini - i5-6500/ 8GB RAM / 500GB SSD

![Elitedesks](https://github.com/thomgre/homelab/blob/main/docs/images/elitedesk-cluster.jpeg?raw=true)

At first I will be using one control plane node to have similarity with a production environment and not running workloads on the control plane node. Resource wise it is important for the control plane node to have decent I/O performance for etcd.

To improve this setup I could extend the cluster with 2 more mini PC to have 5 nodes in total: 3 control plane nodes for high availability and 2 worker nodes. The odd number of control plane nodes prevents split-brain scenarios and provides fault tolerance.

![Homelab rack](https://github.com/thomgre/homelab/blob/main/docs/images/rack.jpeg?raw=true)

### Cost breakdown
|   |   |   |
|---|---|---|
| HP EliteDesk i3 4GB |   | €99  |
| HP EliteDesk i3 16GB |   | €166  |
| HP EliteDesk i5 8GB |   | €85  | 
| ~~GeekPi 8U Server Cabinet 10"~~ | | ~~€169.99~~ |
| ~~GeekPi 12 Port Patch Panel~~ | | ~~€25.99~~ |
| ~~GeekPi 10" 1U Server Rack Shelf (2PCS)~~ | | ~~€45.99~~ |
| ~~GeekPi DC PDU 0.5U 7 Sockets~~ | | ~~€59.99~~ |
| Lanberg 9U 10" rack | | €46 | 
| DIGITUS 4-way power strip 1U | | €16.99 |
| DIGITUS Shelf 1U | | €15.13 |
| DIGITUS Shelf 1U | | €15.13 |
| DIGITUS Shelf 1U | | €15.13 |
| MikroTik hEX S E60iUGS A | | €73.76 |
| HPE Aruba Instand On 1430 5G Switch | | €31.97 |
| | | |
| **TOTAL** | | €554.11 |

## Infrastructure

## Proxmox
Installed Proxmox on all 3 nodes using [Ventoy](https://www.ventoy.net/en/index.html) and a USB drive. On the HP Elitedesk GP Minis make sure to setup the BIOS with Legacy boot enabled and secure boot disabled. Also make sure to enable "Virtualization Technology" (if you forget you also get a warning about KVM on the Proxmox installer).

After installation succeeded and a reboot, run the [PVE Post Install Script](https://community-scripts.github.io/ProxmoxVE/scripts?id=post-pve-install) to configure some basics, like adding the No-Subscription repository and updating Proxmox.

### Configure Wake-on LAN
`sudo apt update`
`sudo apt install ethtool`

```
# /etc/network/interfaces

auto lo
iface lo inet loopback

iface eno1 inet manual
    postup ethtool -s eno1 wol d # <-- add this
auto vmbr0

interface vmbr0 inet static
    address <node-ip>/24
    gateway <gateway-ip>
    bridge-ports eno1
    bridge-stp off
    bridge-fd 0
    postup ethtool -s eno1 wol d # <-- add this

source /etc/network/interfaces.d/*
```

## Kubernetes bootstrap
### Overview
- Proxmox Node 1: 1 control plane + 2 workers
- Proxmox Node 2: 1 control plane + 2 workers
- Proxmox Node 3: 1 control plane + 2 workers

### ArgoCD

### Infra resources

### Workloads

## Considerations

### Proxmox, Talos and Kairos
Proxmox:

[Talos Linux](https://talos.dev/):

[Kairos](https://kairos.io/):

### k3s vs. k8s
This is not really a fair comparison since both have their place and use. I'm using my Homelab to learn and experiment with Kubernetes so therefor chose to use...suprise.. Kubernetes. K3s is really nice though for IoT and Edge computing use cases due to its low(er) resource use and simplicity while maintaining full Kubernetes API compatibility. Will be looking into k3s more in the future.

### Proxmox vs. Talos vs. Kairos

### Omni

### GitOps decisions
I've decided to use ArgoCD because of its user friendly UI, demand in my local market and the ability to get ArgoCD certifications. Flux is also interesting though due to its modular architecture and the more lightweight, Kubernetes native approach.

### Secret management
