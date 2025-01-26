<#
.AUTHOR
    Nick Kok

.SYNOPSIS
    This script enables the Kiosk AutoLogon feature

.VERSION HISTORY
    v1.0.0 - [DD-MM-YYYY] Initial version
    v1.0.1 - [DD-MM-YYYY] ...
#>

# Define constants and variables
$logFile = Join-Path -Path $env:ProgramData -ChildPath "Microsoft\IntuneManagementExtension\Logs\Kiosk-Autologon-enable-Remediate.log"

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
Write-Log -Message "Script execution started."

# Registry data to set
$registryPath = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
$registryProperty = "AutoAdminLogon"
$registryValue = 1

$registryPath1 = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
$registryProperty1 = "DefaultUserName"
$registryValue1 = "kioskUser0"

$registryPath2 = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
$registryProperty2 = "IsConnectedAutoLogon"
$registryValue2 = 0

# Set registry data
try {
    # Check if registry key exists. If not, then create it
    if (Get-ItemProperty -Path $registryPath -ErrorAction SilentlyContinue) {
        Write-Log -Message "$registryPath does already exist. Going further"
    }
    else {
        Write-Log -Message "$registryPath does not exist. Going to create"
        New-Item -Path $registryPath -Force | Out-Null
    }

    #Create registry property and set it on desired value
    New-ItemProperty -Path $registryPath -Name $registryProperty -Value $registryValue -Force | Out-Null
}
catch {
    Write-Log -Message "An error occurred during remediation: $_" -Level "ERROR"
    exit 1
}

try {
    # Check if registry key exists. If not, then create it
    if (Get-ItemProperty -Path $registryPath1 -ErrorAction SilentlyContinue) {
        Write-Log -Message "$registryPath1 does already exist. Going further"
    }
    else {
        Write-Log -Message "$registryPath1 does not exist. Going to create"
        New-Item -Path $registryPath1 -Force | Out-Null
    }

    #Create registry property and set it on desired value
    New-ItemProperty -Path $registryPath1 -Name $registryProperty1 -Value $registryValue1 -Force | Out-Null
}
catch {
    Write-Log -Message "An error occurred during remediation: $_" -Level "ERROR"
    exit 1
}

try {
    # Check if registry key exists. If not, then create it
    if (Get-ItemProperty -Path $registryPath2 -ErrorAction SilentlyContinue) {
        Write-Log -Message "$registryPath2 does already exist. Going further"
    }
    else {
        Write-Log -Message "$registryPath2 does not exist. Going to create"
        New-Item -Path $registryPath2 -Force | Out-Null
    }

    #Create registry property and set it on desired value
    New-ItemProperty -Path $registryPath2 -Name $registryProperty2 -Value $registryValue2 -Force | Out-Null
}
catch {
    Write-Log -Message "An error occurred during remediation: $_" -Level "ERROR"
    exit 1
}