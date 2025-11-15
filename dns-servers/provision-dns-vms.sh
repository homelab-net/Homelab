#!/bin/bash
#
# Proxmox DNS Server Provisioning Script
# Creates dns-1 (192.168.8.81) and dns-2 (192.168.8.82)
# Using Ubuntu 24.04.3 LTS
#

set -euo pipefail

# Configuration
ISO_PATH="local:iso/ubuntu-24.04.3-live-server-amd64.iso"
STORAGE="local-lvm"  # Adjust to your storage name
BRIDGE="vmbr0"       # Adjust to your bridge name
GATEWAY="192.168.8.1"  # Adjust to your gateway
DNS_SERVER="1.1.1.1"   # Temporary DNS for initial setup
NETMASK="24"

# VM IDs (adjust if needed)
DNS1_VMID=101
DNS2_VMID=102

# VM Specifications
CPU_CORES=2
MEMORY=4096  # 4GB RAM
DISK_SIZE=32G

# Function to create a DNS VM
create_dns_vm() {
    local VMID=$1
    local HOSTNAME=$2
    local IP=$3

    echo "=========================================="
    echo "Creating VM ${VMID}: ${HOSTNAME} (${IP})"
    echo "=========================================="

    # Check if VM already exists
    if qm status ${VMID} &>/dev/null; then
        echo "ERROR: VM ${VMID} already exists. Please remove it first or choose a different VMID."
        return 1
    fi

    # Create the VM
    echo "Creating VM..."
    qm create ${VMID} \
        --name ${HOSTNAME} \
        --memory ${MEMORY} \
        --cores ${CPU_CORES} \
        --net0 virtio,bridge=${BRIDGE} \
        --scsihw virtio-scsi-pci \
        --ostype l26 \
        --cpu host

    # Import the Ubuntu ISO as a CDROM
    echo "Attaching Ubuntu ISO..."
    qm set ${VMID} --cdrom ${ISO_PATH}

    # Create and attach the main disk
    echo "Creating disk..."
    qm set ${VMID} --scsi0 ${STORAGE}:${DISK_SIZE}

    # Set boot order
    qm set ${VMID} --boot order=scsi0

    # Enable QEMU Guest Agent
    qm set ${VMID} --agent enabled=1

    # Cloud-init configuration
    echo "Configuring Cloud-init..."
    qm set ${VMID} --ide2 ${STORAGE}:cloudinit

    # Set Cloud-init parameters
    qm set ${VMID} \
        --ipconfig0 ip=${IP}/${NETMASK},gw=${GATEWAY} \
        --nameserver ${DNS_SERVER} \
        --ciuser ubuntu \
        --sshkeys ~/.ssh/authorized_keys

    # Note: For Ubuntu live server, cloud-init setup needs the vendor data
    # You may need to manually install Ubuntu and then convert to template

    echo "VM ${HOSTNAME} created successfully!"
    echo "VMID: ${VMID}"
    echo "IP: ${IP}"
    echo ""
}

# Main execution
echo "=========================================="
echo "Proxmox DNS Server Provisioning"
echo "=========================================="
echo ""
echo "This script will create two DNS server VMs:"
echo "  - dns-1 (VMID: ${DNS1_VMID}) at 192.168.8.81"
echo "  - dns-2 (VMID: ${DNS2_VMID}) at 192.168.8.82"
echo ""
echo "Configuration:"
echo "  - CPU Cores: ${CPU_CORES}"
echo "  - Memory: ${MEMORY}MB"
echo "  - Disk: ${DISK_SIZE}"
echo "  - Storage: ${STORAGE}"
echo "  - Bridge: ${BRIDGE}"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."
echo ""

# Create DNS VMs
create_dns_vm ${DNS1_VMID} "dns-1" "192.168.8.81"
create_dns_vm ${DNS2_VMID} "dns-2" "192.168.8.82"

echo "=========================================="
echo "Provisioning Complete!"
echo "=========================================="
echo ""
echo "Next Steps:"
echo "1. Start the VMs: qm start ${DNS1_VMID} && qm start ${DNS2_VMID}"
echo "2. Access console: qm terminal ${DNS1_VMID}"
echo "3. Complete Ubuntu installation manually"
echo "4. After OS installation, run setup-dns-service.sh"
echo ""
echo "Alternative automated approach:"
echo "  - Create an Ubuntu cloud-init image template first"
echo "  - Then clone from template instead of using live ISO"
echo "  - See: https://pve.proxmox.com/wiki/Cloud-Init_Support"
echo ""
