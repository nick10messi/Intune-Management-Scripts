# Connect to Microsoft Graph
Connect-MgGraph -Scopes Group.Read.All, DeviceManagementManagedDevices.Read.All, DeviceManagementServiceConfig.Read.All, DeviceManagementApps.Read.All, DeviceManagementApps.ReadWrite.All, DeviceManagementConfiguration.Read.All, DeviceManagementConfiguration.ReadWrite.All -NoWelcome

# Applications
$Resource = "deviceAppManagement/mobileApps"
$graphApiVersion = "Beta"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$filter=(isAssigned eq true)&`$expand=Assignments"

$Apps = (Invoke-MgGraphRequest -Method GET -Uri $uri).Value | Where-Object {$_.assignments.intent -like "required"}

# Prepare data for CSV
$ExportData = @()

foreach ($App in $Apps) {
    $AppName = $App.DisplayName

    if ($App.assignments.id -like "acacacac-9df4-4c7d-9d50-4ef0226f57a9*" -or $App.assignments.id -like "adadadad-808e-44e2-905a-0b7873a8a531*") {
        if ($App.assignments.id -like "acacacac-9df4-4c7d-9d50-4ef0226f57a9*") {
            $ExportData += [PSCustomObject]@{
                AppName     = $AppName
                Assignment  = "Required"
                GroupName   = "All Users (Built-in Group)"
            }
        }
        if ($App.assignments.id -like "adadadad-808e-44e2-905a-0b7873a8a531*") {
            $ExportData += [PSCustomObject]@{
                AppName     = $AppName
                Assignment  = "Required"
                GroupName   = "All Devices (Built-in Group)"
            }
        }
    }
    else {
        $EIDGroupId = $App.assignments.target.groupId

        foreach ($group in $EIDGroupId) {
            $EIdGroup = Get-MgGroup -Filter "Id eq '$group'" -ErrorAction Continue
            $AssignIntent = $App.assignments | Where-Object -Property id -like "$group*"

            $ExportData += [PSCustomObject]@{
                AppName     = $AppName
                Assignment  = $AssignIntent.intent
                GroupName   = $EIdGroup.displayName
            }
        }
    }
}

# Export to CSV
$ExportPath = "$env:USERPROFILE\Downloads\IntuneRequiredApps.csv"
$ExportData | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8

Write-Host "Data exported to $ExportPath" -ForegroundColor Green