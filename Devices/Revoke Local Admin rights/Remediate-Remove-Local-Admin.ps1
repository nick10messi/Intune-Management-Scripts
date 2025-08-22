###########################################################################
# Auteur      : Nick Kok
# Doel        : Verwijderd de gebruiker uit de lokale Administrators groep
# Versie      : 1.0
# Datum       : 22-08-2025
###########################################################################

# Define constants and variables
$logFile = Join-Path -Path $env:ProgramData -ChildPath "Microsoft\IntuneManagementExtension\Logs\REMEDIATE-Remove-Local-Admin.log"

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

# Haal de ingelogde gebruiker op
$CurrentUser = (Get-WMIObject -Class Win32_ComputerSystem).UserName
if (-not $CurrentUser) {
    Write-Log -Message "Geen actieve gebruiker gevonden." -Level "INFO"
    exit 0
}

# Extract alleen gebruikersnaam (zonder domein of AzureAD prefix)
$CurrentUserSimple = $CurrentUser.Split('\')[-1]
Write-Log -Message "Huidige gebruiker: $CurrentUserSimple" -Level "INFO"

# Haal alle leden van de Administrators-groep op
$LocalAdmins = Get-LocalGroupMember -Group "Administrators"

# Zoek de gebruiker in de groep
$Target = $LocalAdmins | Where-Object {
    $_.Name -like "*\$CurrentUserSimple"
}

# Verwijder indien gevonden
if ($Target) {
    try {
        Remove-LocalGroupMember -Group "Administrators" -Member $Target.Name -ErrorAction Stop
        Write-Log -Message "Gebruiker $($Target.Name) is verwijderd uit de Administrators-groep." -Level "INFO"
    }
    catch {
        Write-Log -Message "Fout bij verwijderen: $_" -Level "ERROR"
        exit 1
    }
}
else {
    Write-Log -Message "Gebruiker $CurrentUserSimple is geen lokaal administrator." -Level "INFO"
}