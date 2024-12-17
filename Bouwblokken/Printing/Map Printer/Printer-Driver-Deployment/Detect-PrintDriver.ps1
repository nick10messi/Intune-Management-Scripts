$PrintDriver = "DriverName INF File"
$PrintDriver1 = "DriverName INF File"
$PrintDriver2 = "DriverName INF File"
$PrintDriver3 = "DriverName INF File"

if (Get-PrinterDriver $PrintDriver) {
    Write-Host "$PrintDriver geinstalleerd op device"
}
else {
    exit 1
}

if (Get-PrinterDriver $PrintDriver1) {
    Write-Host "$PrintDriver1 geinstalleerd op device"
}
else {
    exit 1
}

if (Get-PrinterDriver $PrintDriver2) {
    Write-Host "$PrintDriver2 geinstalleerd op device"
}
else {
    exit 1
}

if (Get-PrinterDriver $PrintDriver3) {
    Write-Host "$PrintDriver3 geinstalleerd op device"
}
else {
    exit 1
}