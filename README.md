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

## Infra resources

## Workloads

## Considerations

### k3s vs. k8s

### Proxmox vs. Talos vs. Kairos

### Omni

### GitOps decisions
