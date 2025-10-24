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

Restart-Service Spooler
Start-Sleep 10


##########################################################
### Installeert de nieuwe driver ###
# Vind de directory waarin het script en de driverbestanden zich bevinden
$workingDir = Split-Path -Parent ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)

# Bouw volledig pad naar het INF-bestand
$infPath = Join-Path $workingDir "CNP60MA64.INF"

Write-Log -Message "Werkdirectory: $workingDir"
Write-Log -Message "Driver pad: $infPath"

$infPath = Join-Path $scriptDir "CNP60MA64.INF"

# Importeert de printdriver in de DriverStore
try {
    Start-Process "pnputil.exe" -ArgumentList "/add-driver `"$infPath`" /install" -NoNewWindow -Wait
    Write-Log -Message "Driver succesvol geinstalleerd in DriverStore" -Level "INFO"
}
catch {
    Write-Log -Message "Foutmelding bij installeren driver in DriverStore: $_" -Level "ERROR"
}

# Installeert de printdriver in de Print Spooler service
try {
    Add-PrinterDriver -Name "Canon Generic Plus PCL6"
    Write-Log -Message "Driver succesvol geinstalleerd in Print Spooler service" -Level "INFO"
}
catch {
    Write-Log -Message "Foutmelding bij installeren driver in Print Spooler service: $_" -Level "ERROR"
}

Write-Log -Message "Script execution completed." -Level "INFO"