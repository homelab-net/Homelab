# DNS Server Setup for Homelab

This directory contains all the necessary code and configuration to provision and deploy dual DNS servers on Proxmox using Technitium DNS.

## Overview

**Phase 2: Networking & DNS** from the Homelab Roadmap v2.3

This setup creates two redundant DNS servers:
- **dns-1**: 192.168.8.81
- **dns-2**: 192.168.8.82

Both servers run Technitium DNS Server in Docker containers on Ubuntu 24.04 LTS VMs.

## Architecture

```
┌─────────────────────────────────────────────────┐
│              Proxmox Host                       │
│                                                 │
│  ┌──────────────────┐    ┌──────────────────┐  │
│  │   dns-1 VM       │    │   dns-2 VM       │  │
│  │ 192.168.8.81     │    │ 192.168.8.82     │  │
│  │                  │    │                  │  │
│  │ ┌──────────────┐ │    │ ┌──────────────┐ │  │
│  │ │ Technitium   │ │    │ │ Technitium   │ │  │
│  │ │ DNS Server   │ │    │ │ DNS Server   │ │  │
│  │ │ (Docker)     │ │    │ │ (Docker)     │ │  │
│  │ └──────────────┘ │    │ └──────────────┘ │  │
│  │                  │    │                  │  │
│  │ Ubuntu 24.04 LTS │    │ Ubuntu 24.04 LTS │  │
│  └──────────────────┘    └──────────────────┘  │
│                                                 │
└─────────────────────────────────────────────────┘
```

## Features

- **Dual redundant DNS servers** for high availability
- **Technitium DNS Server** with web-based management
- **Docker-based deployment** for easy management
- **Cloud-init automation** for VM provisioning
- **DNS-over-HTTPS (DoH)** and **DNS-over-TLS (DoT)** support
- **DHCP server** capability (optional)
- **Split DNS** support for internal and external zones
- **DNS caching and forwarding**
- **DNSSEC validation**

## Prerequisites

### On Proxmox Host

1. **Proxmox VE** (tested on 7.x+)
2. **Storage**: At least 64GB free (32GB per VM)
3. **Network**: Bridge configured (default: vmbr0)
4. **ISO**: Ubuntu 24.04.3 LTS Server ISO uploaded to Proxmox
   - Or use cloud image (recommended for automation)

### Network Requirements

- Available IP addresses: 192.168.8.81 and 192.168.8.82
- Gateway: 192.168.8.1 (adjust in scripts if different)
- Subnet: 192.168.8.0/24 (adjust if different)

## Directory Structure

```
dns-servers/
├── README.md                           # This file
├── provision-dns-vms.sh                # Basic VM creation (manual install)
├── provision-dns-vms-cloudinit.sh      # Automated VM creation with cloud-init
├── setup-dns-service.sh                # DNS service deployment script
├── cloud-init/
│   ├── dns-1-user-data.yml             # Cloud-init config for dns-1
│   └── dns-2-user-data.yml             # Cloud-init config for dns-2
└── docker-compose/
    ├── dns-1/
    │   ├── docker-compose.yml          # Docker Compose for dns-1
    │   └── .env.example                # Environment variables example
    └── dns-2/
        ├── docker-compose.yml          # Docker Compose for dns-2
        └── .env.example                # Environment variables example
```

## Quick Start

### Method 1: Automated Setup (Recommended)

This method uses Ubuntu Cloud Images for fully automated provisioning.

1. **Run on Proxmox host:**
   ```bash
   cd dns-servers
   chmod +x provision-dns-vms-cloudinit.sh
   ./provision-dns-vms-cloudinit.sh
   ```

2. **Wait for VMs to provision** (approximately 5-10 minutes)

3. **SSH into each VM and deploy DNS service:**
   ```bash
   # For dns-1
   ssh ubuntu@192.168.8.81
   curl -O https://raw.githubusercontent.com/[your-repo]/dns-servers/setup-dns-service.sh
   chmod +x setup-dns-service.sh
   ./setup-dns-service.sh

   # For dns-2
   ssh ubuntu@192.168.8.82
   curl -O https://raw.githubusercontent.com/[your-repo]/dns-servers/setup-dns-service.sh
   chmod +x setup-dns-service.sh
   ./setup-dns-service.sh
   ```

