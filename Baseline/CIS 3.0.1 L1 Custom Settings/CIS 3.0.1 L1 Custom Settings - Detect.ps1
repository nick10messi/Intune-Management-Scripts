<#
.AUTHOR
    Nick Kok

.SYNOPSIS
    This script detects if all the required CIS 3.0.1 L1 Custom Settings are configured correctly.
#>

# Define constants and variables
$logFile = Join-Path -Path $env:ProgramData -ChildPath "Microsoft\IntuneManagementExtension\Logs\CIS-3.0.1-L1-Custom-Settings-Detect.log"

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

$serviceName = "sshd"

try {
    $service = Get-CimInstance -ClassName Win32_Service -Filter "Name='$serviceName'" -ErrorAction SilentlyContinue
    if ($service.StartMode -ne "Disabled") {
        Write-Log -Message "$serviceName is not Disabled"
        exit 1
    } else {
        Write-Log -Message "$serviceName is correctly set to Disabled"
        exit 0
    }
} catch {
    Write-Log -Message "Service $serviceName not found or error occurred: $_" -Level "ERROR"
    exit 0
}