# Homelab Configuration & Reference

**Last Updated:** 2025-11-14
**Hardware:** KAMRUI Essenx E2 N150 Mini PC (16GB DDR4, 512GB SSD)
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
| Model | KAMRUI Essenx E2 N150 Mini PC |
| CPU | Intel Twin Lake-N N150 (4C/4T, up to 3.6GHz) |
| RAM | 16 GB DDR4 |
| Storage | 512 GB SSD |
| Network | Gigabit Ethernet + WiFi + Bluetooth |
| Display | HDMI + DP1.4 (Dual 4K UHD support) |
| IP Address | [TODO: Add Proxmox IP] |

**Resource Allocation Strategy:**
- Proxmox Host overhead: ~2GB RAM
- Available for VMs: ~14GB RAM
- Reserve 30GB for Proxmox root
- Remaining storage: ~480GB for VMs

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
| dns-primary | [TODO] | Technitium DNS (Primary DNS + Ad-blocking) | Web UI: http://IP:5380 |
| dns-secondary | [TODO] | Technitium DNS (Secondary DNS + Ad-blocking) | Web UI: http://IP:5380 |
| docker-host | [TODO] | Docker container host | - |
| wireguard | [TODO] | VPN endpoint (on dns-primary) | - |

### DNS Configuration
| Record Type | Name | Target | Purpose |
|-------------|------|--------|---------|
| A | proxmox.local | [Proxmox IP] | Proxmox web interface |
| A | dns1.local | [dns-primary IP] | Technitium DNS primary admin interface |
| A | dns2.local | [dns-secondary IP] | Technitium DNS secondary admin interface |
| A | docker.local | [Docker host IP] | Docker host |
| A | traefik.local | [Docker host IP] | Traefik dashboard |
| A | portainer.local | [Docker host IP] | Portainer UI |

---

## VM Inventory

### Active VMs
| VM ID | Name | OS | vCPU | RAM | Disk | IP | Purpose | Status |
|-------|------|----|----- |-----|------|-------|---------|--------|
| 100 | dns-primary | Ubuntu Server 24.04 LTS | 1 | 1.5GB | 15GB | [TODO] | Technitium DNS + WireGuard VPN | Planned |
| 101 | dns-secondary | Ubuntu Server 24.04 LTS | 1 | 1.5GB | 15GB | [TODO] | Technitium DNS (secondary) | Planned |
| 102 | docker-host | Ubuntu Server 24.04 LTS | 4 | 9GB | 150GB | [TODO] | Docker container runtime | Planned |

**Total Allocated:** 6 vCPU, 12GB RAM, 180GB Disk
**Remaining:** ~2-4GB RAM, ~300GB Storage for future expansion

### Why Dual Technitium DNS?
**Consistency:** Same interface on both servers - easier to manage and configure
**True DNS Redundancy:** Proper primary/secondary DNS setup with zone transfers
**Professional Features:** Full authoritative + recursive DNS server capabilities
**Ad-blocking:** Quick Add blocklists with auto-updates every 24 hours
**Advanced DNS:** DoH, DoT, DNSSEC, conditional forwarding built-in
**Learning:** Understand real DNS server operation beyond just ad-blocking
**Zero downtime:** Can update/reboot one DNS server while the other runs

**DNS Configuration on Clients:**
- Primary DNS: [dns-primary IP] (Technitium Primary)
- Secondary DNS: [dns-secondary IP] (Technitium Secondary)

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
| dns-primary | [TODO] | [TODO] | ssh user@[PRIMARY-DNS-IP] | - |
| dns-secondary | [TODO] | [TODO] | ssh user@[SECONDARY-DNS-IP] | - |
| docker-host | [TODO] | [TODO] | ssh user@[DOCKER-IP] | - |

### DNS & Ad-blocking Services
| Service | Username | Password Location | Access URL | Notes |
|---------|----------|-------------------|------------|-------|
| Technitium DNS (Primary) | admin | [TODO: Set on first login] | http://dns1.local:5380 | Primary DNS server |
| Technitium DNS (Secondary) | admin | [TODO: Set on first login] | http://dns2.local:5380 | Secondary DNS server |

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
**Goal:** Get basic VMs running with dual Technitium DNS for redundancy and ad-blocking

