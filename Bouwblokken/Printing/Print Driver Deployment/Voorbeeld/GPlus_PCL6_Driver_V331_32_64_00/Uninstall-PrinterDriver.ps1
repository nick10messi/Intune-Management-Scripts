###########################################################################
# Auteur      : Nick Kok
# Doel        : Verwijdert alle printers met opgegeven driver en daarna de printerdriver
# Versie      : 1.1
# Datum       : 16-10-2025
###########################################################################

# Define constants and variables
$logFile = Join-Path -Path $env:ProgramData -ChildPath "Microsoft\IntuneManagementExtension\Logs\Uninstall-PrinterDriver.log"

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

Write-Log -Message "Script execution started."

##########################################################

$driverOld = "Canon Generic Plus PCL6"
$infOld = "CNP60MA64.INF"

try {
    # Zoek alle printers die de opgegeven driver gebruiken
    $printers = Get-Printer | Where-Object { $_.DriverName -eq $driverOld }

    if ($printers) {
        foreach ($printer in $printers) {
            try {
                Remove-Printer -Name $printer.Name -ErrorAction Stop
                Write-Log -Message "Printer '$($printer.Name)' verwijderd (driver: $driverOld)." -Level "INFO"
            }
            catch {
                Write-Log -Message "Kon printer '$($printer.Name)' niet verwijderen: $_" -Level "ERROR"
            }
        }
    }
    else {
        Write-Log -Message "Geen printers gevonden met driver '$driverOld'." -Level "INFO"
    }

    # Verwijder nu de printerdriver
    Remove-PrinterDriver -Name $driverOld -ErrorAction Stop
    Write-Log -Message "Driver '$driverOld' verwijderd uit Print Spooler." -Level "INFO"
}
catch {
    Write-Log -Message "Fout bij verwijderen printerdriver: $_" -Level "ERROR"
}

try {
    # Verwijder driver ook uit de driverstore
    Start-Process "pnputil.exe" -ArgumentList "/delete-driver $infOld /uninstall /force" -NoNewWindow -Wait
    Write-Log -Message "Driver '$infOld' verwijderd uit driverstore." -Level "INFO"
}
catch {
    Write-Log -Message "Fout bij verwijderen driver uit driverstore: $_" -Level "ERROR"
}

Write-Log -Message "Script execution completed."
