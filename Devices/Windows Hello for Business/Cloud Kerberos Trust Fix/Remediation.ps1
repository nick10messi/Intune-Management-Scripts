$path = "HKLM:\SOFTWARE\Policies\Microsoft\PassportForWork"
$key = "UseCloudTrustForOnPremAuth" 

# # Check if the registry key exists
if (Get-ItemProperty -Path $path -ErrorAction SilentlyContinue) {
    Write-Output "$path bestaat al"
}
else {
    Write-Output "$path bestaat nog niet, aanmaken"
    New-item -Path $path -Force
    New-ItemProperty -Path $path -Name $key -Value 1 -Force
}