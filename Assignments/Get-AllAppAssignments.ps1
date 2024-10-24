# Get Intune Apps and their Assignments
$apps = Get-MgDeviceAppManagementMobileApp | Select-Object Id, DisplayName

$results = foreach ($app in $apps) {
    $assignments = Get-MgDeviceAppManagementMobileAppAssignment -MobileAppId $app.Id
    Write-Output $assignments
    foreach ($assignment in $assignments) {
        if ($groupId -eq 'acacacac-9df4-4c7d-9d50-4ef0226f57a9_1_0') {
            $groupName = 'All Users'
        } elseif ($groupId -eq 'adadadad-808e-44e2-905a-0b7873a8a531_1_0') {
            $groupName = 'All Devices'
        } else {
            $group = Get-MgGroup -GroupId $groupId
            $groupName = $group.DisplayName
        }
        [PSCustomObject]@{
            'App ID'        = $app.Id
            'Displayname'   = $app.DisplayName
            'Intent'        = $assignment.Intent
            'Groupname'     = $groupName
        }
    }
}

# Export to CSV
$results | Export-Csv -Path "$env:USERPROFILE\Downloads\IntuneAppsAssignments.csv" -NoTypeInformation
