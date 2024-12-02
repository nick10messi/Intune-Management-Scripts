#Author : Nick Kok
#Version : 1.1 
#Date : 1-3-2023

$OSDModule = Get-InstalledModule | Where-Object {$_.Name -eq "OSD"}

if (-NOT($OSDModule)) {
    Write-Host "OSD Module not installed, installing the module" -ForegroundColor Yellow
    Install-Module -Name OSD -Force
    Import-Module OSD -Force
}

# Get USB drive
Get-Disk | Where-Object BusType -eq 'USB'
Write-Host " "
$USB = Read-Host "Voer het nummer in van de gewenste USB"

# Clear and convert USB drive
Clear-Disk -Number $USB -RemoveData -RemoveOEM -Confirm:$false
Set-Disk -Number $USB -PartitionStyle MBR

# Remove previous downloaded ISO from download folder
$ISO_Path = "$env:USERPROFILE\Downloads\Windows*.iso"
Remove-Item -Path $ISO_Path -Force

# Create OSDCloud USB
Start-Process -FilePath "PowerShell" -ArgumentList "New-OSDCloudUSB -fromIsoUrl https://occwsendpointmanager.blob.core.windows.net/osdv3/OSDBuilds/OSDCloud_NL_W11_23H2_RGF_31-10-2024.iso"