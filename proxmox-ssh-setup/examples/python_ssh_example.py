"""
Python Example: Connecting to Proxmox via SSH with Key-Based Authentication

This script demonstrates how to programmatically connect to Proxmox
using SSH keys (passwordless authentication) from Python.

Requirements:
    pip install paramiko

Usage:
    python python_ssh_example.py
"""

import paramiko
import os
from pathlib import Path


class ProxmoxSSHClient:
    """Simple SSH client for Proxmox using key-based authentication"""

    def __init__(self, hostname, username='root', port=22, key_filename=None):
        """
        Initialize Proxmox SSH client

        Args:
            hostname (str): Proxmox server IP or hostname
            username (str): SSH username (default: 'root')
            port (int): SSH port (default: 22)
            key_filename (str): Path to private key file (default: ~/.ssh/proxmox_rsa)
        """
        self.hostname = hostname
        self.username = username
        self.port = port

        # Use default key location if not specified
        if key_filename is None:
            home = str(Path.home())
            self.key_filename = os.path.join(home, '.ssh', 'proxmox_rsa')
        else:
            self.key_filename = key_filename

        self.client = None

    def connect(self):
        """Establish SSH connection to Proxmox"""
        try:
            self.client = paramiko.SSHClient()
            self.client.set_missing_host_key_policy(paramiko.AutoAddHostPolicy())

            print(f"Connecting to {self.username}@{self.hostname}:{self.port}")
            print(f"Using key: {self.key_filename}")

            self.client.connect(
                hostname=self.hostname,
                port=self.port,
                username=self.username,
                key_filename=self.key_filename,
                look_for_keys=True,
                allow_agent=True
            )

            print("✓ Connected successfully!")
            return True

        except FileNotFoundError:
            print(f"✗ Error: SSH key not found at {self.key_filename}")
            print("  Run Generate-SSHKey.ps1 first to create your SSH key")
            return False

        except paramiko.AuthenticationException:
            print("✗ Authentication failed!")
            print("  Make sure your public key is in /root/.ssh/authorized_keys on Proxmox")
            return False

        except paramiko.SSHException as e:
            print(f"✗ SSH error: {e}")
            return False

        except Exception as e:
            print(f"✗ Connection error: {e}")
            return False

    def execute_command(self, command):
        """
        Execute a command on the Proxmox server

        Args:
            command (str): Command to execute

        Returns:
            tuple: (stdout, stderr, exit_status)
        """
        if self.client is None:
            raise Exception("Not connected. Call connect() first.")

        stdin, stdout, stderr = self.client.exec_command(command)

        stdout_text = stdout.read().decode('utf-8')
        stderr_text = stderr.read().decode('utf-8')
        exit_status = stdout.channel.recv_exit_status()

        return stdout_text, stderr_text, exit_status

    def close(self):
        """Close the SSH connection"""
        if self.client:
            self.client.close()
            print("Connection closed")

    def __enter__(self):
        """Context manager entry"""
        self.connect()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit"""
        self.close()


def main():
    """Example usage of ProxmoxSSHClient"""

    # Configuration - UPDATE THESE VALUES
    PROXMOX_HOST = "192.168.1.100"  # Your Proxmox IP
    PROXMOX_USER = "root"
    PROXMOX_PORT = 22

    print("=" * 50)
    print("Proxmox SSH Client Example")
    print("=" * 50)
    print()

    # Example 1: Using context manager (recommended)
    print("Example 1: Using context manager")
    print("-" * 50)
    try:
        with ProxmoxSSHClient(PROXMOX_HOST, PROXMOX_USER, PROXMOX_PORT) as ssh:
            # Get Proxmox version
            stdout, stderr, status = ssh.execute_command('pveversion')
            print(f"Proxmox Version:\n{stdout}")

            # Get system uptime
            stdout, stderr, status = ssh.execute_command('uptime')
            print(f"System Uptime:\n{stdout}")

            # List VMs
            stdout, stderr, status = ssh.execute_command('qm list')
            print(f"Virtual Machines:\n{stdout}")

    except Exception as e:
        print(f"Error: {e}")

    print()

    # Example 2: Manual connection management
    print("Example 2: Manual connection management")
    print("-" * 50)

    ssh = ProxmoxSSHClient(PROXMOX_HOST, PROXMOX_USER, PROXMOX_PORT)

    if ssh.connect():
        try:
            # Execute multiple commands
            commands = [
                ('hostname', 'Get hostname'),
                ('df -h /', 'Check disk usage'),
                ('pvecm status', 'Cluster status'),
                ('cat /etc/pve/.version', 'PVE version')
            ]

            for cmd, description in commands:
                print(f"\n{description}:")
                stdout, stderr, status = ssh.execute_command(cmd)

                if status == 0:
                    print(stdout.strip())
                else:
                    print(f"Error: {stderr.strip()}")

        finally:
            ssh.close()

    print()
    print("=" * 50)
    print("Examples completed!")
    print("=" * 50)


if __name__ == "__main__":
    main()
