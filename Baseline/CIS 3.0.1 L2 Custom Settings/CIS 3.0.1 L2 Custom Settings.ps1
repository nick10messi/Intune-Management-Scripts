<#
.AUTHOR
    Nick Kok

.SYNOPSIS
    This script configures all the required CIS 3.0.1 L2 Custom Settings which cannot be deployed with the Intune Settings Catalog.
#>

# Define constants and variables
$logFile = Join-Path -Path $env:ProgramData -ChildPath "Microsoft\IntuneManagementExtension\Logs\TITLE-Detect.log"

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

# Ensure 'Bluetooth Audio Gateway Service (BTAGService)' is set to 'Disabled'
Set-Service -Name BTAGService -StartupType Disabled
Write-Log -Message "Bluetooth Audio Gateway Service (BTAGService) is set to Disabled." -Level "INFO"

# Ensure 'Bluetooth Support Service (bthserv)' is set to 'Disabled'
Set-Service -Name bthserv -StartupType Disabled
Write-Log -Message "Bluetooth Support Service (bthserv) is set to Disabled." -Level "INFO"

# Ensure 'Downloaded Maps Manager (MapsBroker)' is set to 'Disabled'
Set-Service -Name MapsBroker -StartupType Disabled
Write-Log -Message "Downloaded Maps Manager (MapsBroker) is set to Disabled." -Level "INFO"

# Ensure 'Geolocation Service (lfsvc)' is set to 'Disabled'
Set-Service -Name lfsvc -StartupType Disabled
Write-Log -Message "Geolocation Service (lfsvc) is set to Disabled." -Level "INFO"

# Ensure 'Link-Layer Topology Discovery Mapper (lltdsvc)' is set to 'Disabled'
Set-Service -Name lltdsvc -StartupType Disabled
Write-Log -Message "Link-Layer Topology Discovery Mapper (lltdsvc) is set to Disabled." -Level "INFO"

# Ensure 'Microsoft iSCSI Initiator Service (MSiSCSI)' is set to 'Disabled'
Set-Service -Name MSiSCSI -StartupType Disabled
Write-Log -Message "Microsoft iSCSI Initiator Service (MSiSCSI) is set to Disabled." -Level "INFO"

# Ensure 'Peer Name Resolution Protocol (PNRPsvc)' is set to 'Disabled'
Set-Service -Name PNRPsvc -StartupType Disabled
Write-Log -Message "Peer Name Resolution Protocol (PNRPsvc) is set to Disabled." -Level "INFO"

# Ensure 'Peer Networking Grouping (p2psvc)' is set to 'Disabled'
Set-Service -Name p2psvc -StartupType Disabled
Write-Log -Message "Peer Networking Grouping (p2psvc) is set to Disabled." -Level "INFO"

# Ensure 'Peer Networking Identity Manager (p2pimsvc)' is set to 'Disabled'
Set-Service -Name p2pimsvc -StartupType Disabled
Write-Log -Message "Peer Networking Identity Manager (p2pimsvc) is set to Disabled." -Level "INFO"

# Ensure 'PNRP Machine Name Publication Service (PNRPAutoReg)' is set to 'Disabled'
Set-Service -Name PNRPAutoReg -StartupType Disabled
Write-Log -Message "PNRP Machine Name Publication Service (PNRPAutoReg) is set to Disabled." -Level "INFO"

# Ensure 'Print Spooler (Spooler)' is set to 'Disabled'
Set-Service -Name Spooler -StartupType Disabled
Write-Log -Message "Print Spooler (Spooler) is set to Disabled." -Level "INFO"

# Ensure 'Problem Reports and Solutions Control Panel Support (wercplsupport)' is set to 'Disabled'
Set-Service -Name wercplsupport -StartupType Disabled
Write-Log -Message "Problem Reports and Solutions Control Panel Support (wercplsupport) is set to Disabled." -Level "INFO"

# Ensure 'Remote Access Auto Connection Manager (RasAuto)' is set to 'Disabled'
Set-Service -Name RasAuto -StartupType Disabled
Write-Log -Message "Remote Access Auto Connection Manager (RasAuto) is set to Disabled." -Level "INFO"

# Ensure 'Remote Desktop Configuration (SessionEnv)' is set to 'Disabled'
Set-Service -Name SessionEnv -StartupType Disabled
Write-Log -Message "Remote Desktop Configuration (SessionEnv) is set to Disabled." -Level "INFO"

# Ensure 'Remote Desktop Services (TermService)' is set to 'Disabled'
Set-Service -Name TermService -StartupType Disabled
Write-Log -Message "Remote Desktop Services (TermService) is set to Disabled." -Level "INFO"

# Ensure 'Remote Desktop Services UserMode Port Redirector (UmRdpService)' is set to 'Disabled'
Set-Service -Name UmRdpService -StartupType Disabled
Write-Log -Message "Remote Desktop Services UserMode Port Redirector (UmRdpService) is set to Disabled." -Level "INFO"

# Ensure 'Remote Registry (RemoteRegistry)' is set to 'Disabled'
Set-Service -Name RemoteRegistry -StartupType Disabled
Write-Log -Message "Remote Registry (RemoteRegistry) is set to Disabled." -Level "INFO"

# Ensure 'Server (LanmanServer)' is set to 'Disabled'
Set-Service -Name LanmanServer -StartupType Disabled
Write-Log -Message "Server (LanmanServer) is set to Disabled." -Level "INFO"

#Ensure 'SNMP Service (SNMP)' is set to 'Disabled'
Set-Service -Name SNMP -StartupType Disabled
Write-Log -Message "SNMP Service (SNMP) is set to Disabled." -Level "INFO"

# Ensure 'Windows Error Reporting Service (WerSvc)' is set to 'Disabled'
Set-Service -Name WerSvc -StartupType Disabled
Write-Log -Message "Windows Error Reporting Service (WerSvc) is set to Disabled." -Level "INFO"

# Ensure 'Windows Event Collector (Wecsvc)' is set to 'Disabled'
Set-Service -Name Wecsvc -StartupType Disabled
Write-Log -Message "Windows Event Collector (Wecsvc) is set to Disabled." -Level "INFO"

# Ensure 'Windows Push Notifications System Service (WpnService)' is set to 'Disabled'
Set-Service -Name WpnService -StartupType Disabled
Write-Log -Message "Windows Push Notifications System Service (WpnService) is set to Disabled." -Level "INFO"

# Ensure 'Windows PushToInstall Service (PushToInstall)' is set to 'Disabled'
Set-Service -Name PushToInstall -StartupType Disabled
Write-Log -Message "Windows PushToInstall Service (PushToInstall) is set to Disabled." -Level "INFO"

# Ensure 'Windows Remote Management (WS-Management) (WinRM)' is set to 'Disabled'
Set-Service -Name WinRM -StartupType Disabled
Write-Log -Message "Windows Remote Management (WS-Management) (WinRM) is set to Disabled." -Level "INFO"