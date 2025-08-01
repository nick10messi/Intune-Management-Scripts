###########################################################################
# Auteur      : Nick Kok
# Doel        : Uninstall unwanted Windows-apps
# Versie      : 1.0
# Datum       : 28-07-2025
###########################################################################

Function Write-Log {
    Param (
        [string]$Message,
        [ValidateSet("INFO","WARN","ERROR")]
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp [$Level] : $Message" | Out-File -FilePath "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\Remove_Unwanted_Apps-Remediate.log" -Append -Encoding utf8
}

$appsToRemove = @(
    "Microsoft.GamingApp",
    "Microsoft.Xbox.TCUI",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxLive",
    "Microsoft.SkypeApp",
    "Microsoft.Getstarted",
    "Microsoft.WindowsMaps",
    "Microsoft.MixedReality.Portal",
    "Microsoft.ZuneVideo",
    "Microsoft.MSPaint",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.Edge.GameAssist",
    "MicrosoftCorporationII.MicrosoftFamily"
)

foreach ($app in $appsToRemove) {
    $pkg = Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue
    if ($pkg) {
        try {
            Write-Log -Message "Verwijderen: $app" -Level "INFO"
            Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers
        } catch {
            Write-Log -Message "Fout bij verwijderen van $app : $($_)" -Level "ERROR"
        }
    }
}

Write-Log -Message "Verwijderingsproces voltooid." -Level "INFO"
exit 0