###########################################################################
# Auteur      : Nick Kok
6# Doel        : Detecteert of de taakbalk links is uitgelijnd
# Versie      : 1.0
# Datum       : 23-9-2025
###########################################################################

# Define constants and variables
$logFile = Join-Path -Path $env:ProgramData -ChildPath "Microsoft\IntuneManagementExtension\Logs\Detect-Taskbar-Alignment.log"

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
$taskbarAlignment = Get-ItemPropertyValue -Path $registryPath -Name $registryValueName -ErrorAction SilentlyContinue

# Detect taskbar alignment
if ($taskbarAlignment -eq 0) {
    Write-Log -Message "Taskbar is aligned to the left." -Level "INFO"
    exit 0
}
else {
    Write-Log -Message "Taskbar is not aligned to the left." -Level "WARNING"
    exit 1
}