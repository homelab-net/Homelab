# Proxmox SSH Key-Based Authentication Setup

This guide provides scripts and instructions to set up passwordless SSH authentication from a Windows client to a Proxmox server using SSH keys.

## Overview

After completing this setup, you will be able to:
- Connect to your Proxmox server via SSH without entering a password
- Use SSH keys for secure, automated authentication
- Access Proxmox root account securely from Windows

## Prerequisites

### Windows Client
- Windows 10/11 with OpenSSH Client installed
- PowerShell 5.1 or later
- Network access to your Proxmox server

### Proxmox Server
- SSH service running (enabled by default)
- Root access or user with sudo privileges
- Network accessible from your Windows client

## Quick Start (Automated Method)

### Step 1: Install OpenSSH Client on Windows

First, ensure OpenSSH client is installed on your Windows machine.

**Check if OpenSSH is installed:**
```powershell
Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Client*'
```

**If not installed, install it:**
```powershell
# Run PowerShell as Administrator
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
```

### Step 2: Generate SSH Key Pair on Windows

Run the following PowerShell script to generate your SSH key pair:

```powershell
cd proxmox-ssh-setup
.\Generate-SSHKey.ps1
```

**Optional parameters:**
```powershell
.\Generate-SSHKey.ps1 -KeyName "my_proxmox_key" -Comment "My-Custom-Comment"
```

This script will:
- Create a `.ssh` directory in your user profile if it doesn't exist
- Generate a 4096-bit RSA key pair
- Save the keys as `proxmox_rsa` (private) and `proxmox_rsa.pub` (public)
- Copy the public key to your clipboard
- Display the public key for verification

### Step 3: Copy Public Key to Proxmox Server

Run the following PowerShell script to copy your public key to the Proxmox server:

```powershell
.\Copy-SSHKeyToProxmox.ps1 -ProxmoxHost "192.168.1.100"
```

**Full syntax with all options:**
```powershell
.\Copy-SSHKeyToProxmox.ps1 -ProxmoxHost "192.168.1.100" -ProxmoxUser "root" -Port 22 -KeyName "proxmox_rsa"
```

**You will be prompted for your Proxmox password ONE LAST TIME.**

The script will:
- Read your public key from `~\.ssh\proxmox_rsa.pub`
- Connect to your Proxmox server
- Create the `.ssh` directory if needed
- Add your public key to `/root/.ssh/authorized_keys`
- Set proper permissions
- Test the passwordless connection

### Step 4: Test the Connection

After the script completes, test your passwordless SSH connection:

```powershell
ssh root@192.168.1.100
```

You should now be logged in without entering a password!

## Manual Method (Alternative)

If you prefer to set things up manually or the automated scripts don't work:

### On Windows Client:

1. **Generate SSH key pair:**
```powershell
ssh-keygen -t rsa -b 4096 -C "Windows-to-Proxmox" -f $env:USERPROFILE\.ssh\proxmox_rsa
```

2. **Display your public key:**
```powershell
Get-Content $env:USERPROFILE\.ssh\proxmox_rsa.pub
```

3. **Copy the public key output** (starts with `ssh-rsa...`)

### On Proxmox Server:

1. **SSH into your Proxmox server** (with password):
```bash
ssh root@192.168.1.100
```

2. **Run the setup script:**
```bash
# Upload the setup script to Proxmox (or copy/paste the content)
chmod +x setup-ssh-key-proxmox.sh
./setup-ssh-key-proxmox.sh
```

3. **Or manually add the key:**
```bash
# Create .ssh directory if it doesn't exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Add your public key to authorized_keys
echo "your-public-key-here" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

## SSH Configuration (Optional)

For easier access, create an SSH config file on Windows:

**Location:** `C:\Users\YourUsername\.ssh\config`

```
Host proxmox
    HostName 192.168.1.100
    User root
    Port 22
    IdentityFile C:\Users\YourUsername\.ssh\proxmox_rsa
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

After creating this config, you can connect simply with:
```powershell
ssh proxmox
```

## Troubleshooting

### Issue: "Permission denied (publickey,password)"

**Solution:**
1. Verify the public key was added correctly on Proxmox:
   ```bash
   cat /root/.ssh/authorized_keys
   ```

2. Check file permissions on Proxmox:
   ```bash
   ls -la /root/.ssh
   # Should show:
   # drwx------ .ssh (700)
   # -rw------- authorized_keys (600)
   ```

3. Fix permissions if needed:
   ```bash
   chmod 700 /root/.ssh
   chmod 600 /root/.ssh/authorized_keys
   ```

### Issue: "Connection refused"

**Solution:**
1. Verify SSH service is running on Proxmox:
   ```bash
   systemctl status sshd
   ```

2. Start SSH service if needed:
   ```bash
   systemctl start sshd
   systemctl enable sshd
   ```

### Issue: "Could not resolve hostname"

