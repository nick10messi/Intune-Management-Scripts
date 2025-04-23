<#
.AUTHOR
    Nick Kok

.SYNOPSIS
    This script configures all the required CIS 3.0.1 L1 Custom Settings which cannot be deployed with the Intune Settings Catalog.
#>

# Define constants and variables
$logFile = Join-Path -Path $env:ProgramData -ChildPath "Microsoft\IntuneManagementExtension\Logs\CIS-3.0.1-L1-Custom-Settings-Remediate.log"

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

# Ensure 'OpenSSH SSH Server (sshd)' is set to 'Disabled'
$serviceName = "sshd"

try {
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    Set-Service -Name $serviceName -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Log -Message "Set $serviceName to Disabled"
} catch {
    Write-Log -Message "Service $serviceName not found or error occurred: $_"
}