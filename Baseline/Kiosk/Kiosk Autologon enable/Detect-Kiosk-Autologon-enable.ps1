<#
.AUTHOR
    Nick Kok

.SYNOPSIS
    This script detects if the Kiosk Autologon feature is enabled on the system

.VERSION HISTORY
    v1.0.0 - [DD-MM-YYYY] Initial version
    v1.0.1 - [DD-MM-YYYY] ...
#>

# Define constants and variables
$logFile = Join-Path -Path $env:ProgramData -ChildPath "Microsoft\IntuneManagementExtension\Logs\Kiosk-Autologon-enable-Detect.log"

# Function to write messages to the log
function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [ValidateSet("INFO", "WARN", "ERROR")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp][$Level] $Message"
    Add-Content -Path $logFile -Value $logEntry
}

# Start logging
Write-Log -Message "Script execution started." -Level INFO

# Registry data to detect
$registryPath = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
$registryProperty = "AutoAdminLogon"
$registryValue = 1

$registryPath1 = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
$registryProperty1 = "DefaultUserName"
$registryValue1 = "kioskUser0"

$registryPath2 = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
$registryProperty2 = "IsConnectedAutoLogon"
$registryValue2 = 0

# Check if registry data exist
if ((Get-ItemPropertyValue -Path $registryPath -Name $registryProperty) -eq $registryValue) {
    Write-Log -Message "$registryProperty has the right value"
}
else {
    Write-Log -Message "$registryProperty does not has the right value. Going to remediate" -Level "ERROR"
    exit 1
}

if ((Get-ItemPropertyValue -Path $registryPath1 -Name $registryProperty1) -eq $registryValue1) {
    Write-Log -Message "$registryProperty1 has the right value"
}
else {
    Write-Log -Message "$registryProperty1 does not has the right value. Going to remediate" -Level "ERROR"
    exit 1
}

if ((Get-ItemPropertyValue -Path $registryPath2 -Name $registryProperty2) -eq $registryValue2) {
    Write-Log -Message "$registryProperty2 has the right value"
}
else {
    Write-Log -Message "$registryProperty2 does not has the right value. Going to remediate" -Level "ERROR"
    exit 1
}