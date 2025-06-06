<#
.AUTHOR
    Nick Kok

.SYNOPSIS
    This script detects if all the required CIS 4.0.0 L2 Custom Settings are configured correctly.
#>

$servicesToCheck = @(
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

$nonCompliant = $false

foreach ($service in $servicesToCheck) {
    $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
    if ($svc -and $svc.StartType -ne 'Disabled') {
        $nonCompliant = $true
        break
    }
}

if ($nonCompliant) {
    Write-Output "Remediaton needed for $service"
    exit 1    
} 
else {
    write-output "No remediation needed"
    exit 0    
}