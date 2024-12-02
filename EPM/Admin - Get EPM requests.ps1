# Connect to MS Graph
Connect-MgGraph -Scopes "DeviceManagementConfiguration.Read.All" -NoWelcome

# Retrieve data from Graph API
$epmRequests = Invoke-MgGraphRequest -Method Get -Uri 'https://graph.microsoft.com/beta/deviceManagement/elevationRequests'

$OutputPath = (Join-Path $Env:USERPROFILE\Downloads "EPM-Requests.csv")

# Loop through all EPM elevation requests and export this data to a CSV-file
$epmRequests.Value | ForEach-Object {
    [PSCustomObject]@{        
        Aanvrager = $_.requestedByUserPrincipalName
        Aanvraagdatum = $_.requestCreatedDateTime
        Reden = $_.requestJustification
        Status = $_.status
        Reviewer = $_.reviewCompletedByUserPrincipalName
        Beoordelingsdatum = $_.reviewCompletedDateTime
        Beoordelingsreden = $_.reviewerJustification
        Bestandsnaam = $_.applicationDetail.fileName
        Bestandspad = $_.applicationDetail.filePath
        Uitgever = $_.applicationDetail.publisherName
        Versie = $_.applicationDetail.productVersion
    }
} | Export-Csv -Path $OutputPath -NoTypeInformation