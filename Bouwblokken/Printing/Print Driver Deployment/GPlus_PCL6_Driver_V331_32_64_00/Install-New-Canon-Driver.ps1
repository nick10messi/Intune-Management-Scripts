###########################################################################
# Auteur      : Nick Kok
# Doel        : Verwijderd eerst de iR-ADV C3520 printer en installeert daarna de juiste driver
# Versie      : 1.0
# Datum       : 16-10-2025
###########################################################################

# Define constants and variables
$logFile = Join-Path -Path $env:ProgramData -ChildPath "Microsoft\IntuneManagementExtension\Logs\Install-New-Canon-Driver.log"

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

##########################################################
### Verwijder bestaande printer ###
$printerName = "iR-ADV C3520"
$printer = Get-Printer -Name $printerName -ErrorAction SilentlyContinue

if ($printer) {
    Remove-Printer -Name $printerName -Confirm:$false
    Write-Log -Message "Printer '$printerName' verwijderd." -Level "INFO"
} else {
    Write-Log -Message "Printer '$printerName' niet gevonden, doorgaan." -Level "INFO"
}


##########################################################
### Verwijder oude driver ###
$infOld = "oem97.inf"

try {
    Start-Process "pnputil.exe" -ArgumentList "/delete-driver $infOld /uninstall /force" -NoNewWindow -Wait
    Write-Log -Message "Driver $infOld verwijderd." -Level "INFO"
}
catch {
    Write-Log -Message "Foutmelding bij verwijderen driver: $_" -Level "ERROR"
}

##########################################################
### Installeert de nieuwe driver ###
$infPath = "$PSScriptRoot\x64\Driver\CNP60MA64.INF"

try {
    Start-Process "pnputil.exe" -ArgumentList "/add-driver `"$infPath`" /install" -NoNewWindow -Wait
    Write-Log -Message "Driver CNP60MA64.INF succesvol geinstalleerd in DriverStore" -Level "INFO"
}
catch {
    Write-Log -Message "Foutmelding bij installeren driver in DriverStore: $_" -Level "ERROR"
}

try {
    Add-PrinterDriver -Name "Canon Generic Plus PCL6"
    Write-Log -Message "Driver CNP60MA64.INF succesvol geinstalleerd in Print Spooler service" -Level "INFO"
}
catch {
    Write-Log -Message "Foutmelding bij installeren driver in Print Spooler service: $_" -Level "ERROR"
}