**Steps:**
1. Create `dns-primary` (Ubuntu Server 24.04 LTS)
   - VM ID: 100
   - Resources: 1 vCPU, 1.5GB RAM, 15GB disk
   - Static IP assignment
   - Install Technitium DNS Server (automated Debian installer)
   - Install WireGuard for VPN access
   - Configure as primary DNS for homelab
   - Access web UI at http://[IP]:5380

2. Create `dns-secondary` (Ubuntu Server 24.04 LTS)
   - VM ID: 101
   - Resources: 1 vCPU, 1.5GB RAM, 15GB disk
   - Static IP assignment
   - Install Technitium DNS Server (automated Debian installer)
   - Configure as secondary DNS server
   - Set up zone transfers from primary
   - Access web UI at http://[IP]:5380

3. Create `docker-host` (Ubuntu Server 24.04 LTS)
   - VM ID: 102
   - Resources: 4 vCPU, 9GB RAM, 150GB disk
   - Static IP assignment
   - Install Docker & Docker Compose
   - Configure Docker logging (limit log sizes)
   - Point to both Technitium DNS servers

**Success Criteria:**
- All three VMs boot and are accessible via SSH
- VMs can reach internet and each other
- Docker installed and functional
- Both Technitium DNS web UIs accessible
- DNS redundancy working (can lose one DNS and still resolve)

---

### 📡 Phase 2: Networking & DNS
**Goal:** Dual Technitium DNS with ad-blocking and secure remote access

**Steps:**
1. Configure Technitium DNS Primary (dns-primary)
   - Complete initial setup wizard via web UI
   - Set upstream DNS (Cloudflare 1.1.1.1, Google 8.8.8.8)
   - Enable DNSSEC
   - Settings → Blocking → Quick Add → Select blocklists (HaGeZi Multi NORMAL, OISD Big)
   - Create local DNS zones (*.local) with A records
   - Configure as authoritative for local zone
   - Set as primary DNS on Proxmox and all VMs

2. Configure Technitium DNS Secondary (dns-secondary)
   - Complete initial setup wizard via web UI
   - Set upstream DNS (Quad9 9.9.9.9, Cloudflare 1.0.0.1)
   - Enable DNSSEC
   - Settings → Blocking → Quick Add → Same blocklists as primary
   - Configure zone transfer from primary DNS
   - Set up as secondary for local zones
   - Set as secondary DNS on Proxmox and all VMs

3. Configure WireGuard VPN (on dns-primary)
   - Generate server and client keys
   - Configure peer access
   - Route DNS queries through Technitium
   - Test remote connectivity
   - Document client configurations

4. Test DNS redundancy
   - Verify both DNS servers resolve queries
   - Test local zone resolution (*.local domains)
   - Shut down one DNS server and test failover
   - Verify ad-blocking effectiveness
   - Check query logs and statistics on both systems
   - Test zone transfer between primary and secondary

**Success Criteria:**
- All hostnames resolve via local DNS
- Ad-blocking working on both DNS servers
- Can access homelab remotely via WireGuard
- DNS failover works if one server is down
- Query statistics visible in both Technitium dashboards
- Zone transfers working between primary and secondary

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
- OPNsense/pfSense VM for advanced routing
- Additional WireGuard peers for family/friends

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

### Technitium DNS
```bash
# Check service status
systemctl status dns

# Restart DNS service
systemctl restart dns

# View logs
journalctl -u dns -f

# Check if service is running
systemctl is-active dns

# Update Technitium DNS
# (Done via web UI at http://dns1.local:5380 or http://dns2.local:5380)
# Settings → About → Check for Updates

# Manually update blocklists
# (Done via web UI)
# Settings → Blocking → Update Blocklists

# Configuration file location
/etc/dns/dns.config

# Data directory
/etc/dns/

# Backup DNS configuration
sudo tar -czf dns-backup-$(date +%Y%m%d).tar.gz /etc/dns/
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
| 2025-11-14 | Updated for KAMRUI N150 hardware specs, dual DNS VMs (Pi-hole + AdGuard Home) | Claude |
| 2025-11-14 | Switched to dual Technitium DNS setup for consistency and advanced DNS features | Claude |
| | | |

---

**Remember:** This is a living document. Update it whenever you:
- Add/remove VMs or containers
- Change IP addresses or network configuration
- Update credentials or access methods
- Complete a roadmap phase
- Learn something important

Keep this document in sync with reality, and it will be invaluable for troubleshooting and future development!
