# Copy-SSHKeyToProxmox.ps1
# PowerShell script to copy SSH public key to Proxmox server

param(
    [Parameter(Mandatory=$true)]
    [string]$ProxmoxHost,

    [string]$ProxmoxUser = "root",

    [string]$KeyName = "proxmox_rsa",

    [string]$KeyPath = "$env:USERPROFILE\.ssh",

    [int]$Port = 22
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Copy SSH Key to Proxmox Server" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$PublicKeyPath = Join-Path $KeyPath "$KeyName.pub"

# Check if public key exists
if (-not (Test-Path -Path $PublicKeyPath)) {
    Write-Host "[ERROR] Public key not found at: $PublicKeyPath" -ForegroundColor Red
    Write-Host "[INFO] Please run Generate-SSHKey.ps1 first to generate your SSH key pair" -ForegroundColor Yellow
    exit 1
}

# Read the public key
$PublicKey = Get-Content $PublicKeyPath -Raw
$PublicKey = $PublicKey.Trim()

Write-Host "[INFO] Public key found: $PublicKeyPath" -ForegroundColor Green
Write-Host "[INFO] Target server: $ProxmoxUser@$ProxmoxHost`:$Port" -ForegroundColor Green
Write-Host ""
Write-Host "[WARNING] You will be prompted for the Proxmox password ONE LAST TIME" -ForegroundColor Yellow
Write-Host "[INFO] After this setup, you won't need to enter the password again" -ForegroundColor Yellow
Write-Host ""

# Create the command to add the key to authorized_keys
$SshCommand = @"
mkdir -p ~/.ssh && \
chmod 700 ~/.ssh && \
echo '$PublicKey' >> ~/.ssh/authorized_keys && \
chmod 600 ~/.ssh/authorized_keys && \
echo 'SSH key added successfully!'
"@

try {
    Write-Host "[INFO] Connecting to Proxmox server..." -ForegroundColor Green
    Write-Host "[INFO] Please enter your Proxmox password when prompted" -ForegroundColor Yellow
    Write-Host ""

    # Use ssh to execute the command on the remote server
    $sshArgs = @(
        "-p", $Port,
        "$ProxmoxUser@$ProxmoxHost",
        $SshCommand
    )

    $process = Start-Process -FilePath "ssh" -ArgumentList $sshArgs -NoNewWindow -Wait -PassThru

    if ($process.ExitCode -eq 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "[SUCCESS] SSH key copied successfully!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Testing passwordless connection..." -ForegroundColor Yellow
        Write-Host ""

        # Test the connection
        $testArgs = @(
            "-p", $Port,
            "-o", "BatchMode=yes",
            "-o", "ConnectTimeout=5",
            "$ProxmoxUser@$ProxmoxHost",
            "echo 'Passwordless SSH connection successful!'"
        )

        $testProcess = Start-Process -FilePath "ssh" -ArgumentList $testArgs -NoNewWindow -Wait -PassThru

        if ($testProcess.ExitCode -eq 0) {
            Write-Host "[SUCCESS] Passwordless authentication is working!" -ForegroundColor Green
            Write-Host ""
            Write-Host "You can now connect to Proxmox without a password using:" -ForegroundColor Cyan
            Write-Host "ssh -p $Port $ProxmoxUser@$ProxmoxHost" -ForegroundColor White
            Write-Host ""
        }
        else {
            Write-Host "[WARNING] Connection test failed. Please verify manually." -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "[ERROR] Failed to copy SSH key. Exit code: $($process.ExitCode)" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "[ERROR] An error occurred: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Verify the Proxmox host address is correct" -ForegroundColor White
    Write-Host "2. Ensure SSH service is running on Proxmox" -ForegroundColor White
    Write-Host "3. Check network connectivity to the Proxmox server" -ForegroundColor White
    Write-Host "4. Verify OpenSSH client is installed on Windows" -ForegroundColor White
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
