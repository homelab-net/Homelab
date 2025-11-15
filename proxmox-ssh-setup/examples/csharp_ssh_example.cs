/*
 * C# Example: SSH Connection to Proxmox with Key-Based Authentication
 *
 * This example demonstrates how to connect to Proxmox via SSH from C#
 * using SSH keys for passwordless authentication.
 *
 * Requirements:
 *   Install-Package SSH.NET
 *
 * Usage:
 *   1. Update the configuration variables (ProxmoxHost, etc.)
 *   2. Build and run the program
 *
 * NuGet Package:
 *   dotnet add package SSH.NET
 */

using System;
using System.IO;
using Renci.SshNet;

namespace ProxmoxSSHExample
{
    public class ProxmoxSSHClient : IDisposable
    {
        private SshClient _sshClient;
        private readonly string _hostname;
        private readonly string _username;
        private readonly int _port;
        private readonly string _privateKeyPath;

        public ProxmoxSSHClient(string hostname, string username = "root", int port = 22, string privateKeyPath = null)
        {
            _hostname = hostname;
            _username = username;
            _port = port;

            // Use default key location if not specified
            if (string.IsNullOrEmpty(privateKeyPath))
            {
                var userProfile = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
                _privateKeyPath = Path.Combine(userProfile, ".ssh", "proxmox_rsa");
            }
            else
            {
                _privateKeyPath = privateKeyPath;
            }
        }

        public bool Connect()
        {
            try
            {
                Console.WriteLine($"Connecting to {_username}@{_hostname}:{_port}");
                Console.WriteLine($"Using key: {_privateKeyPath}");

                // Check if private key exists
                if (!File.Exists(_privateKeyPath))
                {
                    Console.WriteLine($"✗ Error: SSH key not found at {_privateKeyPath}");
                    Console.WriteLine("  Run Generate-SSHKey.ps1 first to create your SSH key");
                    return false;
                }

                // Load the private key
                var keyFile = new PrivateKeyFile(_privateKeyPath);
                var keyFiles = new[] { keyFile };

                // Create connection info
                var connectionInfo = new ConnectionInfo(
                    _hostname,
                    _port,
                    _username,
                    new PrivateKeyAuthenticationMethod(_username, keyFiles)
                );

                // Create SSH client
                _sshClient = new SshClient(connectionInfo);
                _sshClient.Connect();

                Console.WriteLine("✓ Connected successfully!");
                return true;
            }
            catch (Renci.SshNet.Common.SshAuthenticationException ex)
            {
                Console.WriteLine("✗ Authentication failed!");
                Console.WriteLine("  Make sure your public key is in /root/.ssh/authorized_keys on Proxmox");
                Console.WriteLine($"  Error: {ex.Message}");
                return false;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"✗ Connection error: {ex.Message}");
                return false;
            }
        }

        public (string Output, string Error, int ExitCode) ExecuteCommand(string command)
        {
            if (_sshClient == null || !_sshClient.IsConnected)
            {
                throw new InvalidOperationException("Not connected. Call Connect() first.");
            }

            using (var cmd = _sshClient.CreateCommand(command))
            {
                var result = cmd.Execute();
                return (result, cmd.Error, cmd.ExitStatus);
            }
        }

        public void Disconnect()
        {
            if (_sshClient != null && _sshClient.IsConnected)
            {
                _sshClient.Disconnect();
                Console.WriteLine("Connection closed");
            }
        }