**Solution:**
- Verify the IP address or hostname of your Proxmox server
- Test connectivity: `ping 192.168.1.100`
- Check your network connection

### Issue: SSH still asks for password

**Solution:**
1. Check Proxmox SSH configuration (`/etc/ssh/sshd_config`):
   ```bash
   grep "PubkeyAuthentication" /etc/ssh/sshd_config
   # Should show: PubkeyAuthentication yes
   ```

2. Enable public key authentication if disabled:
   ```bash
   sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
   systemctl restart sshd
   ```

3. Check SSH logs on Proxmox for errors:
   ```bash
   tail -f /var/log/auth.log
   ```

4. Verify you're using the correct private key:
   ```powershell
   ssh -i $env:USERPROFILE\.ssh\proxmox_rsa root@192.168.1.100
   ```

### Issue: "WARNING: UNPROTECTED PRIVATE KEY FILE!"

**Solution (Windows):**
1. Open File Explorer and navigate to `%USERPROFILE%\.ssh`
2. Right-click on `proxmox_rsa` → Properties → Security
3. Click Advanced → Disable inheritance → Remove all inherited permissions
4. Add your user with Full Control
5. Remove all other users
6. Click OK

**Solution (PowerShell):**
```powershell
$privateKeyPath = "$env:USERPROFILE\.ssh\proxmox_rsa"
# Remove inheritance
icacls $privateKeyPath /inheritance:r
# Grant current user full control
icacls $privateKeyPath /grant:r "$env:USERNAME:F"
```

## Security Best Practices

1. **Protect Your Private Key:**
   - Never share your private key (`proxmox_rsa`)
   - Keep it only on your Windows client
   - Consider adding a passphrase for extra security

2. **Use Key-Based Auth Only (Advanced):**
   After verifying key-based login works, you can disable password authentication on Proxmox:
   ```bash
   # Edit /etc/ssh/sshd_config
   PasswordAuthentication no
   PermitRootLogin prohibit-password

   # Restart SSH
   systemctl restart sshd
   ```

   **WARNING:** Only do this after confirming key-based auth works!

3. **Regular Key Rotation:**
   - Rotate SSH keys periodically (e.g., every 6-12 months)
   - Remove old keys from `authorized_keys`

4. **Backup Your Keys:**
   - Keep a secure backup of your private key
   - Store it in an encrypted location

## Advanced Configuration

### Using Different SSH Keys for Different Servers

Modify your `~\.ssh\config` file:

```
Host proxmox1
    HostName 192.168.1.100
    User root
    IdentityFile C:\Users\YourUsername\.ssh\proxmox1_rsa

Host proxmox2
    HostName 192.168.1.101
    User root
    IdentityFile C:\Users\YourUsername\.ssh\proxmox2_rsa
```

### Adding SSH Key for Non-Root Users

To set up key-based auth for a regular user (e.g., `admin`):

1. **On Proxmox:**
   ```bash
   su - admin
   mkdir -p ~/.ssh
   chmod 700 ~/.ssh
   echo "your-public-key" >> ~/.ssh/authorized_keys
   chmod 600 ~/.ssh/authorized_keys
   ```

2. **On Windows:**
   ```powershell
   ssh admin@192.168.1.100
   ```

## Scripts Reference

### Generate-SSHKey.ps1

Generates an SSH key pair on Windows.

**Parameters:**
- `-KeyName`: Name of the key file (default: `proxmox_rsa`)
- `-KeyPath`: Directory to store keys (default: `$env:USERPROFILE\.ssh`)
- `-Comment`: Comment for the key (default: `Windows-to-Proxmox-SSH-Key`)

### Copy-SSHKeyToProxmox.ps1

Copies the public key to Proxmox server.

**Parameters:**
- `-ProxmoxHost`: IP address or hostname of Proxmox server (required)
- `-ProxmoxUser`: Username for SSH (default: `root`)
- `-KeyName`: Name of the key file (default: `proxmox_rsa`)
- `-KeyPath`: Directory containing keys (default: `$env:USERPROFILE\.ssh`)
- `-Port`: SSH port (default: `22`)

### setup-ssh-key-proxmox.sh

Server-side script for manual key setup on Proxmox.

**Features:**
- Creates `.ssh` directory with proper permissions
- Allows pasting public key interactively
- Configures SSH daemon for key-based authentication
- Validates and backs up SSH configuration

## Additional Resources

- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [OpenSSH Documentation](https://www.openssh.com/manual.html)
- [SSH Key-Based Authentication Guide](https://www.ssh.com/academy/ssh/public-key-authentication)

## Support

If you encounter issues:
1. Check the Troubleshooting section above
2. Review Proxmox SSH logs: `tail -f /var/log/auth.log`
3. Verify network connectivity and firewall rules
4. Ensure OpenSSH is properly installed on Windows

## License

These scripts are provided as-is for homelab and educational purposes.
