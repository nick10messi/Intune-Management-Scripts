###########################################################################
# Auteur      : Nick Kok
# Doel        : Map Canon iR-ADV C3520 netwerkprinter met juiste driver
# Context     : Standalone printer via TCP/IP, geen printserver
# Versie      : 2.0
# Datum       : 17-10-2025
###########################################################################

# ===============================
# Configuratie
# ===============================
$printerName = "Canon iR-ADV C3520"
$driverName  = "Canon Generic Plus PCL6"
$printerIP   = "10.20.30.101"
$portName    = "IP_$printerIP"
$logPath     = "$env:ProgramData\Printer Mapping\Map-CanonPrinter.log"


# ===============================
# Loggingfunctie
# ===============================
function Write-Log {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR")][string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp][$Level] $Message"
    Add-Content -Path $logPath -Value $entry
}

Write-Log -Message "-----------------------------"
Write-Log -Message "Script gestart."

# ===============================
# Poort aanmaken indien nodig
# ===============================
try {
    if (-not (Get-PrinterPort -Name $portName -ErrorAction SilentlyContinue)) {
        Add-PrinterPort -Name $portName -PrinterHostAddress $printerIP
        Write-Log -Message "Printerpoort '$portName' aangemaakt voor IP $printerIP."
    } else {
        Write-Log -Message "Printerpoort '$portName' bestaat al."
    }
} catch {
    Write-Log -Message "Fout bij aanmaken printerpoort: $_" -Level "ERROR"
    exit 1
}

# ===============================
# Printer toevoegen
# ===============================
try {
    Add-Printer -Name $printerName -DriverName $driverName -PortName $portName
    Write-Log -Message "Printer '$printerName' succesvol toegevoegd met driver '$driverName'." "INFO"
} catch {
    Write-Log "Fout bij toevoegen printer '$printerName': $_" "ERROR"
    exit 1
}