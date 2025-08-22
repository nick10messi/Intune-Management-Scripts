###########################################################################
# Auteur      : Nick Kok
# Doel        : Detecteert of de gebruiker lid is van de lokale Administrators groep
# Versie      : 1.0
# Datum       : 22-08-2025
###########################################################################

# Define constants and variables
$logFile = Join-Path -Path $env:ProgramData -ChildPath "Microsoft\IntuneManagementExtension\Logs\Remove-Local-Admin-Detect.log"

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

# Haalt ingelogde gebruiker op
$CurrentUser = (Get-WMIObject -Class Win32_ComputerSystem).UserName

# Haalt alle leden van de lokale Administrators groep op
$LocalAdmins = Get-LocalGroupMember -Group "Administrators" | ForEach-Object { $_.Name }

if ($LocalAdmins -contains $CurrentUser) {
    Write-Log -Message "Detected - $CurrentUser is a local administrator." -Level "WARN"
    exit 1
}
else {
    Write-Log -Message "NotDetected - $CurrentUser is not a local administrator." -Level "INFO"
    exit 0
}