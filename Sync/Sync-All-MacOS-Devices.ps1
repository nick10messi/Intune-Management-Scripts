# Credential Manager module
if (Get-Module -ListAvailable -Name Microsoft.Graph.Intune) {
    Write-Host "Microsoft Graph Intune module already installed"
} 
else {
    Install-Module -Name Microsoft.Graph.Intune -Force -Scope CurrentUser
}

Connect-MSGraph

$Devices = Get-IntuneManagedDevice -Filter "contains(operatingsystem, 'macOS')" | Get-MSGraphAllPages

Foreach ($Device in $Devices)
{
 
Invoke-IntuneManagedDeviceSyncDevice -managedDeviceId $Device.managedDeviceId
Write-Host "Sending Sync request to Device with DeviceID $($Device.managedDeviceId)" -ForegroundColor Yellow
 
}