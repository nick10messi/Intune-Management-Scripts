$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Sudo"
$registryName = "Enabled"
$sudoEnabled = (Get-ItemProperty -Path $registryPath -Name $registryName -ErrorAction SilentlyContinue).Enabled -eq 3

If ($sudoEnabled) {
    Write-Output "Sudo is already enabled."
    exit 0
} else {
    Write-Output "Sudo is not enabled."
    exit 1
}