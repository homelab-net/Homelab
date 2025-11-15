# PowerShell Example: Programmatic SSH Access to Proxmox
# This script demonstrates how to automate SSH commands to Proxmox
# using key-based authentication (no password required)

# Configuration - UPDATE THESE VALUES
$ProxmoxHost = "192.168.1.100"  # Your Proxmox IP address
$ProxmoxUser = "root"
$ProxmoxPort = 22
$SSHKeyPath = "$env:USERPROFILE\.ssh\proxmox_rsa"

# Color output functions
function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Function to execute SSH command and return output
function Invoke-ProxmoxSSH {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Command,

        [string]$Host = $ProxmoxHost,
        [string]$User = $ProxmoxUser,
        [int]$Port = $ProxmoxPort,
        [string]$KeyPath = $SSHKeyPath
    )

    try {
        # Build SSH command
        $sshArgs = @(
            "-i", $KeyPath,
            "-p", $Port,
            "-o", "StrictHostKeyChecking=no",
            "-o", "BatchMode=yes",
            "$User@$Host",
            $Command
        )

        # Execute SSH command and capture output
        $output = & ssh $sshArgs 2>&1

        if ($LASTEXITCODE -eq 0) {
            return @{
                Success = $true
                Output = $output
                ExitCode = $LASTEXITCODE
            }
        }
        else {
            return @{
                Success = $false
                Output = $output
                ExitCode = $LASTEXITCODE
            }
        }
    }
    catch {
        return @{
            Success = $false
            Output = $_.Exception.Message
            ExitCode = -1
        }
    }
}

# Function to test SSH connection
function Test-ProxmoxConnection {
    Write-Info "Testing connection to Proxmox..."

    $result = Invoke-ProxmoxSSH -Command "echo 'Connection successful'"

    if ($result.Success) {
        Write-Success "Connection test passed!"
        return $true
    }
    else {
        Write-Error-Custom "Connection test failed!"
        Write-Host "Output: $($result.Output)" -ForegroundColor Red
        return $false
    }
}

# Main script
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Proxmox SSH Automation Example" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if SSH key exists
if (-not (Test-Path $SSHKeyPath)) {
    Write-Error-Custom "SSH private key not found at: $SSHKeyPath"
    Write-Info "Please run Generate-SSHKey.ps1 first"
    exit 1
}

Write-Info "Using SSH key: $SSHKeyPath"
Write-Info "Connecting to: $ProxmoxUser@$ProxmoxHost`:$ProxmoxPort"
Write-Host ""

