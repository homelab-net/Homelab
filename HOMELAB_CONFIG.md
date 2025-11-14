# Homelab Configuration & Reference

**Last Updated:** 2025-11-14
**Hardware:** Small Workstation (16GB RAM, 500GB Storage)
**Hypervisor:** Proxmox VE
**Owner:** [Your Name]

---

## Table of Contents
- [Hardware Specifications](#hardware-specifications)
- [Network Layout](#network-layout)
- [VM Inventory](#vm-inventory)
- [Container/Service Inventory](#containerservice-inventory)
- [Credentials & Access](#credentials--access)
- [Phased Roadmap (16GB Adapted)](#phased-roadmap-16gb-adapted)
- [Future Expansion Plans](#future-expansion-plans)

---

## Hardware Specifications

### Proxmox Host
| Component | Specification |
|-----------|---------------|
| CPU | [TODO: Add CPU model] |
| RAM | 16 GB |
| Storage | 500 GB |
| Network | [TODO: Add NIC details] |
| IP Address | [TODO: Add Proxmox IP] |

**Resource Allocation Strategy:**
- Proxmox Host overhead: ~2GB RAM
- Available for VMs: ~14GB RAM
- Reserve 20-30GB for Proxmox root

---

## Network Layout

### IP Addressing Scheme
| Network | CIDR | Purpose | VLAN |
|---------|------|---------|------|
| Management | [TODO: e.g., 192.168.1.0/24] | Proxmox, admin access | - |
| Services | [TODO: e.g., 192.168.10.0/24] | VM/container services | [TODO] |
| WireGuard VPN | [TODO: e.g., 10.8.0.0/24] | Remote access | - |

### Static IP Assignments
| Hostname | IP Address | Service/Purpose | Notes |
|----------|------------|-----------------|-------|
| proxmox-host | [TODO] | Proxmox VE host | Web UI: https://IP:8006 |
| dns-vm | [TODO] | Technitium DNS | - |
| docker-host | [TODO] | Docker container host | - |
| wireguard | [TODO] | VPN endpoint | - |

### DNS Configuration
| Record Type | Name | Target | Purpose |
|-------------|------|--------|---------|
| A | proxmox.local | [Proxmox IP] | Proxmox web interface |
| A | docker.local | [Docker host IP] | Docker host |
| A | dns.local | [DNS VM IP] | DNS server |
| A | traefik.local | [Docker host IP] | Traefik dashboard |
| A | portainer.local | [Docker host IP] | Portainer UI |

---

## VM Inventory

### Active VMs
| VM ID | Name | OS | vCPU | RAM | Disk | IP | Purpose | Status |
|-------|------|----|----- |-----|------|-------|---------|--------|
| 100 | dns-vm | [TODO: e.g., Ubuntu 22.04] | 1 | 2GB | 20GB | [TODO] | Technitium DNS + WireGuard | Planned |
| 101 | docker-host | [TODO: e.g., Ubuntu 22.04] | 4 | 10GB | 100GB | [TODO] | Docker container runtime | Planned |

**Total Allocated:** 6 vCPU, 12GB RAM, 120GB Disk

---

## Container/Service Inventory

### Docker Services (on docker-host VM)

#### Phase 1: Core Infrastructure
| Container | Image | Port(s) | URL | Purpose | Status |
|-----------|-------|---------|-----|---------|--------|
| traefik | traefik:latest | 80, 443, 8080 | https://traefik.local | Reverse proxy | Planned |
| portainer | portainer/portainer-ce | 9000 | https://portainer.local | Docker management UI | Planned |

#### Phase 2: Monitoring (Lightweight)
| Container | Image | Port(s) | URL | Purpose | Status |
|-----------|-------|---------|-----|---------|--------|
| uptime-kuma | louislam/uptime-kuma | 3001 | https://uptime.local | Service monitoring | Planned |

#### Phase 3: Optional Services
| Container | Image | Port(s) | URL | Purpose | Status |
|-----------|-------|---------|-----|---------|--------|
| homepage | ghcr.io/gethomepage/homepage | 3000 | https://home.local | Dashboard | Optional |
| nginx | nginx:alpine | 8080 | https://www.local | Web server | Optional |

---

## Credentials & Access

### Proxmox Host
| Service | Username | Password Location | Access URL | Notes |
|---------|----------|-------------------|------------|-------|
| Proxmox Web UI | root | [TODO: Password manager] | https://[PROXMOX-IP]:8006 | - |
| SSH | root | SSH key in ~/.ssh/ | ssh root@[PROXMOX-IP] | - |

### Virtual Machines
| VM | Username | Password/Key Location | SSH Access | Notes |
|----|----------|----------------------|------------|-------|
| dns-vm | [TODO] | [TODO] | ssh user@[DNS-IP] | - |
| docker-host | [TODO] | [TODO] | ssh user@[DOCKER-IP] | - |

### Docker Services
| Service | Username | Password Location | Access URL | Notes |
|---------|----------|-------------------|------------|-------|
| Portainer | admin | [TODO: Set on first login] | https://portainer.local | - |
| Traefik Dashboard | - | BasicAuth in config | https://traefik.local | - |

### WireGuard VPN
| Peer Name | Public Key | Allowed IPs | Config File | Notes |
|-----------|------------|-------------|-------------|-------|
| laptop | [TODO] | 10.8.0.2/32 | ~/wireguard/laptop.conf | - |
| phone | [TODO] | 10.8.0.3/32 | ~/wireguard/phone.conf | - |

---

## Phased Roadmap (16GB Adapted)

This roadmap is adapted from the full v2.3 roadmap to fit 16GB RAM constraints.

### ✅ Phase 0: Foundation (CURRENT)
- [x] Proxmox installed on bare metal
- [ ] Basic network configuration
- [ ] Update and secure Proxmox host

### 🔨 Phase 1: Core Infrastructure (START HERE)
**Goal:** Get basic VMs running with proper resource allocation

**Steps:**
1. Create `dns-vm` (Ubuntu Server 22.04)
   - 1 vCPU, 2GB RAM, 20GB disk
   - Static IP assignment
   - Install Technitium DNS
   - Configure as primary DNS for homelab

2. Create `docker-host` (Ubuntu Server 22.04)
   - 4 vCPU, 10GB RAM, 100GB disk
   - Static IP assignment
   - Install Docker & Docker Compose
   - Configure Docker logging (limit log sizes)

**Success Criteria:**
- Both VMs boot and are accessible via SSH
- VMs can reach internet and each other
- Docker installed and functional

---

### 📡 Phase 2: Networking & DNS
**Goal:** Proper DNS resolution and secure remote access

**Steps:**
1. Configure Technitium DNS
   - Set up local DNS zones (*.local)
   - Configure forwarding to upstream DNS (1.1.1.1, 8.8.8.8)
   - Point Proxmox and VMs to use Technitium DNS
   - Create A records for all planned services

2. Install WireGuard VPN (on dns-vm or dedicated container)
   - Generate server and client keys
   - Configure peer access
   - Test remote connectivity
   - Document client configurations

**Success Criteria:**
- All hostnames resolve via local DNS
- Can access homelab remotely via WireGuard
- DNS queries logged and working

---

### 🐳 Phase 3: Core Docker Services
**Goal:** Reverse proxy and container management

**Steps:**
1. Deploy Traefik
   - Docker Compose configuration
   - SSL certificate setup (self-signed or Let's Encrypt)
   - Dashboard access
   - Docker provider configuration

2. Deploy Portainer
   - Behind Traefik reverse proxy
   - Persistent volume for data
   - Configure Docker endpoint
   - Explore stacks and templates

3. (Optional) Deploy Homepage/Dashy
   - Centralized dashboard
   - Links to all services
   - Status indicators

**Success Criteria:**
- Access services via https://service.local URLs
- Portainer manages all containers
- No port conflicts

---

### 📊 Phase 4: Basic Monitoring (Lightweight)
**Goal:** Know when things break

**Option A: Uptime Kuma (Recommended for 16GB)**
- Simple, lightweight monitoring
- Status page and alerts
- Minimal resource usage (~100MB RAM)

**Option B: Prometheus + Grafana (If resources allow)**
- Deploy Prometheus (limit retention to 3 days)
- Deploy Grafana
- Skip Loki/Promtail (too heavy)
- Basic node_exporter on VMs

**Success Criteria:**
- Dashboard shows service status
- Alerts configured (email or webhook)
- Historical uptime data visible

---

### 🔒 Phase 5: Hardening & Backups
**Goal:** Don't lose everything

**Steps:**
1. Implement backup strategy
   - Proxmox VM backups to external USB or NFS
   - Docker volume backups (scripted)
   - Configuration file versioning (git)

2. Security hardening
   - Firewall rules on Proxmox
   - VM firewall configurations
   - Fail2ban on SSH endpoints
   - Regular update schedule

3. Documentation
   - Update this document with all changes
   - Create runbooks for common tasks
   - Document disaster recovery procedures

**Success Criteria:**
- Automated nightly backups running
- Can restore a VM from backup
- All credentials documented securely

---

### 🚀 Phase 6: Expansion Services (Optional)
**Choose what interests you - only add if resources allow:**

- **Media Server:** Plex/Jellyfin (4-6GB RAM)
- **File Sync:** Nextcloud (2-4GB RAM)
- **Git Server:** Gitea (512MB RAM)
- **Wiki:** WikiJS or BookStack (512MB RAM)
- **Password Manager:** Vaultwarden (lightweight)
- **RSS Reader:** FreshRSS
- **Home Automation:** Home Assistant (if you have smart devices)

**Resource Budget:** You'll have ~2-3GB RAM remaining for add-ons

---

## Future Expansion Plans

### When You Upgrade to 32GB RAM:
- Add Proxmox Backup Server (dedicated VM)
- Full observability stack (Prometheus + Grafana + Loki)
- Media server (Plex/Jellyfin)
- Additional services from Phase 6

### When You Upgrade to 64GB+ RAM:
- Consider the full v2.3 roadmap features:
  - Voice services (STT/TTS)
  - n8n automation workflows
  - RAG with Qdrant
  - Multiple Docker hosts (clustering)

### Storage Expansion:
- Add NAS for media/backup storage
- ZFS or Ceph for redundancy
- Separate storage VM with PCIe passthrough

### Network Expansion:
- VLAN segmentation (IoT, services, management)
- Dual DNS for redundancy
- OPNsense/pfSense VM for advanced routing

---

## Notes & Lessons Learned

### Tips:
- Always set resource limits on Docker containers
- Use Docker Compose for everything (easier to manage)
- Keep this document updated after every change
- Test backups regularly
- Document before you forget

### Common Issues:
| Issue | Solution | Date Encountered |
|-------|----------|------------------|
| [TODO: Add as you encounter problems] | | |

---

## Quick Reference Commands

### Proxmox
```bash
# List VMs
qm list

# Start VM
qm start <vmid>

# Stop VM
qm stop <vmid>

# VM console
qm terminal <vmid>

# Check storage
pvesm status
```

### Docker (on docker-host)
```bash
# View all containers
docker ps -a

# View logs
docker logs -f <container>

# Restart container
docker restart <container>

# Docker Compose
docker compose up -d
docker compose down
docker compose logs -f
```

### WireGuard
```bash
# Check status
wg show

# Restart WireGuard
systemctl restart wg-quick@wg0
```

---

## File Locations & Backups

### Configuration Files
| Config | Location | Backup Frequency | Notes |
|--------|----------|------------------|-------|
| This document | /home/user/Homelab/HOMELAB_CONFIG.md | On every commit | Version controlled |
| Docker Compose files | /home/user/docker-compose/ | Daily | - |
| WireGuard configs | /etc/wireguard/ | On creation | - |
| Traefik config | /home/user/docker-compose/traefik/ | Daily | - |

### Backup Locations
| Backup Type | Source | Destination | Schedule | Retention |
|-------------|--------|-------------|----------|-----------|
| Proxmox VMs | Proxmox host | [TODO: NFS/USB] | Weekly | 4 weeks |
| Docker volumes | docker-host | [TODO] | Daily | 7 days |
| Configs | All hosts | Git repository | On change | Indefinite |

---

## Change Log

| Date | Change | Modified By |
|------|--------|-------------|
| 2025-11-14 | Initial document creation, 16GB roadmap adaptation | Claude |
| | | |

---

**Remember:** This is a living document. Update it whenever you:
- Add/remove VMs or containers
- Change IP addresses or network configuration
- Update credentials or access methods
- Complete a roadmap phase
- Learn something important

Keep this document in sync with reality, and it will be invaluable for troubleshooting and future development!
