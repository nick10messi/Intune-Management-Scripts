###########################################################################
# Auteur      : Nick Kok
# Doel        : Verwijdert alle Dell bloatware
# Versie      : 1.0
# Datum       : 02-10-2025
###########################################################################

# Define constants and variables
$logFile = Join-Path -Path $env:ProgramData -ChildPath "Microsoft\IntuneManagementExtension\Logs\Dell-Remove-Bloatware.log"

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

# Alleen draaien op Dell devices
$manufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
if ($manufacturer -notlike "*Dell*") {
    Write-Log -Message "Geen Dell device, script stopt."
    exit 0
}

# Lijst met bekende Dell bloatware
$DellBloatware = @(
    "Dell Optimizer",
    "Dell Power Manager",
    "Dell Digital Delivery",
    "Dell Peripheral Manager",
    "Dell Update",
    "Dell Command | Update",
    "Dell SupportAssist",
    "Dell SupportAssist Remediation",
    "SupportAssist Recovery Assistant",
    "Dell Inc. PartnerPromo",
    "Dell Inc. DellOptimizer",
    "Dell Display Manager",
    "Dell Pair"
)

# Functie om AppX en MSI-apps te verwijderen
function Remove-DellApp {
    param (
        [string]$AppName
    )

    # AppX provisioned packages
    $prov = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like "*$AppName*" }
    foreach ($p in $prov) {
        try {
            Remove-AppxProvisionedPackage -Online -PackageName $p.PackageName -AllUsers -ErrorAction Stop
            Write-Log -Message "Provisioned package verwijderd: $($p.DisplayName)"
        } catch {
            Write-Log -Message "Fout bij verwijderen provisioned package $($p.DisplayName): $_" -Level "ERROR"
        }
    }

    # AppX installed packages
    $pkg = Get-AppxPackage -AllUsers | Where-Object { $_.Name -like "*$AppName*" -or $_.DisplayName -like "*$AppName*" }
    foreach ($p in $pkg) {
        try {
            Remove-AppxPackage -Package $p.PackageFullName -AllUsers -ErrorAction Stop
            Write-Log -Message "AppX package verwijderd: $($p.Name)"
        } catch {
            Write-Log -Message "Fout bij verwijderen AppX package $($p.Name): $_" -Level "ERROR"
        }
    }

    # MSI/exe via registry
    $classic = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
                                "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" |
               Where-Object { $_.DisplayName -like "*$AppName*" }

    foreach ($c in $classic) {
        if ($c.UninstallString) {
            try {
                Write-Log -Message "Start uninstall van $($c.DisplayName)"
                Start-Process -FilePath "cmd.exe" -ArgumentList "/c",$c.UninstallString,"/quiet","/norestart" -Wait
                Write-Log -Message "$($c.DisplayName) verwijderd."
            } catch {
                Write-Log -Message "Fout bij verwijderen $($c.DisplayName): $_" -Level "ERROR"
            }
        }
    }
}

# Speciale behandeling Dell SupportAssist (soms hardnekkig)
$dellSA = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", 
                           "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" |
          Where-Object { $_.DisplayName -like "Dell SupportAssist" }

foreach ($sa in $dellSA) {
    if ($sa.QuietUninstallString) {
        try {
            Write-Log -Message "Silent uninstall van Dell SupportAssist gestart"
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c",$sa.QuietUninstallString -Wait
            Write-Log -Message "Dell SupportAssist verwijderd via QuietUninstallString."
        } catch {
            Write-Log -Message "Fout bij verwijderen Dell SupportAssist: $_" -Level "ERROR"
        }
    }
}

# Doorloop de lijst met Dell bloatware
foreach ($app in $DellBloatware) {
    Remove-DellApp -AppName $app
}

Write-Log -Message "Dell bloatware verwijderen voltooid."