# Test connection
if (-not (Test-ProxmoxConnection)) {
    Write-Error-Custom "Cannot connect to Proxmox server"
    Write-Info "Make sure:"
    Write-Host "  1. Your public key is installed on Proxmox" -ForegroundColor White
    Write-Host "  2. The Proxmox server is accessible" -ForegroundColor White
    Write-Host "  3. SSH service is running on Proxmox" -ForegroundColor White
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Example 1: Get System Information" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Get Proxmox version
Write-Info "Getting Proxmox version..."
$result = Invoke-ProxmoxSSH -Command "pveversion"
if ($result.Success) {
    Write-Host $result.Output
}

# Get hostname
Write-Info "Getting hostname..."
$result = Invoke-ProxmoxSSH -Command "hostname"
if ($result.Success) {
    Write-Host "Hostname: $($result.Output)" -ForegroundColor White
}

# Get uptime
Write-Info "Getting system uptime..."
$result = Invoke-ProxmoxSSH -Command "uptime"
if ($result.Success) {
    Write-Host $result.Output
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Example 2: Check Resources" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Check memory usage
Write-Info "Checking memory usage..."
$result = Invoke-ProxmoxSSH -Command "free -h"
if ($result.Success) {
    Write-Host $result.Output
}

Write-Host ""

# Check disk usage
Write-Info "Checking disk usage..."
$result = Invoke-ProxmoxSSH -Command "df -h /"
if ($result.Success) {
    Write-Host $result.Output
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Example 3: List Virtual Machines" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Info "Getting list of VMs..."
$result = Invoke-ProxmoxSSH -Command "qm list"
if ($result.Success) {
    Write-Host $result.Output
}
else {
    Write-Host "No VMs found or command not available" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Example 4: Execute Multiple Commands" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Execute multiple commands in a single SSH session
$multiCommand = @"
echo '=== System Info ==='
uname -a
echo ''
echo '=== CPU Info ==='
lscpu | grep 'Model name'
echo ''
echo '=== Network Interfaces ==='
ip -brief addr
"@

Write-Info "Running multiple commands..."
$result = Invoke-ProxmoxSSH -Command $multiCommand
if ($result.Success) {
    Write-Host $result.Output
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Example 5: Custom Function Usage" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Example: Get all running VMs
function Get-ProxmoxRunningVMs {
    Write-Info "Getting running VMs..."
    $result = Invoke-ProxmoxSSH -Command "qm list | grep running"

    if ($result.Success -and $result.Output) {
        $vms = $result.Output -split "`n" | Where-Object { $_ -match '\S' }
        Write-Success "Found $($vms.Count) running VM(s)"
        return $vms
    }
    else {
        Write-Info "No running VMs found"
        return @()
    }
}

# Example: Get Proxmox cluster status
function Get-ProxmoxClusterStatus {
    Write-Info "Checking cluster status..."
    $result = Invoke-ProxmoxSSH -Command "pvecm status 2>&1"

    if ($result.ExitCode -eq 0) {
        Write-Host $result.Output
    }
    else {
        Write-Info "This Proxmox server is not part of a cluster"
    }
}

# Example: Backup a VM (example - customize as needed)
function Backup-ProxmoxVM {
    param(
        [Parameter(Mandatory=$true)]
        [int]$VMID,

        [string]$Storage = "local"
    )

    Write-Info "Starting backup of VM $VMID to storage '$Storage'..."

    $command = "vzdump $VMID --storage $Storage --mode snapshot --compress gzip"
    $result = Invoke-ProxmoxSSH -Command $command

    if ($result.Success) {
        Write-Success "Backup initiated successfully!"
        Write-Host $result.Output
    }
    else {
        Write-Error-Custom "Backup failed!"
        Write-Host $result.Output -ForegroundColor Red
    }
}

# Call the example functions
Get-ProxmoxRunningVMs
Write-Host ""
Get-ProxmoxClusterStatus

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Example 6: File Transfer (SCP)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Example: Download a file from Proxmox
function Get-ProxmoxFile {
    param(
        [Parameter(Mandatory=$true)]
        [string]$RemotePath,

        [Parameter(Mandatory=$true)]
        [string]$LocalPath
    )

    Write-Info "Downloading file from Proxmox..."
    Write-Host "  Remote: $RemotePath" -ForegroundColor White
    Write-Host "  Local:  $LocalPath" -ForegroundColor White

    $scpArgs = @(
        "-i", $SSHKeyPath,
        "-P", $ProxmoxPort,
        "$ProxmoxUser@${ProxmoxHost}:$RemotePath",
        $LocalPath
    )

    try {
        & scp $scpArgs
        if ($LASTEXITCODE -eq 0) {
            Write-Success "File downloaded successfully!"
        }
        else {
            Write-Error-Custom "File download failed!"
        }
    }
    catch {
        Write-Error-Custom "SCP error: $_"
    }
}

# Example: Upload a file to Proxmox
function Send-ProxmoxFile {
    param(
        [Parameter(Mandatory=$true)]
        [string]$LocalPath,

        [Parameter(Mandatory=$true)]
        [string]$RemotePath
    )

    if (-not (Test-Path $LocalPath)) {
        Write-Error-Custom "Local file not found: $LocalPath"
        return
    }

    Write-Info "Uploading file to Proxmox..."
    Write-Host "  Local:  $LocalPath" -ForegroundColor White
    Write-Host "  Remote: $RemotePath" -ForegroundColor White

    $scpArgs = @(
        "-i", $SSHKeyPath,
        "-P", $ProxmoxPort,
        $LocalPath,
        "$ProxmoxUser@${ProxmoxHost}:$RemotePath"
    )

    try {
        & scp $scpArgs
        if ($LASTEXITCODE -eq 0) {
            Write-Success "File uploaded successfully!"
        }
        else {
            Write-Error-Custom "File upload failed!"
        }
    }
    catch {
        Write-Error-Custom "SCP error: $_"
    }
}

# Example usage (commented out)
# Get-ProxmoxFile -RemotePath "/etc/pve/.version" -LocalPath ".\pve-version.txt"
# Send-ProxmoxFile -LocalPath ".\myfile.txt" -RemotePath "/tmp/myfile.txt"

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "All Examples Completed!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Info "You can now use these functions in your own scripts for automation"
Write-Host ""
