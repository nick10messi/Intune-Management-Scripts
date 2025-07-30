param(
    [Parameter(Mandatory = $true)]
    [string]$CustomerTenantID  # Mag een tenant ID of tenant domain zijn
)

# Connect to Exchange Online
Write-Host "`n[INFO] Connecting to Exchange Online..." -ForegroundColor Cyan
Connect-ExchangeOnline -DelegatedOrganization $CustomerTenantID -ErrorAction Stop


# Retrieve all inactive mailboxes (i.e. deleted users with mailbox retention)
Write-Host "[INFO] Retrieving inactive mailboxes (deleted accounts)..." -ForegroundColor Cyan
$inactiveMailboxes = Get-Mailbox -InactiveMailboxOnly -ResultSize Unlimited

# Prepare results
$results = foreach ($mbx in $inactiveMailboxes) {
    try {
        $mbxDetails = Get-Mailbox -Identity $mbx.Guid.Guid -ErrorAction Stop

        [PSCustomObject]@{
            TenantID                = $CustomerTenantID
            DisplayName             = $mbxDetails.DisplayName
            UserPrincipalName       = $mbxDetails.UserPrincipalName
            PrimarySmtpAddress      = $mbxDetails.PrimarySmtpAddress
            WhenMailboxCreated      = $mbxDetails.WhenMailboxCreated
            LitigationHoldEnabled   = $mbxDetails.LitigationHoldEnabled
            LitigationHoldDuration  = $mbxDetails.LitigationHoldDuration
        }
    } catch {
        Write-Warning "Failed to retrieve details for mailbox: $($_.Exception.Message)"
    }
}

# Export results to CSV
$csvPath = "$env:USERPROFILE\Downloads\DeletedUsersWithLitigationHold_$($CustomerTenantID).csv"
$results | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

Write-Host "`n[INFO] Export completed. File saved to: $csvPath" -ForegroundColor Green

# Disconnect session
Disconnect-ExchangeOnline -Confirm:$false

