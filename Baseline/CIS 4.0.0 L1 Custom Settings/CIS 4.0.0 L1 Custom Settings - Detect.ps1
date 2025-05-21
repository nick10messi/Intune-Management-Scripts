<#
.AUTHOR
    Nick Kok

.SYNOPSIS
    This script detects if all the required CIS 4.0.0 L1 Custom Settings are configured correctly.
#>

$servicesToCheck = @(
    "IISADMIN",
    "irmon",
    "LxssManager",
    "FTPSVC",
    "sshd",
    "RpcLocator",
    "RemoteAccess",
    "simptcp",
    "sacsvr",
    "SSDPSRV",
    "upnphost",
    "WMSvc",
    "WMPNetworkSvc",
    "icssvc",
    "W3SVC"
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