4. **Access web interface:**
   - dns-1: http://192.168.8.81:5380
   - dns-2: http://192.168.8.82:5380

### Method 2: Manual Setup

This method uses the Ubuntu Server ISO with manual installation.

1. **Run on Proxmox host:**
   ```bash
   cd dns-servers
   chmod +x provision-dns-vms.sh
   ./provision-dns-vms.sh
   ```

2. **Start the VMs:**
   ```bash
   qm start 101
   qm start 102
   ```

3. **Complete Ubuntu installation:**
   - Access VM console: `qm terminal 101`
   - Follow Ubuntu installation wizard
   - Set hostname: dns-1 (or dns-2)
   - Configure network: Static IP as specified
   - Install OpenSSH server
   - Repeat for both VMs

4. **Deploy DNS service:**
   ```bash
   # Copy setup script to each VM
   scp setup-dns-service.sh ubuntu@192.168.8.81:~/
   scp setup-dns-service.sh ubuntu@192.168.8.82:~/

   # Run on each VM
   ssh ubuntu@192.168.8.81
   chmod +x setup-dns-service.sh
   ./setup-dns-service.sh
   ```

## Configuration

### VM Specifications

| Setting | Value |
|---------|-------|
| CPU Cores | 2 |
| Memory | 4GB |
| Disk | 32GB |
| OS | Ubuntu 24.04 LTS |
| Network | vmbr0 (adjust in scripts) |

### Customization

Edit the configuration variables in the provisioning scripts:

**provision-dns-vms-cloudinit.sh:**
```bash
DNS1_VMID=101              # VM ID for dns-1
DNS2_VMID=102              # VM ID for dns-2
CPU_CORES=2                # CPU cores per VM
MEMORY=4096                # RAM in MB
DISK_SIZE=32G              # Disk size
STORAGE="local-lvm"        # Proxmox storage pool
BRIDGE="vmbr0"             # Network bridge
GATEWAY="192.168.8.1"      # Default gateway
```

### Docker Compose Configuration

Edit `docker-compose/dns-1/.env` (create from `.env.example`):
```bash
DNS_ADMIN_PASSWORD=your-secure-password
```

## Post-Deployment Configuration

### Initial Setup

1. **Access Web Interface:**
   - Navigate to http://192.168.8.81:5380
   - Login with username: `admin` and the password from `.env` file

2. **Configure DNS Zones:**
   - Create primary zone for your local domain (e.g., `home.local`)
   - Add DNS records for your services
   - Configure reverse DNS zones if needed

3. **Configure Forwarders:**
   - Settings → Forwarders
   - Add upstream DNS servers (e.g., 1.1.1.1, 8.8.8.8)
   - Enable DNSSEC validation

4. **Enable DNS-over-HTTPS (Optional):**
   - Settings → DNS-over-HTTPS
   - Configure certificate
   - Enable DoH endpoint

### DNS Synchronization

To set up DNS replication between dns-1 and dns-2:

1. **On dns-1 (Primary):**
   - Settings → Zone Transfer
   - Enable zone transfers to 192.168.8.82

2. **On dns-2 (Secondary):**
   - Create secondary zones
   - Set primary server to 192.168.8.81
   - Configure zone transfer from primary

### Client Configuration

Update your network devices to use the new DNS servers:

**Option 1: DHCP Server**
- Configure DHCP to advertise DNS servers: 192.168.8.81, 192.168.8.82

**Option 2: Manual Configuration**
- Set DNS servers on clients:
  - Primary: 192.168.8.81
  - Secondary: 192.168.8.82

**Option 3: Router Configuration**
- Update router DNS settings to point to DNS servers

## Firewall Configuration

The setup script automatically configures UFW with these rules:

