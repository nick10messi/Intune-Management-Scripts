<#
.AUTHOR
    Nick Kok

.SYNOPSIS
    This script detects if the following setting is on 15 minutes: Het beeldscherm uitschakelen na

.VERSION HISTORY
    v1.0.0 - [22-04-2025] Initial version
    v1.0.1 - [DD-MM-YYYY] ...
#>

# Define constants and variables
$logFile = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Temp\Turn-off-display-After-Detect.log"

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

# Detecteert of de monitor timeout op 15 minuten staat voor AC en DC
$acTimeout = powercfg /q | Select-String -Pattern 'Video timeout \(AC\)' -Context 0,1 | ForEach-Object { ($_ -split ': ')[-1] } | ForEach-Object { $_.Trim() }
$dcTimeout = powercfg /q | Select-String -Pattern 'Video timeout \(DC\)' -Context 0,1 | ForEach-Object { ($_ -split ': ')[-1] } | ForEach-Object { $_.Trim() }

# Omzetten van hex naar dec
$acTimeoutMin = [convert]::ToInt32($acTimeout, 16)
$dcTimeoutMin = [convert]::ToInt32($dcTimeout, 16)

if ($acTimeoutMin -ne 15 -or $dcTimeoutMin -ne 15) {
    Write-Log -Message "Monitor timeout is niet correct ingesteld. AC: $acTimeoutMin, DC: $dcTimeoutMin" -Level "ERROR"
    exit 1
}
else {
    Write-Log -Message "Monitor timeout staat correct ingesteld op 15 minuten."
    exit 0
}