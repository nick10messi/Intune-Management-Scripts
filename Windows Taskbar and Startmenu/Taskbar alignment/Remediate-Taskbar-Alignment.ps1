###########################################################################
# Auteur      : Nick Kok
# Doel        : Stelt de taakbalk uitlijning links in
# Versie      : 1.0
# Datum       : 23-9-2025
###########################################################################

# Define constants and variables
$logFile = Join-Path -Path $env:ProgramData -ChildPath "Microsoft\IntuneManagementExtension\Logs\Remediate-Taskbar-Alignment.log"

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

# Data
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$registryValueName = "TaskbarAl"

# Set taskbar alignment to left (0)
try {
    Set-ItemProperty -Path $registryPath -Name $registryValueName -Value 0 -ErrorAction Stop
    Write-Log -Message "Taskbar alignment set to left (0)." -Level "INFO"    
    exit 0
}
catch {
    Write-Log -Message "Failed to set taskbar alignment: $_" -Level "ERROR"
    exit 1
}