| Port | Protocol | Service |
|------|----------|---------|
| 22 | TCP | SSH |
| 53 | TCP/UDP | DNS |
| 80 | TCP | HTTP |
| 443 | TCP | HTTPS/DoH |
| 853 | TCP/UDP | DNS-over-TLS/QUIC |
| 5380 | TCP | Technitium Web UI |
| 67 | UDP | DHCP (optional) |

## Maintenance

### View Logs

```bash
# On DNS VM
cd ~/dns-compose
docker-compose logs -f
```

### Restart DNS Service

```bash
cd ~/dns-compose
docker-compose restart
```

### Update Technitium DNS

```bash
cd ~/dns-compose
docker-compose pull
docker-compose up -d
```

### Backup Configuration

```bash
# Backup DNS configuration
sudo tar -czf technitium-backup-$(date +%Y%m%d).tar.gz /opt/technitium/config
```

### Restore Configuration

```bash
# Restore DNS configuration
sudo tar -xzf technitium-backup-YYYYMMDD.tar.gz -C /
cd ~/dns-compose
docker-compose restart
```

## Monitoring

### Health Checks

Built-in Docker health checks monitor the Technitium web interface:

```bash
docker-compose ps
```

### DNS Query Testing

```bash
# Test DNS resolution
dig @192.168.8.81 example.com
nslookup example.com 192.168.8.81

# Test DNS-over-TLS
kdig -d @192.168.8.81 +tls example.com

# Test DNS-over-HTTPS
curl -H 'accept: application/dns-json' \
  'https://192.168.8.81/dns-query?name=example.com&type=A'
```

### Integration with Prometheus (Phase 4)

Technitium DNS provides metrics endpoint for Prometheus scraping:
- Metrics URL: `http://192.168.8.81:5380/metrics`
- Configure Prometheus to scrape both DNS servers

## Troubleshooting

### VM Won't Start

```bash
# Check VM status
qm status 101

# View VM config
qm config 101

# Check Proxmox logs
tail -f /var/log/syslog | grep qemu
```

### DNS Service Not Starting

```bash
# Check Docker status
systemctl status docker

# View container logs
docker-compose logs

# Check port conflicts
sudo netstat -tulpn | grep :53
```

### DNS Queries Not Resolving

```bash
# Check DNS service is listening
sudo netstat -tulpn | grep :53

# Check firewall
sudo ufw status

# Test local resolution
dig @127.0.0.1 example.com

# Check systemd-resolved
systemctl status systemd-resolved
```

### Can't Access Web Interface

```bash
# Check if port 5380 is accessible
curl http://192.168.8.81:5380

# Check firewall
sudo ufw allow 5380/tcp

# Check Docker port mapping
docker ps
```

## Security Considerations

1. **Change default admin password** immediately after deployment
2. **Restrict web interface access** to trusted networks only
3. **Enable DNSSEC** for DNS validation
4. **Use DNS-over-HTTPS/TLS** for encrypted queries
5. **Regular updates** of Ubuntu and Docker images
6. **Backup configurations** regularly
7. **Monitor DNS logs** for suspicious activity
8. **Implement rate limiting** to prevent DNS amplification attacks

## Integration with Other Services

### WireGuard VPN (Phase 2)
- Configure DNS servers to be accessible via WireGuard
- Add split DNS for VPN clients

### Traefik Reverse Proxy (Phase 3)
- Create DNS records for all services
- Example: `grafana.local`, `n8n.local`, etc.

### Prometheus Monitoring (Phase 4)
- Scrape Technitium metrics endpoint
- Create Grafana dashboards for DNS metrics
- Set up alerts for DNS failures

## References

- [Technitium DNS Documentation](https://technitium.com/dns/)
- [Proxmox Cloud-Init](https://pve.proxmox.com/wiki/Cloud-Init_Support)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Ubuntu Server Guide](https://ubuntu.com/server/docs)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Technitium DNS documentation
3. Check Proxmox logs
4. Open an issue in the repository

## License

This configuration is part of the Homelab project. Refer to the main repository for license information.

---

**Homelab Roadmap v2.3 - Phase 2: Networking & DNS**
