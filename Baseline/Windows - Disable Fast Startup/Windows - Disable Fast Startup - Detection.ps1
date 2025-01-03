<#
.AUTHOR
    Nick Kok

.SYNOPSIS
    This script detects if the registry property HiberbootEnabled has value 1 (Disable Fast Startup)

.VERSION HISTORY
    v1.0.0 - [DD-MM-YYYY] Initial version
    v1.0.1 - [DD-MM-YYYY] ...
#>

# Define constants and variables
$logFile = Join-Path -Path $env:ProgramData -ChildPath "Microsoft\IntuneManagementExtension\Logs\TITLE-Detect.log"

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

# Registry data to detect
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
$registryProperty = "HiberbootEnabled"
$registryValue = 1

# Check if registry data exist
if ((Get-ItemPropertyValue -Path $registryPath -Name $registryProperty) -eq $registryValue) {
    Write-Log -Message "$registryProperty has the right value"
    exit 0
}
else {
    Write-Log -Message "$registryProperty does not has the right value. Going to remediate" -Level "ERROR"
    exit 1
}