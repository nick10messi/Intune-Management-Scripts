<#
.AUTHOR
    Nick Kok

.SYNOPSIS
    This script configures all the required CIS 4.0.0 L1 Custom Settings which cannot be deployed with the Intune Settings Catalog.
#>

$servicesToDisable = @(
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