###########################################################################
# Auteur      : Nick Kok
# Doel        : Verwijdert ongewenste snelkoppelingen van de desktop (gebruiker én publiek)
# Versie      : 1.0
# Datum       : 25-09-2025
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

Write-Log -Message "Start verwijdering van ongewenste snelkoppelingen." -Level "INFO"

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
    "Yesplan.lnk",
    "Topdesk.lnk"
)

$DesktopPaths = @(
    [Environment]::GetFolderPath("Desktop"),
    "$env:PUBLIC\Desktop"
)

foreach ($Path in $DesktopPaths) {
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
}

Write-Log -Message "Verwijdering voltooid." -Level "INFO"
exit 0