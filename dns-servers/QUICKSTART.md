# Quick Start Guide - DNS Servers

This is a condensed guide to get your DNS servers up and running quickly.

## Prerequisites Checklist

- [ ] Proxmox host running and accessible
- [ ] Network: 192.168.8.0/24 with gateway at 192.168.8.1
- [ ] IPs available: 192.168.8.81 and 192.168.8.82
- [ ] SSH access to Proxmox host
- [ ] At least 64GB storage available

## 5-Minute Setup (Automated)

### Step 1: Upload to Proxmox

```bash
# SSH to your Proxmox host
ssh root@your-proxmox-host

# Clone or upload the dns-servers directory
cd /root
git clone <your-repo-url>
cd dns-servers
```

### Step 2: Edit Configuration (Optional)

Only needed if your network differs from defaults:

```bash
nano provision-dns-vms-cloudinit.sh

# Update these if needed:
# GATEWAY="192.168.8.1"
# STORAGE="local-lvm"
# BRIDGE="vmbr0"
```

### Step 3: Run Provisioning Script

```bash
chmod +x provision-dns-vms-cloudinit.sh
./provision-dns-vms-cloudinit.sh
```

Press Enter when prompted, then wait 5-10 minutes for VMs to provision.

### Step 4: Deploy DNS Service

```bash
# SSH to dns-1
ssh ubuntu@192.168.8.81

# Download and run setup script
wget https://raw.githubusercontent.com/<your-repo>/main/dns-servers/setup-dns-service.sh
chmod +x setup-dns-service.sh
./setup-dns-service.sh

# Note the admin password displayed at the end
```

Repeat for dns-2:
```bash
ssh ubuntu@192.168.8.82
# Same commands as above
```

### Step 5: Access Web Interface

1. Open browser: http://192.168.8.81:5380
2. Login: admin / <password-from-step-4>
3. Complete initial setup wizard

## Manual Alternative

If cloud-init doesn't work for you:

```bash
# On Proxmox host
chmod +x provision-dns-vms.sh
./provision-dns-vms.sh

# Start VMs
qm start 101
qm start 102

# Access console and install Ubuntu manually
qm terminal 101

# After OS installation, copy and run setup script
scp setup-dns-service.sh ubuntu@192.168.8.81:~/
ssh ubuntu@192.168.8.81
./setup-dns-service.sh
```

## Verification

Test DNS resolution:

```bash
# From any computer on your network
dig @192.168.8.81 google.com
dig @192.168.8.82 google.com

# Both should return A records
```

## Next Steps

1. **Configure DNS zones** for your local domain
2. **Add DNS records** for your services
3. **Update DHCP** to use new DNS servers
4. **Configure replication** between dns-1 and dns-2
5. **Enable DNSSEC** and DoH/DoT

See [README.md](README.md) for detailed configuration instructions.

## Quick Commands Reference

### Proxmox
```bash
qm list                    # List all VMs
qm start 101              # Start dns-1
qm stop 101               # Stop dns-1
qm destroy 101            # Delete dns-1
qm terminal 101           # Access console
```

### DNS Server
```bash
cd ~/dns-compose
docker-compose ps         # Check status
docker-compose logs -f    # View logs
docker-compose restart    # Restart service
docker-compose down       # Stop service
docker-compose up -d      # Start service
```

### DNS Testing
```bash
dig @192.168.8.81 example.com              # Test DNS query
nslookup example.com 192.168.8.81          # Alternative test
host example.com 192.168.8.81              # Another alternative
drill @192.168.8.81 example.com            # Yet another tool
```

## Troubleshooting

**VMs won't start?**
```bash
qm status 101
tail -f /var/log/syslog | grep qemu
```

**Can't SSH to VMs?**
```bash
# Check from Proxmox console
qm terminal 101
ip addr show
ping 192.168.8.1
```

**DNS not resolving?**
```bash
# On DNS server
docker-compose ps
docker-compose logs
sudo netstat -tulpn | grep :53
```

**Web interface not accessible?**
```bash
# On DNS server
curl http://localhost:5380
sudo ufw status
docker ps
```

## Support

- Full documentation: [README.md](README.md)
- Technitium DNS docs: https://technitium.com/dns/
- Proxmox docs: https://pve.proxmox.com/wiki/

---

**Setup Time**: ~15 minutes total
**Difficulty**: Easy to Medium
