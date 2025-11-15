#!/bin/bash
# setup-ssh-key-proxmox.sh
# Script to manually configure SSH key authentication on Proxmox server
# Run this script ON the Proxmox server

set -e

echo "========================================"
echo "Proxmox SSH Key Setup (Server Side)"
echo "========================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_warning "This script should be run as root for proper Proxmox configuration"
    print_info "Switching to root user configuration..."
fi

# Set the SSH directory path
SSH_DIR="/root/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"
SSHD_CONFIG="/etc/ssh/sshd_config"

# Create .ssh directory if it doesn't exist
if [ ! -d "$SSH_DIR" ]; then
    print_info "Creating .ssh directory at $SSH_DIR"
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
else
    print_info ".ssh directory already exists"
fi

# Create authorized_keys file if it doesn't exist
if [ ! -f "$AUTHORIZED_KEYS" ]; then
    print_info "Creating authorized_keys file"
    touch "$AUTHORIZED_KEYS"
    chmod 600 "$AUTHORIZED_KEYS"
else
    print_info "authorized_keys file already exists"
fi

# Display current authorized keys
if [ -s "$AUTHORIZED_KEYS" ]; then
    print_info "Current authorized keys:"
    echo "----------------------------------------"
    cat -n "$AUTHORIZED_KEYS"
    echo "----------------------------------------"
    echo ""
fi

# Ask if user wants to add a new key
echo ""
echo -e "${CYAN}Do you want to add a new SSH public key?${NC}"
echo "1) Yes, I'll paste it now"
echo "2) No, just verify SSH configuration"
echo "3) Exit"
echo ""
read -p "Choose an option (1-3): " choice

case $choice in
    1)
        echo ""
        print_info "Paste your SSH public key below and press Enter:"
        print_info "(The key should start with 'ssh-rsa' or 'ssh-ed25519')"
        echo ""
        read -r public_key

        # Validate the key format
        if [[ ! "$public_key" =~ ^ssh-(rsa|ed25519|ecdsa|dss) ]]; then
            print_error "Invalid SSH key format. Key should start with 'ssh-rsa', 'ssh-ed25519', etc."
            exit 1
        fi

        # Check if key already exists
        if grep -qF "$public_key" "$AUTHORIZED_KEYS" 2>/dev/null; then
            print_warning "This key is already in authorized_keys"
        else
            # Add the key
            echo "$public_key" >> "$AUTHORIZED_KEYS"
            print_success "SSH public key added to $AUTHORIZED_KEYS"
        fi
        ;;
    2)
        print_info "Skipping key addition..."
        ;;
    3)
        print_info "Exiting..."
        exit 0
        ;;
    *)
        print_error "Invalid choice"
        exit 1
        ;;
esac

echo ""
print_info "Verifying SSH server configuration..."
echo ""

# Check SSH configuration
print_info "Checking SSH daemon configuration..."

# Backup sshd_config
if [ ! -f "$SSHD_CONFIG.backup" ]; then
    print_info "Creating backup of sshd_config..."
    cp "$SSHD_CONFIG" "$SSHD_CONFIG.backup"
fi

# Check important SSH settings
echo ""
echo "Current SSH Configuration:"
echo "----------------------------------------"

check_ssh_config() {
    local setting=$1
    local recommended=$2
    local current=$(grep "^$setting" "$SSHD_CONFIG" || echo "# $setting not explicitly set")

    echo -e "${CYAN}$setting${NC}"
    echo "  Current: $current"
    echo "  Recommended: $setting $recommended"
    echo ""
}

check_ssh_config "PubkeyAuthentication" "yes"
check_ssh_config "PermitRootLogin" "prohibit-password"
check_ssh_config "PasswordAuthentication" "yes"

echo "----------------------------------------"
echo ""

print_warning "For enhanced security, consider these settings in $SSHD_CONFIG:"
echo "  - PubkeyAuthentication yes          (Enable key-based auth)"
echo "  - PermitRootLogin prohibit-password (Allow root login only with keys)"
echo "  - PasswordAuthentication yes        (Keep password auth as fallback)"
echo ""

read -p "Do you want to enable recommended SSH settings? (yes/no): " configure_ssh

if [ "$configure_ssh" = "yes" ]; then
    print_info "Configuring SSH daemon..."

    # Enable PubkeyAuthentication
    if grep -q "^#*PubkeyAuthentication" "$SSHD_CONFIG"; then
        sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSHD_CONFIG"
    else
        echo "PubkeyAuthentication yes" >> "$SSHD_CONFIG"
    fi

    # Configure PermitRootLogin
    if grep -q "^#*PermitRootLogin" "$SSHD_CONFIG"; then
        sed -i 's/^#*PermitRootLogin.*/PermitRootLogin prohibit-password/' "$SSHD_CONFIG"
    else
        echo "PermitRootLogin prohibit-password" >> "$SSHD_CONFIG"
    fi

    print_success "SSH configuration updated"

    # Test SSH configuration
    print_info "Testing SSH configuration..."
    if sshd -t; then
        print_success "SSH configuration is valid"

        read -p "Restart SSH service now? (yes/no): " restart_ssh
        if [ "$restart_ssh" = "yes" ]; then
            print_info "Restarting SSH service..."
            systemctl restart sshd
            print_success "SSH service restarted"
        else
            print_warning "Remember to restart SSH service later: systemctl restart sshd"
        fi
    else
        print_error "SSH configuration test failed!"
        print_info "Restoring backup..."
        cp "$SSHD_CONFIG.backup" "$SSHD_CONFIG"
        print_warning "Original configuration restored"
        exit 1
    fi
fi

echo ""
echo "========================================"
print_success "SSH Key Setup Complete!"
echo "========================================"
echo ""
print_info "Summary:"
echo "  - SSH directory: $SSH_DIR (permissions: $(stat -c %a $SSH_DIR))"
echo "  - Authorized keys: $AUTHORIZED_KEYS (permissions: $(stat -c %a $AUTHORIZED_KEYS))"
echo "  - Number of authorized keys: $(wc -l < $AUTHORIZED_KEYS)"
echo ""
print_info "You can now test the connection from your Windows client:"
echo "  ssh root@<proxmox-ip>"
echo ""
