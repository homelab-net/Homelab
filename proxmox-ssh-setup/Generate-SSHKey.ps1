# Generate-SSHKey.ps1
# PowerShell script to generate SSH keys for Proxmox authentication on Windows

param(
    [string]$KeyName = "proxmox_rsa",
    [string]$KeyPath = "$env:USERPROFILE\.ssh",
    [string]$Comment = "Windows-to-Proxmox-SSH-Key"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Proxmox SSH Key Generator for Windows" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if .ssh directory exists, create if not
if (-not (Test-Path -Path $KeyPath)) {
    Write-Host "[INFO] Creating .ssh directory at: $KeyPath" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $KeyPath -Force | Out-Null
}

$PrivateKeyPath = Join-Path $KeyPath $KeyName
$PublicKeyPath = "$PrivateKeyPath.pub"

# Check if key already exists
if (Test-Path -Path $PrivateKeyPath) {
    Write-Host "[WARNING] SSH key already exists at: $PrivateKeyPath" -ForegroundColor Yellow
    $overwrite = Read-Host "Do you want to overwrite it? (yes/no)"
    if ($overwrite -ne "yes") {
        Write-Host "[INFO] Keeping existing key. Exiting..." -ForegroundColor Green
        exit 0
    }
}

# Generate SSH key pair
Write-Host "[INFO] Generating SSH key pair..." -ForegroundColor Green
Write-Host "[INFO] Key type: RSA 4096-bit" -ForegroundColor Green
Write-Host "[INFO] Location: $PrivateKeyPath" -ForegroundColor Green
Write-Host ""

try {
    # Use ssh-keygen to generate the key
    $sshKeygenArgs = @(
        "-t", "rsa",
        "-b", "4096",
        "-C", $Comment,
        "-f", $PrivateKeyPath,
        "-N", '""'  # No passphrase (for passwordless authentication)
    )

    $process = Start-Process -FilePath "ssh-keygen" -ArgumentList $sshKeygenArgs -NoNewWindow -Wait -PassThru

    if ($process.ExitCode -eq 0) {
        Write-Host ""
        Write-Host "[SUCCESS] SSH key pair generated successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Private key: $PrivateKeyPath" -ForegroundColor Cyan
        Write-Host "Public key:  $PublicKeyPath" -ForegroundColor Cyan
        Write-Host ""

        # Display the public key
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "Your Public Key:" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Get-Content $PublicKeyPath
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""

        # Copy public key to clipboard
        Get-Content $PublicKeyPath | Set-Clipboard
        Write-Host "[INFO] Public key has been copied to clipboard!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "1. Run the Copy-SSHKeyToProxmox.ps1 script to copy the key to your Proxmox server" -ForegroundColor White
        Write-Host "2. Or manually add the public key to /root/.ssh/authorized_keys on your Proxmox server" -ForegroundColor White
        Write-Host ""
    }
    else {
        Write-Host "[ERROR] Failed to generate SSH key. Exit code: $($process.ExitCode)" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "[ERROR] An error occurred: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Make sure OpenSSH is installed on your Windows system." -ForegroundColor Yellow
    Write-Host "To install OpenSSH, run PowerShell as Administrator and execute:" -ForegroundColor Yellow
    Write-Host "Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0" -ForegroundColor Cyan
    exit 1
}
