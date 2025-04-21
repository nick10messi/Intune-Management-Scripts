<#
.AUTHOR
    Nick Kok

.SYNOPSIS
    This script configures all the required CIS 3.0.1 L2 Custom Settings which cannot be deployed with the Intune Settings Catalog.
#>

# Define constants and variables
$logFile = Join-Path -Path $env:ProgramData -ChildPath "Microsoft\IntuneManagementExtension\Logs\CIS-3.0.1-L2-Custom-Settings-Remediate.log"

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

$servicesToDisable = @(
    "BTAGService", "bthserv", "MapsBroker", "lfsvc", "lltdsvc", "MSiSCSI",
    "PNRPsvc", "p2psvc", "p2pimsvc", "PNRPAutoReg", "Spooler", "wercplsupport",
    "RasAuto", "SessionEnv", "TermService", "UmRdpService", "RemoteRegistry",
    "LanmanServer", "SNMP", "WerSvc", "Wecsvc", "WpnService", "PushToInstall", "WinRM"
)

foreach ($serviceName in $servicesToDisable) {
    try {
        $cimService = Get-CimInstance -ClassName Win32_Service -Filter "Name='$serviceName'" -ErrorAction Stop
        if ($cimService.StartMode -ne "Disabled") {
            Set-Service -Name $serviceName -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Log -Message "Set $serviceName to Disabled"
        } else {
            Write-Log -Message "$serviceName already Disabled"
        }
    } catch {
        Write-Log -Message "Service $serviceName not found or error occurred: $_" -Level "ERROR"
    }
}