# Connect to MS Graph
Connect-MgGraph -Scopes "DeviceManagementApps.Read.All" -NoWelcome
$mobileapps = Invoke-MgGraphRequest -Method Get -Uri 'https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps'

$OutputPath = (Join-Path $Env:USERPROFILE\Downloads "EPM-Requests.csv")

# Loop through all EPM elevation requests and export this data to a CSV-file
$mobileapps.Value | ForEach-Object {
    [PSCustomObject]@{        
        AppName = $_.displayname
        AppID = $_.id
    }
} | Export-Csv -Path $OutputPath -NoTypeInformation