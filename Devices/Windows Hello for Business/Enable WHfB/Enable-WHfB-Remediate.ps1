### Remediate 'UsePassportForWork' Registry value
if ((Get-ItemPropertyValue 'HKLM:\SOFTWARE\Policies\Microsoft\PassportForWork' -Name 'Enabled' -ErrorAction SilentlyContinue) -eq 1) {
    Write-Host "Windows Hello for Business is ingeschakeld"
}
else {
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\PassportForWork' -Force
    New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\PassportForWork' -Name 'Enabled' -Value 1 -Force
}

### Also check this path on device: HKLM:\SOFTWARE\Microsoft\Policies\PassportForWork\<guid>\Device\Policies -UseCloudTrustForOnPremAuth