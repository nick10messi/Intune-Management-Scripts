<#
.AUTHOR
    Nick Kok

.SYNOPSIS
    This script configures all the required CIS 4.0.0 L2 Custom Settings which cannot be deployed with the Intune Settings Catalog.
#>

$servicesToDisable = @(
    "BTAGService",
    "bthserv",
    "MapsBroker",
    "GameInputSvc",
    "lfsvc",
    "lltdsvc",
    "MSiSCSI",
    "Spooler",
    "wercplsupport",
    "RasAuto",
    "SessionEnv",
    "TermService",
    "UmRdpService",
    "RemoteRegistry",
    "LanmanServer",
    "SNMP",
    "WerSvc",
    "Wecsvc",
    "WpnService",
    "PushToInstall",
    "WinRM",
    "WinHttpAutoProxySvc"
)

foreach ($service in $servicesToDisable) {
    $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
    if ($svc) {
        try {
            Set-Service -Name $service -StartupType Disabled -ErrorAction Stop
        } catch {
            Write-Output "Could not alter service $service : $_"
        }
    }
}