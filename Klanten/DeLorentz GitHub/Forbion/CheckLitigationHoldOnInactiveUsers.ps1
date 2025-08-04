param(
    [Parameter(Mandatory = $true)]
    [string]$CustomerTenantID  # Can be a tenant ID or tenant domain
)

function Ensure_ExchangeOnlineModule36 {
    $requiredVersion = '3.6.0'
    $installedModules = Get-InstalledModule -Name ExchangeOnlineManagement -ErrorAction SilentlyContinue

    if ($installedModules -and $installedModules.Version -eq [version]$requiredVersion) {
        Write-Host "[INFO] ExchangeOnlineManagement $requiredVersion is already installed." -ForegroundColor Green
    } else {
        Write-Host "[INFO] Removing existing versions of ExchangeOnlineManagement..." -ForegroundColor Yellow
        Get-InstalledModule -Name ExchangeOnlineManagement -AllVersions -ErrorAction SilentlyContinue | Uninstall-Module -Force -AllVersions -ErrorAction SilentlyContinue

        Write-Host "[INFO] Installing version $requiredVersion of ExchangeOnlineManagement..." -ForegroundColor Cyan
        Install-Module -Name ExchangeOnlineManagement -RequiredVersion $requiredVersion -Force -AllowClobber
    }

    Import-Module ExchangeOnlineManagement -RequiredVersion $requiredVersion -Force -ErrorAction Stop
}

# Step 1: Ensure correct module version
Ensure_ExchangeOnlineModule36

# Step 2: Connect to Exchange Online
Write-Host "`n[INFO] Connecting to Exchange Online for tenant: $CustomerTenantID..." -ForegroundColor Cyan
Connect-ExchangeOnline -DelegatedOrganization $CustomerTenantID -ErrorAction Stop

# Step 3: Get inactive mailboxes
Write-Host "[INFO] Retrieving inactive mailboxes with Litigation Hold enabled..." -ForegroundColor Cyan
$inactiveMailboxes = Get-Mailbox -InactiveMailboxOnly -ResultSize Unlimited

# Step 4: Filter those with Litigation Hold enabled
$heldInactive = foreach ($mbx in $inactiveMailboxes) {
    if ($mbx.LitigationHoldEnabled) {
        [PSCustomObject]@{
            DisplayName            = $mbx.DisplayName
            UserPrincipalName      = $mbx.UserPrincipalName
            LitigationHoldEnabled  = $mbx.LitigationHoldEnabled
            LitigationHoldDuration = $mbx.LitigationHoldDuration
        }
    }
}

# Step 5: Display and export results
if ($heldInactive) {
    Write-Host "`nInactive mailboxes with Litigation Hold enabled:" -ForegroundColor Green

    $output = $heldInactive | Select-Object DisplayName, UserPrincipalName, LitigationHoldEnabled, @{
        Name = 'LitigationHoldDurationReadable'
        Expression = {
            $duration = $_.LitigationHoldDuration

            if ($duration -ne $null) {
                if ($duration -isnot [TimeSpan]) {
                    try {
                        $duration = [TimeSpan]::Parse($duration)
                    } catch {
                        return "Unknown format"
                    }
                }

                $totalDays = $duration.TotalDays
                $years = [math]::Floor($totalDays / 365)
                $months = [math]::Floor(($totalDays % 365) / 30)

                if ($years -eq 0 -and $months -eq 0) {
                    "Less than 1 month"
                } elseif ($months -eq 0) {
                    "$years year(s)"
                } else {
                    "$years year(s) and $months month(s)"
                }
            } else {
                "Permanent"
            }
        }
    } | Sort-Object DisplayName

    # Output to console
    $output | Format-Table -AutoSize

    # Export to CSV
    $csvPath = "C:\Temp\InactiveMailboxesWithLitigationHold_$($CustomerTenantID).csv"
    $output | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    Write-Host "`n[INFO] Results exported to $csvPath" -ForegroundColor Cyan
} else {
    Write-Host "No inactive mailboxes with Litigation Hold enabled were found." -ForegroundColor Yellow
}

# Step 6: Disconnect session
Disconnect-ExchangeOnline -Confirm:$false