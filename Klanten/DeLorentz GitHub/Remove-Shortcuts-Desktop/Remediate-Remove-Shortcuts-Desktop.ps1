###########################################################################
# Auteur      : Nick Kok
# Doel        : Verwijdert ongewenste snelkoppelingen (.lnk en .url) 
#               van desktop (gebruiker én publiek)
# Versie      : 1.3
# Datum       : 26-09-2025
###########################################################################

Function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("INFO","WARN","ERROR")][string]$Level = "INFO"
    )
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogFile = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\Remove-DesktopShortcuts-Remediate.log"
    Add-Content -Path $LogFile -Value "$TimeStamp [$Level] - $Message"
}

Function Get-LoggedOnUserDesktopPath {
    $RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI"
    $SID = (Get-ItemProperty -Path $RegPath -Name LastLoggedOnUserSID).LastLoggedOnUserSID
    if ($SID) {
        $UserProfile = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$SID").ProfileImagePath
        return Join-Path -Path $UserProfile -ChildPath "Desktop"
    }
    return $null
}

Write-Log -Message "Start verwijdering van ongewenste snelkoppelingen." -Level "INFO"

# Zowel .lnk als .url opnemen
$ShortcutsToRemove = @(
    "Google Chrome.lnk",
    "Microsoft Edge.lnk",
    "FortiClient VPN.lnk",
    "Adobe Acrobat.lnk",
    "Outlook.lnk",
    "Word.lnk",
    "Excel.lnk",
    "Powerpoint.lnk",
    "Uurwerk.lnk",
    "Uurwerk.url",
    "Yesplan.lnk",
    "Yesplan.url",
    "Topdesk.lnk",
    "Topdesk.url",
    "Maak verbinding met G-schijf.lnk",
    "Maak verbinding met G-schijf.url"
)

$DesktopPaths = @(
    "$env:PUBLIC\Desktop"
)

foreach ($Path in $DesktopPaths) {
    if (-not [string]::IsNullOrWhiteSpace($Path) -and (Test-Path $Path)) {
        foreach ($Shortcut in $ShortcutsToRemove) {
            $FullPath = Join-Path -Path $Path -ChildPath $Shortcut
            if (Test-Path $FullPath) {
                try {
                    Remove-Item -Path $FullPath -Force
                    Write-Log -Message "Verwijderd: $FullPath" -Level "INFO"
                } catch {
                    Write-Log -Message "Fout bij verwijderen van $FullPath - $_" -Level "ERROR"
                }
            } else {
                Write-Log -Message "Niet gevonden (overslaan): $FullPath" -Level "INFO"
            }
        }
    } else {
        Write-Log -Message "Ongeldig pad overgeslagen: '$Path'" -Level "WARN"
    }
}

Write-Log -Message "Verwijdering voltooid." -Level "INFO"
exit 0
