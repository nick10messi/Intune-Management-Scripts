# Enable Sudo by setting registry key
$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Sudo"
$registryName = "Enabled"
$registryValue = 3

New-Item -Path $registryPath -Force | Out-Null
Set-ItemProperty -Path $registryPath -Name $registryName -Value $registryValue
Write-Output "Sudo has been enabled."