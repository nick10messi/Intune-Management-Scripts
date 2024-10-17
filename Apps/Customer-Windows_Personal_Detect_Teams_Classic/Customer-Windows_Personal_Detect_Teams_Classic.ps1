$app = Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Teams" -ErrorAction SilentlyContinue | Select-Object DisplayName -ExpandProperty DisplayName

if ($app -eq "Microsoft Teams classic") {
    Write-Output "Classic Teams installed"
    exit 1
}
else {
    Write-Output "NO Classic Teams"
    exit 0
}