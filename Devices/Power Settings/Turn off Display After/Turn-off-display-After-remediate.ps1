<#
.AUTHOR
    Nick Kok

.SYNOPSIS
    This script configures  the following setting on 15 minutes: Het beeldscherm uitschakelen na

.VERSION HISTORY
    v1.0.0 - [22-04-2025] Initial version
    v1.0.1 - [DD-MM-YYYY] ...
#>

# Define constants and variables
$logFile = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Temp\Turn-off-display-After-Remediate.log"

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

# Zet de monitor timeout op 15 minuten voor netstroom (AC) en batterij (DC)
try {
    powercfg.exe /CHANGE monitor-timeout-ac 15
    Write-Log -Message "Monitor timeout voor AC succesvol ingesteld op 15 minuten." -Level "INFO"

    powercfg.exe /CHANGE monitor-timeout-dc 15
    Write-Log -Message "Monitor timeout voor DC succesvol ingesteld op 15 minuten." -Level "INFO"
}
catch {
    Write-Log -Message "Fout bij instellen van monitor timeout: $_" -Level "ERROR"
}
