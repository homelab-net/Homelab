#!/bin/bash
#
# Proxmox DNS Server Provisioning Script (Cloud-init Method)
# Creates dns-1 (192.168.8.81) and dns-2 (192.168.8.82)
# Using Ubuntu 24.04 Cloud Image for full automation
#

set -euo pipefail

# Configuration
CLOUD_IMAGE_URL="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
CLOUD_IMAGE_NAME="noble-server-cloudimg-amd64.img"
STORAGE="local-lvm"  # Adjust to your storage name
BRIDGE="vmbr0"       # Adjust to your bridge name
GATEWAY="192.168.8.1"
NETMASK="24"
SEARCH_DOMAIN="local"

# VM IDs
DNS1_VMID=101
DNS2_VMID=102
TEMPLATE_VMID=9000

# VM Specifications
CPU_CORES=2
MEMORY=4096  # 4GB RAM
DISK_SIZE=32G

# Cloud-init user data directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLOUDINIT_DIR="${SCRIPT_DIR}/cloud-init"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to download Ubuntu cloud image
download_cloud_image() {
    log_info "Checking for Ubuntu cloud image..."

    if [ -f "/tmp/${CLOUD_IMAGE_NAME}" ]; then
        log_info "Cloud image already exists, skipping download"
        return 0
    fi

    log_info "Downloading Ubuntu 24.04 cloud image..."
    wget -O "/tmp/${CLOUD_IMAGE_NAME}" "${CLOUD_IMAGE_URL}"
    log_info "Download complete"
}

# Function to create Ubuntu template
create_ubuntu_template() {
    log_info "Creating Ubuntu 24.04 template (VMID: ${TEMPLATE_VMID})..."

    # Check if template already exists
    if qm status ${TEMPLATE_VMID} &>/dev/null; then
        log_warn "Template ${TEMPLATE_VMID} already exists, skipping creation"
        return 0
    fi

    # Create VM
    qm create ${TEMPLATE_VMID} \
        --name ubuntu-2404-cloudinit \
        --memory 2048 \
        --cores 2 \
        --net0 virtio,bridge=${BRIDGE} \
        --scsihw virtio-scsi-pci

    # Import the cloud image
    qm importdisk ${TEMPLATE_VMID} "/tmp/${CLOUD_IMAGE_NAME}" ${STORAGE}

    # Attach the imported disk
    qm set ${TEMPLATE_VMID} --scsi0 ${STORAGE}:vm-${TEMPLATE_VMID}-disk-0

    # Add cloud-init drive
    qm set ${TEMPLATE_VMID} --ide2 ${STORAGE}:cloudinit

    # Set boot disk
    qm set ${TEMPLATE_VMID} --boot order=scsi0

    # Enable QEMU guest agent
    qm set ${TEMPLATE_VMID} --agent enabled=1

    # Add serial console
    qm set ${TEMPLATE_VMID} --serial0 socket --vga serial0

    # Convert to template
    qm template ${TEMPLATE_VMID}

    log_info "Template created successfully"
}

# Function to create DNS VM from template
create_dns_vm_from_template() {
    local VMID=$1
    local HOSTNAME=$2
    local IP=$3

    log_info "Creating VM ${VMID}: ${HOSTNAME} (${IP})"

    # Check if VM already exists
    if qm status ${VMID} &>/dev/null; then
        log_error "VM ${VMID} already exists. Please remove it first or choose a different VMID."
        return 1
    fi

    # Clone from template
    log_info "Cloning from template..."
    qm clone ${TEMPLATE_VMID} ${VMID} \
        --name ${HOSTNAME} \
        --full

    # Configure VM
    log_info "Configuring VM..."
    qm set ${VMID} --memory ${MEMORY}
    qm set ${VMID} --cores ${CPU_CORES}

    # Resize disk
    qm resize ${VMID} scsi0 ${DISK_SIZE}

    # Configure cloud-init
    qm set ${VMID} \
        --ipconfig0 ip=${IP}/${NETMASK},gw=${GATEWAY} \
        --nameserver "1.1.1.1,8.8.8.8" \
        --searchdomain ${SEARCH_DOMAIN} \
        --ciuser ubuntu \
        --cipassword $(openssl rand -base64 12) \
        --sshkeys ~/.ssh/authorized_keys

    # Load custom cloud-init if exists
    if [ -f "${CLOUDINIT_DIR}/${HOSTNAME}-user-data.yml" ]; then
        log_info "Applying custom cloud-init configuration..."
        # Note: Custom cloud-init requires snippet storage
        # qm set ${VMID} --cicustom "user=local:snippets/${HOSTNAME}-user-data.yml"
        log_warn "Custom cloud-init requires manual setup via snippets storage"
    fi

    log_info "VM ${HOSTNAME} created successfully!"
    echo "  VMID: ${VMID}"
    echo "  IP: ${IP}"
    echo "  Username: ubuntu"
    echo "  SSH: Use your SSH key to connect"
    echo ""
}

# Function to start VMs
start_vms() {
    log_info "Starting DNS VMs..."
    qm start ${DNS1_VMID}
    qm start ${DNS2_VMID}

    log_info "Waiting for VMs to boot (30 seconds)..."
    sleep 30

    log_info "VMs started. You can connect via:"
    echo "  ssh ubuntu@192.168.8.81"
    echo "  ssh ubuntu@192.168.8.82"
}

# Main execution
main() {
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

    # Download cloud image
    download_cloud_image

    # Create template
    create_ubuntu_template

    # Create DNS VMs
    create_dns_vm_from_template ${DNS1_VMID} "dns-1" "192.168.8.81"
    create_dns_vm_from_template ${DNS2_VMID} "dns-2" "192.168.8.82"

    # Ask to start VMs
    echo ""
    read -p "Start the VMs now? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        start_vms
    fi

    echo ""
    echo "=========================================="
    echo "Provisioning Complete!"
    echo "=========================================="
    echo ""
    echo "Next Steps:"
    echo "1. SSH into the VMs (if not started, run: qm start ${DNS1_VMID} ${DNS2_VMID})"
    echo "2. Run the setup-dns-service.sh script on each VM"
    echo "3. Configure Technitium DNS via web interface"
    echo ""
}

main "$@"
