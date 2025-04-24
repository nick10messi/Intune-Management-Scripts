# Pad naar logbestand (pas aan indien gewenst)
$logFile = "$env:ProgramData\MonitorTimeoutLog.txt"

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