$app = Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -like "Teams Machine-Wide Installer"} | select-object name -ExpandProperty name

if ($app -eq "Teams Machine-Wide Installer") {
    Write-output "Old Teams installed"
    exit 1
}
else {
    Write-output "Old Teams not installed"
    exit 0
}