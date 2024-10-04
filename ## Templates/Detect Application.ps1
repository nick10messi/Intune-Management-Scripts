$app = Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -like "APPNAME WMI"} | Select-Object Name -ExpandProperty Name

if (($app) -eq "APPNAME WMI") {
    Write-Output "APPNAME WMI is geïnstalleerd, doorgaan naar remediation"
    exit 1
}
else {
    Write-Output "APPNAME WMI is niet geïnstalleerd"
    exit 0
}