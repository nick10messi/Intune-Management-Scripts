# Check required modules
if (Get-Module "Microsoft.Graph" -ListAvailable) {
    Write-Output "Microsoft.Graph is aanwezig"
}
else{
    Install-Module -Name Microsoft.Graph -Force
}

if (Get-Module "WindowsAutoPilotIntune" -ListAvailable) {
    Write-Output "WindowsAutoPilotIntune is aanwezig"
}
else{
    Install-Module -Name WindowsAutoPilotIntune -Force
}

# Connect to customer tenant
Connect-MgGraph -Scopes "Group.ReadWrite.All, Device.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All, DeviceManagementServiceConfig.ReadWrite.All, GroupMember.ReadWrite.All"

####################################################################################################
######## variabeles ########

# Specify the old group tag here test1234
$oldGrouptag = Read-Host "Voer de HUIDIGE grouptag in van de devices die aangepast moeten worden"

# Specify the new group tag here
$newGrouptag = Read-Host "Voer de nieuwe grouptag in van de devices die aangepast moeten worden"
####################################################################################################

# Get all Autopilot devices
$devices = Get-AutopilotDevice | Where-Object GroupTag -EQ $oldGrouptag

# Change Grouptag for each resulted device
foreach ($device in $devices) {
    try {
        Set-AutopilotDevice -id $device.id -groupTag $newGrouptag
        Write-Output "Group tag aangepast naar $newGrouptag voor $device.id"
    }
    catch {
        $message = $_.Exception.Message
        Write-Output "Group tag aanpassen gefaald voor apparaat met serienummer $($device.serialNumber): $message"
    }    
}

# Disconnect Graph from customer tenant
Disconnect-MgGraph