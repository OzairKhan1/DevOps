# ConfigureRemotingForAnsible.ps1
# This script configures WinRM for Ansible use.

# Run this in PowerShell as Administrator

# Enable PS Remoting
Enable-PSRemoting -Force

# Allow Unencrypted traffic
Set-Item -Path WSMan:\localhost\Service\AllowUnencrypted -Value $true

# Allow Basic Auth
Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true

# Set firewall rule
Enable-WSManCredSSP -Role Server -Force

# Create WinRM listener
$listener = Get-ChildItem -Path WSMan:\Localhost\Listener | Where-Object { $_.Keys -contains "Transport=HTTP" }
if (-not $listener) {
    New-Item -Path WSMan:\Localhost\Listener -Transport HTTP -Address * -Force
}

# Allow the WinRM service through Windows Firewall
netsh advfirewall firewall add rule name="Ansible WinRM" dir=in action=allow protocol=TCP localport=5985

Write-Host "WinRM has been configured successfully for Ansible"
