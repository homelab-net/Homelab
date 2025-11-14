# DNS Server Setup Guide for Resource-Constrained Proxmox

## Overview
This guide covers setting up dns-1 and dns-2 (Technitium DNS servers) on a Proxmox host with limited resources (16GB RAM, 500GB storage).

## Table of Contents
- [Resource Planning](#resource-planning)
- [Prerequisites](#prerequisites)
- [Container vs VM Decision](#container-vs-vm-decision)
- [DNS-1 Setup](#dns-1-setup)
- [DNS-2 Setup](#dns-2-setup)
- [WireGuard Lifeline Configuration](#wireguard-lifeline-configuration)
- [Testing and Validation](#testing-and-validation)
- [Troubleshooting](#troubleshooting)

---

## Resource Planning

### Total System Resources
- **RAM**: 16GB
- **Storage**: 500GB
- **Goal**: Run dual DNS servers with high availability

### Recommended Allocation

#### DNS-1 (Primary)
- **Type**: LXC Container (recommended for efficiency)
- **RAM**: 512MB (1GB max)
- **CPU**: 1 core
- **Storage**: 8GB
- **IP**: 10.0.0.53 (example - adjust to your network)

#### DNS-2 (Secondary)
- **Type**: LXC Container (recommended for efficiency)
- **RAM**: 512MB (1GB max)
- **CPU**: 1 core
- **Storage**: 8GB
- **IP**: 10.0.0.54 (example - adjust to your network)

#### Proxmox Host Reserve
- **RAM**: 2-4GB for Proxmox itself
- **Storage**: 32GB for Proxmox OS
- **Remaining**: ~13GB RAM and ~450GB storage for other VMs/containers

---

## Prerequisites

1. Fresh Proxmox VE installation (7.x or 8.x)
2. Network configured with static IP for Proxmox host
3. Internet connectivity for downloading packages
4. SSH access to Proxmox host
5. Basic understanding of DNS concepts

---

## Container vs VM Decision

**Recommendation: Use LXC Containers**

### Why Containers?
- **Lower overhead**: Containers use ~50-100MB RAM vs VMs using 512MB+
- **Faster deployment**: Start in seconds vs minutes
- **Better resource utilization**: No hypervisor overhead
- **Easier backups**: Smaller backup sizes

### When to Use VMs Instead
- Need kernel-level isolation
- Running non-Linux DNS solutions
- Require specific kernel modules not available in containers

---

## DNS-1 Setup

### Step 1: Create LXC Container

```bash
# Download Ubuntu 22.04 template (if not already available)
pveam update
pveam download local ubuntu-22.04-standard_22.04-1_amd64.tar.zst

# Create dns-1 container
pct create 100 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
  --hostname dns-1 \
  --memory 512 \
  --swap 512 \
  --cores 1 \
  --net0 name=eth0,bridge=vmbr0,ip=10.0.0.53/24,gw=10.0.0.1 \
  --storage local-lvm \
  --rootfs local-lvm:8 \
  --nameserver 8.8.8.8 \
  --searchdomain your.domain.local \
  --password \
  --unprivileged 1 \
  --features nesting=1 \
  --onboot 1

# Start the container
pct start 100
```

**Note**: Adjust the following:
- `100` - Container ID (choose any available ID)
- `10.0.0.53/24` - Your network IP range
- `10.0.0.1` - Your gateway IP
- `your.domain.local` - Your domain name
- `local-lvm` - Your storage pool name

### Step 2: Enter Container and Update

```bash
# Enter the container
pct enter 100

# Update system
apt update && apt upgrade -y

# Install required packages
apt install -y curl wget sudo gnupg2 software-properties-common apt-transport-https ca-certificates
```

### Step 3: Install Technitium DNS

```bash
# Download and install Technitium DNS
curl -sSL https://download.technitium.com/dns/install.sh | sudo bash

# The installer will:
# - Install .NET runtime
# - Install Technitium DNS Server
# - Configure systemd service
# - Start the DNS server on port 5380 (web interface)
```

### Step 4: Initial Configuration

```bash
# Access web interface at: http://10.0.0.53:5380
# Default credentials: admin / admin

# IMPORTANT: Change the default password immediately!
```

**Via Web Interface:**
1. Navigate to `http://10.0.0.53:5380`
2. Login with `admin` / `admin`
3. Go to **Settings** → Change admin password
4. Configure DNS settings:
   - **DNS Server Domain**: your.domain.local
   - **Forwarders**: Add 1.1.1.1, 8.8.8.8 (or your preferred upstream DNS)
   - **Enable DNS-over-HTTPS**: Optional but recommended
   - **Enable DNSSEC**: Recommended for security

### Step 5: Configure Firewall (if applicable)

```bash
# Allow DNS traffic
iptables -A INPUT -p udp --dport 53 -j ACCEPT
iptables -A INPUT -p tcp --dport 53 -j ACCEPT

# Allow web interface (restrict to your management network)
iptables -A INPUT -p tcp --dport 5380 -s 10.0.0.0/24 -j ACCEPT

# Save rules
apt install -y iptables-persistent
netfilter-persistent save
```

### Step 6: Configure System to Start on Boot

```bash
# Enable Technitium service
systemctl enable dns

# Verify status
systemctl status dns
```

---

## DNS-2 Setup

Repeat the same process for dns-2 with these changes:

```bash
# Create dns-2 container
pct create 101 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
  --hostname dns-2 \
  --memory 512 \
  --swap 512 \
  --cores 1 \
  --net0 name=eth0,bridge=vmbr0,ip=10.0.0.54/24,gw=10.0.0.1 \
  --storage local-lvm \
  --rootfs local-lvm:8 \
  --nameserver 8.8.8.8 \
  --searchdomain your.domain.local \
  --password \
  --unprivileged 1 \
  --features nesting=1 \
  --onboot 1

pct start 101
```

Follow Steps 2-6 from DNS-1 setup, but use:
- Container ID: `101`
- IP address: `10.0.0.54`
- Hostname: `dns-2`

### Configure DNS Synchronization

**On dns-1 (Primary):**
1. Go to **Settings** → **Zones**
2. Enable **Zone Transfer** for secondary server
3. Add `10.0.0.54` to allowed secondary servers

**On dns-2 (Secondary):**
1. Go to **Settings** → **Zones**
2. Configure as secondary for dns-1
3. Add `10.0.0.53` as primary server
4. Enable **Zone Transfer** from primary

---

## WireGuard Lifeline Configuration

The WireGuard lifeline ensures DNS availability even if the local network fails by maintaining a VPN connection to an external endpoint.

### Step 1: Install WireGuard on Both DNS Servers

```bash
# On both dns-1 and dns-2
apt install -y wireguard wireguard-tools

# Enable IP forwarding
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p
```

### Step 2: Generate Keys

```bash
# On dns-1
cd /etc/wireguard
umask 077
wg genkey | tee dns1-private.key | wg pubkey > dns1-public.key

# On dns-2
cd /etc/wireguard
umask 077
wg genkey | tee dns2-private.key | wg pubkey > dns2-public.key
```

### Step 3: Configure WireGuard (Example)

**On dns-1** (`/etc/wireguard/wg0.conf`):
```ini
[Interface]
Address = 10.100.0.1/24
PrivateKey = <dns1-private-key>
ListenPort = 51820

[Peer]
# DNS-2
PublicKey = <dns2-public-key>
AllowedIPs = 10.100.0.2/32
PersistentKeepalive = 25

# Optional: External VPS peer for internet failover
[Peer]
PublicKey = <vps-public-key>
Endpoint = vps.example.com:51820
AllowedIPs = 10.100.0.100/32
PersistentKeepalive = 25
```

**On dns-2** (`/etc/wireguard/wg0.conf`):
```ini
[Interface]
Address = 10.100.0.2/24
PrivateKey = <dns2-private-key>
ListenPort = 51820

[Peer]
# DNS-1
PublicKey = <dns1-public-key>
AllowedIPs = 10.100.0.1/32
Endpoint = 10.0.0.53:51820
PersistentKeepalive = 25

# Optional: External VPS peer for internet failover
[Peer]
PublicKey = <vps-public-key>
Endpoint = vps.example.com:51820
AllowedIPs = 10.100.0.100/32
PersistentKeepalive = 25
```

### Step 4: Enable WireGuard

```bash
# On both servers
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

# Verify
wg show
```

### Step 5: Configure Technitium to Listen on WireGuard

In Technitium web interface:
1. Go to **Settings** → **Network**
2. Add WireGuard interface IP to listening interfaces:
   - DNS-1: Add `10.100.0.1`
   - DNS-2: Add `10.100.0.2`

---

## Testing and Validation

### Test 1: Basic DNS Resolution

```bash
# From Proxmox host or another machine
dig @10.0.0.53 google.com
dig @10.0.0.54 google.com

# Should return valid A records
```

### Test 2: Zone Transfer (if configured)

```bash
# From dns-2, check if zones sync from dns-1
dig @10.0.0.54 AXFR your.domain.local
```

### Test 3: WireGuard Connectivity

```bash
# From dns-1
ping 10.100.0.2

# From dns-2
ping 10.100.0.1

# Both should succeed
```

### Test 4: Failover Testing

```bash
# Configure client to use both DNS servers:
# Primary: 10.0.0.53
# Secondary: 10.0.0.54

# Stop dns-1
pct stop 100

# Test resolution still works via dns-2
dig @10.0.0.54 google.com

# Restart dns-1
pct start 100
```

### Test 5: WireGuard Lifeline

```bash
# From another machine on WireGuard network
dig @10.100.0.1 google.com
dig @10.100.0.2 google.com

# Should work even if local network is down
```

---

## Client Configuration

### Configure DHCP Server
Update your router/DHCP server to distribute:
- **Primary DNS**: 10.0.0.53
- **Secondary DNS**: 10.0.0.54

### Manual Configuration
On client machines:
```bash
# Linux
echo "nameserver 10.0.0.53" > /etc/resolv.conf
echo "nameserver 10.0.0.54" >> /etc/resolv.conf

# Windows
# Network Adapter Settings → IPv4 → DNS Servers
# Preferred: 10.0.0.53
# Alternate: 10.0.0.54
```

---

## Monitoring and Maintenance

### Resource Monitoring

```bash
# Check container resource usage
pct status 100
pct status 101

# Detailed stats
pct exec 100 -- top
pct exec 101 -- top
```

### Log Monitoring

```bash
# Technitium logs
pct exec 100 -- journalctl -u dns -f

# WireGuard logs
pct exec 100 -- journalctl -u wg-quick@wg0 -f
```

### Backup Strategy

```bash
# Backup dns-1
vzdump 100 --mode snapshot --storage local

# Backup dns-2
vzdump 101 --mode snapshot --storage local

# Schedule automated backups in Proxmox UI:
# Datacenter → Backup → Add
```

### Updates

```bash
# Monthly maintenance (or as needed)
pct exec 100 -- bash -c "apt update && apt upgrade -y"
pct exec 101 -- bash -c "apt update && apt upgrade -y"

# Technitium updates
# Check web interface → Settings → About for update notifications
```

---

## Troubleshooting

### DNS Server Not Responding

```bash
# Check service status
pct exec 100 -- systemctl status dns

# Check listening ports
pct exec 100 -- netstat -tulpn | grep 53

# Check logs
pct exec 100 -- journalctl -u dns -n 50
```

### WireGuard Connection Issues

```bash
# Check WireGuard status
pct exec 100 -- wg show

# Check if interface is up
pct exec 100 -- ip a show wg0

# Restart WireGuard
pct exec 100 -- systemctl restart wg-quick@wg0

# Check firewall
pct exec 100 -- iptables -L -n -v
```

### Container Won't Start

```bash
# Check Proxmox logs
cat /var/log/pve/tasks/active

# Increase memory if needed
pct set 100 --memory 1024

# Check storage
pvesm status
```

### Performance Issues

```bash
# Increase container resources
pct set 100 --memory 1024 --cores 2

# Check DNS cache hit rate in Technitium UI
# Settings → Statistics

# Optimize forwarders (use closer/faster DNS servers)
```

### Zone Transfer Failures

```bash
# On primary (dns-1), check zone transfer settings
# Ensure secondary IP is allowed

# Check network connectivity
pct exec 100 -- ping 10.0.0.54

# Check DNS service logs for transfer errors
pct exec 100 -- journalctl -u dns | grep -i transfer
```

---

## Advanced Optimizations for Limited Resources

### 1. Use Lightweight OS
- Consider Alpine Linux instead of Ubuntu for even lower overhead
- Alpine containers can run with 128-256MB RAM

### 2. Adjust Swap
```bash
# If RAM is tight, increase swap
pct set 100 --swap 1024
pct set 101 --swap 1024
```

### 3. Limit Cache Size
In Technitium settings:
- **Settings** → **Cache**
- Set maximum cache size to 50-100MB per server

### 4. Disable Unnecessary Features
- Disable DNS-over-HTTPS/TLS if not needed
- Disable DNSSEC validation if not required
- Limit query logging

### 5. Use CPU Limits
```bash
# Prevent DNS containers from using too much CPU
pct set 100 --cpulimit 1
pct set 101 --cpulimit 1
```

---

## Security Best Practices

1. **Change default passwords** immediately
2. **Restrict web interface access** to management network only
3. **Enable DNSSEC** validation for upstream queries
4. **Use DNS-over-HTTPS** for upstream forwarders
5. **Regular backups** of zone files and configurations
6. **Keep systems updated** monthly
7. **Monitor logs** for suspicious queries
8. **Implement rate limiting** in Technitium to prevent DNS amplification attacks
9. **Use WireGuard encryption** for all inter-server communication
10. **Disable recursion** for external clients if only serving local zones

---

## Resource Usage Summary

| Component | RAM | Storage | CPU | Network |
|-----------|-----|---------|-----|---------|
| dns-1 | 512MB | 8GB | 1 core | 1 interface |
| dns-2 | 512MB | 8GB | 1 core | 1 interface |
| Proxmox | 2-4GB | 32GB | - | - |
| **Total** | **~3-5GB** | **~48GB** | **2 cores** | - |
| **Remaining** | **11-13GB** | **~450GB** | - | - |

This leaves plenty of room for additional services on your 16GB/500GB system.

---

## Next Steps

1. **Deploy DNS servers** following this guide
2. **Test thoroughly** using the validation section
3. **Configure clients** to use new DNS servers
4. **Set up monitoring** (optional: Prometheus + Grafana)
5. **Document your specific configuration** (IP addresses, domain names, etc.)
6. **Create restore procedures** and test backup recovery

---

## Additional Resources

- [Technitium DNS Documentation](https://technitium.com/dns/)
- [WireGuard Documentation](https://www.wireguard.com/)
- [Proxmox LXC Documentation](https://pve.proxmox.com/wiki/Linux_Container)
- [DNS Best Practices (IETF)](https://www.rfc-editor.org/rfc/rfc1912)

---

## Changelog

- **2025-11-14**: Initial guide created for resource-constrained Proxmox setups
