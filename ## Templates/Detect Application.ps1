$app = Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -like "APPNAME WMI"} | Select-Object Name -ExpandProperty Name

if (($app) -eq "APPNAME WMI") {
    exit 1
}
else {
    exit 0
}