        public void Dispose()
        {
            Disconnect();
            _sshClient?.Dispose();
        }
    }

    class Program
    {
        static void Main(string[] args)
        {
            // Configuration - UPDATE THESE VALUES
            const string PROXMOX_HOST = "192.168.1.100";  // Your Proxmox IP
            const string PROXMOX_USER = "root";
            const int PROXMOX_PORT = 22;

            Console.WriteLine("========================================");
            Console.WriteLine("Proxmox SSH Client Example (C#)");
            Console.WriteLine("========================================");
            Console.WriteLine();

            try
            {
                // Example 1: Using 'using' statement (recommended)
                Console.WriteLine("Example 1: Basic Connection and Commands");
                Console.WriteLine("----------------------------------------");

                using (var ssh = new ProxmoxSSHClient(PROXMOX_HOST, PROXMOX_USER, PROXMOX_PORT))
                {
                    if (ssh.Connect())
                    {
                        // Get Proxmox version
                        Console.WriteLine("\nProxmox Version:");
                        var (output, error, exitCode) = ssh.ExecuteCommand("pveversion");
                        Console.WriteLine(output);

                        // Get system uptime
                        Console.WriteLine("System Uptime:");
                        (output, error, exitCode) = ssh.ExecuteCommand("uptime");
                        Console.WriteLine(output);

                        // List VMs
                        Console.WriteLine("Virtual Machines:");
                        (output, error, exitCode) = ssh.ExecuteCommand("qm list");
                        Console.WriteLine(output);
                    }
                }

                Console.WriteLine();

                // Example 2: Multiple commands with error handling
                Console.WriteLine("Example 2: Multiple Commands with Error Handling");
                Console.WriteLine("------------------------------------------------");

                using (var ssh = new ProxmoxSSHClient(PROXMOX_HOST, PROXMOX_USER, PROXMOX_PORT))
                {
                    if (ssh.Connect())
                    {
                        var commands = new[]
                        {
                            ("hostname", "Get hostname"),
                            ("df -h /", "Check disk usage"),
                            ("free -h", "Check memory usage"),
                            ("cat /etc/pve/.version", "PVE version")
                        };

                        foreach (var (cmd, description) in commands)
                        {
                            Console.WriteLine($"\n{description}:");

                            var (output, error, exitCode) = ssh.ExecuteCommand(cmd);

                            if (exitCode == 0)
                            {
                                Console.WriteLine(output.TrimEnd());
                            }
                            else
                            {
                                Console.WriteLine($"Error (exit code {exitCode}): {error}");
                            }
                        }
                    }
                }

                Console.WriteLine();

                // Example 3: Custom helper methods
                Console.WriteLine("Example 3: Custom Helper Methods");
                Console.WriteLine("---------------------------------");

                using (var ssh = new ProxmoxSSHClient(PROXMOX_HOST, PROXMOX_USER, PROXMOX_PORT))
                {
                    if (ssh.Connect())
                    {
                        // Get system info
                        GetSystemInfo(ssh);

                        // Get running VMs
                        GetRunningVMs(ssh);

                        // Check cluster status
                        CheckClusterStatus(ssh);
                    }
                }

                Console.WriteLine();
                Console.WriteLine("========================================");
                Console.WriteLine("All Examples Completed!");
                Console.WriteLine("========================================");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error: {ex.Message}");
                Console.WriteLine(ex.StackTrace);
            }

            Console.WriteLine("\nPress any key to exit...");
            Console.ReadKey();
        }

        static void GetSystemInfo(ProxmoxSSHClient ssh)
        {
            Console.WriteLine("\nSystem Information:");
            Console.WriteLine("------------------");

            var (output, _, exitCode) = ssh.ExecuteCommand(@"
                echo 'Hostname:' $(hostname)
                echo 'Kernel:' $(uname -r)
                echo 'Uptime:' $(uptime -p)
            ");

            if (exitCode == 0)
            {
                Console.WriteLine(output);
            }
        }

        static void GetRunningVMs(ProxmoxSSHClient ssh)
        {
            Console.WriteLine("\nRunning Virtual Machines:");
            Console.WriteLine("------------------------");

            var (output, error, exitCode) = ssh.ExecuteCommand("qm list | grep running");

            if (exitCode == 0 && !string.IsNullOrWhiteSpace(output))
            {
                var vms = output.Split('\n', StringSplitOptions.RemoveEmptyEntries);
                Console.WriteLine($"Found {vms.Length} running VM(s)");
                Console.WriteLine(output);
            }
            else
            {
                Console.WriteLine("No running VMs found");
            }
        }

        static void CheckClusterStatus(ProxmoxSSHClient ssh)
        {
            Console.WriteLine("\nCluster Status:");
            Console.WriteLine("---------------");

            var (output, error, exitCode) = ssh.ExecuteCommand("pvecm status 2>&1");

            if (exitCode == 0)
            {
                Console.WriteLine(output);
            }
            else
            {
                Console.WriteLine("This Proxmox server is not part of a cluster");
            }
        }
    }

    // Example: Async version for better performance
    public class ProxmoxSSHClientAsync : IDisposable
    {
        private SshClient _sshClient;
        private readonly string _hostname;
        private readonly string _username;
        private readonly int _port;
        private readonly string _privateKeyPath;

        public ProxmoxSSHClientAsync(string hostname, string username = "root", int port = 22, string privateKeyPath = null)
        {
            _hostname = hostname;
            _username = username;
            _port = port;

            if (string.IsNullOrEmpty(privateKeyPath))
            {
                var userProfile = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
                _privateKeyPath = Path.Combine(userProfile, ".ssh", "proxmox_rsa");
            }
            else
            {
                _privateKeyPath = privateKeyPath;
            }
        }

        public async System.Threading.Tasks.Task<bool> ConnectAsync()
        {
            return await System.Threading.Tasks.Task.Run(() =>
            {
                try
                {
                    var keyFile = new PrivateKeyFile(_privateKeyPath);
                    var connectionInfo = new ConnectionInfo(
                        _hostname,
                        _port,
                        _username,
                        new PrivateKeyAuthenticationMethod(_username, keyFile)
                    );

                    _sshClient = new SshClient(connectionInfo);
                    _sshClient.Connect();
                    return true;
                }
                catch
                {
                    return false;
                }
            });
        }

        public async System.Threading.Tasks.Task<(string Output, string Error, int ExitCode)> ExecuteCommandAsync(string command)
        {
            return await System.Threading.Tasks.Task.Run(() =>
            {
                using (var cmd = _sshClient.CreateCommand(command))
                {
                    var result = cmd.Execute();
                    return (result, cmd.Error, cmd.ExitStatus);
                }
            });
        }

        public void Dispose()
        {
            _sshClient?.Disconnect();
            _sshClient?.Dispose();
        }
    }
}

/*
 * Example .csproj file:
 *
 * <Project Sdk="Microsoft.NET.Sdk">
 *   <PropertyGroup>
 *     <OutputType>Exe</OutputType>
 *     <TargetFramework>net6.0</TargetFramework>
 *   </PropertyGroup>
 *   <ItemGroup>
 *     <PackageReference Include="SSH.NET" Version="2023.0.0" />
 *   </ItemGroup>
 * </Project>
 */
