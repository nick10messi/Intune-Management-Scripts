$Logname = "Microsoft-Windows-User Device Registration/Admin"
$Message_ENG = "Cloud trust for on premise auth policy is enabled: Yes"
$Message_NL = "Cloud vertrouwen voor on-premises authenticatiebeleid ingeschakeld: Yes"

$path = "HKLM:\SOFTWARE\Policies\Microsoft\PassportForWork"
$key = "UseCloudTrustForOnPremAuth" 

# Check for specifric Event Viewer entries
if (Get-WinEvent -LogName $Logname | Where-Object {($_.Message -match $Message_ENG) -or ($_.Message -match $Message_NL)}) {
    Write-Output "Cloud trust is ingeschakeld"
    exit 0
}
else {
    Write-Output "Cloud Trust niet ingeschakeld. Verder met andere checks"
}

# Check if the registry key exists
if (Get-ItemProperty -Path $path -ErrorAction SilentlyContinue) {
    Write-Output "$path bestaat al"
    exit 0
}
else {
    Write-Host "$path bestaat nog niet, remediating"
    exit 1
}