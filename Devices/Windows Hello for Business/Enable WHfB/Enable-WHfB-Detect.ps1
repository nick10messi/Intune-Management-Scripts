### Detect 'UsePassportForWork' Registry value
if ((Get-ItemPropertyValue 'HKLM:\SOFTWARE\Policies\Microsoft\PassportForWork' -Name 'Enabled' -ErrorAction SilentlyContinue) -eq 1) {
    Write-Host "Windows Hello for Business is ingeschakeld"
}
else {
    Write-Host "Windows Hello for Business is NIET ingeschakeld"
    exit 1
}