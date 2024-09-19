# Define the registry key path and value
$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\MfaRequiredInClipRenew"
$registryValueName = "Verify Multifactor Authentication in ClipRenew"
$registryValueData = 0  # DWORD value of 0
$sid = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-4")  

# Check if the registry key already exists
if (-not (Test-Path -Path $registryPath)) {
    Write-Output "Regkey bestaat niet, aanmaken"
    exit 1
} else {
    Write-Output "Registry key bestaat al"
    exit 0
}