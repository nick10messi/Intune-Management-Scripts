# Enable Sudo by setting registry key
$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Sudo"
$registryName = "Enabled"
$registryValue = 3

Set-ItemProperty -Path $registryPath -Name $registryName -Value $registryValue -Force
Write-Output "Sudo has been enabled."