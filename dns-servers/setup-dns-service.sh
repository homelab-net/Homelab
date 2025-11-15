#!/bin/bash
#
# DNS Service Setup Script
# Run this on each DNS server VM after provisioning
# This script deploys Technitium DNS using Docker Compose
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Function to detect which DNS server this is
detect_server() {
    local IP=$(hostname -I | awk '{print $1}')

    if [ "$IP" == "192.168.8.81" ]; then
        echo "dns-1"
    elif [ "$IP" == "192.168.8.82" ]; then
        echo "dns-2"
    else
        echo "unknown"
    fi
}

# Function to check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."

    # Check if running as root or with sudo
    if [ "$EUID" -ne 0 ] && ! sudo -n true 2>/dev/null; then
        log_error "This script requires sudo privileges"
        exit 1
    fi

    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi

    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi

    # Check if user is in docker group
    if ! groups $USER | grep -q docker; then
        log_warn "User $USER is not in docker group. Adding..."
        sudo usermod -aG docker $USER
        log_info "User added to docker group. You may need to log out and back in."
    fi

    log_info "All prerequisites met"
}

# Function to create directory structure
setup_directories() {
    log_step "Setting up directories..."

    sudo mkdir -p /opt/technitium/config
    sudo chown -R $USER:$USER /opt/technitium

    log_info "Directories created"
}

# Function to deploy docker compose
deploy_dns() {
    local SERVER=$(detect_server)
    log_step "Deploying Technitium DNS for ${SERVER}..."

    if [ "$SERVER" == "unknown" ]; then
        log_error "Could not detect server type. Please run on dns-1 or dns-2"
        exit 1
    fi

    # Create compose directory
    mkdir -p ~/dns-compose
    cd ~/dns-compose

    # Download docker-compose.yml from repository or use embedded version
    log_info "Creating docker-compose.yml..."

    cat > docker-compose.yml <<'EOF'
version: '3.8'

services:
  technitium:
    container_name: technitium-dns
    image: technitium/dns-server:latest
    restart: unless-stopped
    ports:
      - "53:53/udp"
      - "53:53/tcp"
      - "853:853/tcp"
      - "443:443/tcp"
      - "853:853/udp"
      - "5380:5380/tcp"
      - "67:67/udp"
    environment:
      - DNS_SERVER_DOMAIN=${HOSTNAME}.local
      - DNS_SERVER_ADMIN_PASSWORD=${DNS_ADMIN_PASSWORD:-admin}
      - DNS_SERVER_PREFER_IPV6=false
    volumes:
      - /opt/technitium/config:/etc/dns
    dns:
      - 1.1.1.1
      - 8.8.8.8
    cap_add:
      - NET_ADMIN
    sysctls:
      - net.ipv4.ip_unprivileged_port_start=0
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5380/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
EOF

    # Create .env file
    if [ ! -f .env ]; then
        log_info "Creating .env file..."
        cat > .env <<EOF
DNS_ADMIN_PASSWORD=$(openssl rand -base64 12)
HOSTNAME=${SERVER}
EOF
        log_info "Admin password generated and saved to .env"
    fi

    # Pull image
    log_info "Pulling Technitium DNS image..."
    docker-compose pull

    # Start service
    log_info "Starting Technitium DNS..."
    docker-compose up -d

    # Wait for service to start
    log_info "Waiting for service to start..."
    sleep 10

    # Check status
    if docker-compose ps | grep -q "Up"; then
        log_info "Technitium DNS started successfully!"
    else
        log_error "Failed to start Technitium DNS"
        docker-compose logs
        exit 1
    fi
}

# Function to configure systemd-resolved
configure_systemd_resolved() {
    log_step "Configuring systemd-resolved..."

    # Disable systemd-resolved stub listener
    sudo mkdir -p /etc/systemd/resolved.conf.d

    cat <<EOF | sudo tee /etc/systemd/resolved.conf.d/dns-servers.conf
[Resolve]
DNS=127.0.0.1
FallbackDNS=1.1.1.1 8.8.8.8
DNSStubListener=no
EOF

    sudo systemctl restart systemd-resolved

    log_info "systemd-resolved configured"
}

# Function to display summary
display_summary() {
    local SERVER=$(detect_server)
    local IP=$(hostname -I | awk '{print $1}')
    local PASSWORD=$(grep DNS_ADMIN_PASSWORD ~/dns-compose/.env | cut -d'=' -f2)

    echo ""
    echo "=========================================="
    echo "  DNS Server Setup Complete!"
    echo "=========================================="
    echo ""
    echo "Server: ${SERVER}"
    echo "IP Address: ${IP}"
    echo ""
    echo "Web Interface: http://${IP}:5380"
    echo "Username: admin"
    echo "Password: ${PASSWORD}"
    echo ""
    echo "DNS Service: Port 53 (TCP/UDP)"
    echo "DNS-over-TLS: Port 853"
    echo "DNS-over-HTTPS: Port 443"
    echo ""
    echo "Docker Compose Location: ~/dns-compose"
    echo ""
    echo "Useful Commands:"
    echo "  - View logs: cd ~/dns-compose && docker-compose logs -f"
    echo "  - Restart: cd ~/dns-compose && docker-compose restart"
    echo "  - Stop: cd ~/dns-compose && docker-compose down"
    echo "  - Start: cd ~/dns-compose && docker-compose up -d"
    echo ""
    echo "Next Steps:"
    echo "  1. Access the web interface and complete initial setup"
    echo "  2. Configure DNS zones and records"
    echo "  3. Set up DNS forwarding/caching as needed"
    echo "  4. Configure DNS-over-HTTPS/TLS if desired"
    echo "  5. Update your network devices to use this DNS server"
    echo ""
    echo "=========================================="
}

# Main execution
main() {
    echo "=========================================="
    echo "  DNS Service Setup"
    echo "=========================================="
    echo ""

    check_prerequisites
    setup_directories
    deploy_dns
    configure_systemd_resolved
    display_summary
}

main "$@"
