<#
.AUTHOR
    Nick Kok

.SYNOPSIS
    This script sets the registry property HiberbootEnabled on value 1 (Disable Fast Startup)

.VERSION HISTORY
    v1.0.0 - [DD-MM-YYYY] Initial version
    v1.0.1 - [DD-MM-YYYY] ...
#>

# Define constants and variables
$logFile = Join-Path -Path $env:ProgramData -ChildPath "Microsoft\IntuneManagementExtension\Logs\TITLE-Remediate.log"

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
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
$registryProperty = "HiberbootEnabled"
$registryValue = 1

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