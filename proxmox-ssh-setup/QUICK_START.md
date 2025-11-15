# Quick Start Guide - Proxmox SSH Key Setup

## TL;DR - 3 Simple Steps

### 1. Generate SSH Key (Windows)
```powershell
cd proxmox-ssh-setup
.\Generate-SSHKey.ps1
```

### 2. Copy Key to Proxmox (Windows)
```powershell
.\Copy-SSHKeyToProxmox.ps1 -ProxmoxHost "YOUR_PROXMOX_IP"
```
*Replace `YOUR_PROXMOX_IP` with your Proxmox server IP address*

### 3. Test Connection (Windows)
```powershell
ssh root@YOUR_PROXMOX_IP
```

**You should now be logged in without a password!**

---

## Manual Commands (If Scripts Don't Work)

### On Windows:
```powershell
# 1. Generate key
ssh-keygen -t rsa -b 4096 -f $env:USERPROFILE\.ssh\proxmox_rsa

# 2. Display public key (copy this)
Get-Content $env:USERPROFILE\.ssh\proxmox_rsa.pub

# 3. Connect to Proxmox and paste the key
ssh root@YOUR_PROXMOX_IP
```

### On Proxmox (after SSH login):
```bash
# Create SSH directory
mkdir -p ~/.ssh && chmod 700 ~/.ssh

# Add your public key (paste the key you copied)
echo "PASTE_YOUR_PUBLIC_KEY_HERE" >> ~/.ssh/authorized_keys

# Set permissions
chmod 600 ~/.ssh/authorized_keys

# Exit
exit
```

### Back on Windows:
```powershell
# Test passwordless login
ssh root@YOUR_PROXMOX_IP
```

---

## Common Issues & Quick Fixes

| Issue | Quick Fix |
|-------|-----------|
| "Command not found: ssh-keygen" | Install OpenSSH: `Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0` (Run PowerShell as Admin) |
| Still asks for password | Check file permissions on Proxmox: `chmod 600 ~/.ssh/authorized_keys && chmod 700 ~/.ssh` |
| "Permission denied" | Verify key was added: `cat ~/.ssh/authorized_keys` on Proxmox |
| "Connection refused" | Start SSH on Proxmox: `systemctl start sshd` |

---

## Even Easier Connection (Optional)

Create a config file at `C:\Users\YourUsername\.ssh\config`:

```
Host proxmox
    HostName YOUR_PROXMOX_IP
    User root
    IdentityFile C:\Users\YourUsername\.ssh\proxmox_rsa
```

Now just type:
```powershell
ssh proxmox
```

---

## Security Note

Your **private key** (`proxmox_rsa`) is like a password - keep it safe!
- Never share it
- Don't upload it anywhere
- Consider adding a passphrase to it

---

For detailed documentation, see [README.md](README.md)
