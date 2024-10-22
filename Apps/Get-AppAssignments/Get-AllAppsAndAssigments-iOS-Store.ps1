# Connect to Microsoft Graph using your admin account interactively
Connect-MgGraph -Scopes "DeviceManagementApps.Read.All" -NoWelcome

# Query the Microsoft Graph API for mobile apps
$response = Invoke-WebRequest -Uri 'https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps' -Method GET

# Filter the results to only include iOS Store Apps
$iosStoreApps = $response.value | Where-Object { $_.'@odata.type' -eq '#microsoft.graph.iosStoreApp' }

# Output the list of iOS Store Apps
$iosStoreApps | ForEach-Object {
    [PSCustomObject]@{
        Name = $_.displayName
        Publisher = $_.publisher
        AppId = $_.appId
        Version = $_.version
    }
} | Format-Table -AutoSize

# Disconnect from Microsoft Graph
Disconnect-MgGraph
