# Connect to MS Graph
Connect-MgGraph -Scopes "DeviceManagementApps.Read.All,Group.Read.All" -NoWelcome

# CSV location
$CSV_location = "$env:USERPROFILE\Downloads\IntuneAppAssignments.csv"

# Get the app IDs and display names of all Intune apps in a single query
$appInfo = Get-MgDeviceAppManagementMobileApp | Select-Object Id, DisplayName

# Export to CSV, ensuring only ID and DisplayName columns are present
$appInfo | Export-Csv -Path $CSV_location -NoTypeInformation -Force