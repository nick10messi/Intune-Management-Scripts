<#
.AUTHOR
    Nick Kok

.SYNOPSIS
    This script detects if all the required CIS 3.0.1 L2 Custom Settings are configured correctly.
#>

# Define constants and variables
$logFile = Join-Path -Path $env:ProgramData -ChildPath "Microsoft\IntuneManagementExtension\Logs\CIS-3.0.1-L2-Custom-Settings-Detect.log"

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

$servicesToCheck = @(
    "BTAGService", "bthserv", "MapsBroker", "lfsvc", "lltdsvc", "MSiSCSI",
    "PNRPsvc", "p2psvc", "p2pimsvc", "PNRPAutoReg", "Spooler", "wercplsupport",
    "RasAuto", "SessionEnv", "TermService", "UmRdpService", "RemoteRegistry",
    "LanmanServer", "SNMP", "WerSvc", "Wecsvc", "WpnService", "PushToInstall", "WinRM"
)

$nonCompliantServices = @()

foreach ($serviceName in $servicesToCheck) {
    try {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        $startMode = (Get-CimInstance -ClassName Win32_Service -Filter "Name='$serviceName'").StartMode
        if ($startMode -ne "Disabled") {
            $nonCompliantServices += $serviceName
        }
    } catch {
        Write-Log -Message "Service $serviceName not found or error occurred: $_" -Level "ERROR"
        $nonCompliantServices += $serviceName
    }
}

if ($nonCompliantServices.Count -gt 0) {
    Write-Log -Message "Non-compliant services found: $($nonCompliantServices -join ', ')" -Level "ERROR"
    exit 1
} else {
    Write-Log -Message "All services are correctly set to Disabled." -Level "INFO"
    exit 0
}