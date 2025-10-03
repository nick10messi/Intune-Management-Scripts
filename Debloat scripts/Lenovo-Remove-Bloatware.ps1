###########################################################################
# Auteur      : Nick Kok
# Doel        : Verwijdert alle Lenovo bloatware
# Versie      : 1.0
# Datum       : 02-10-2025
###########################################################################

# Define constants and variables
$logFile = Join-Path -Path $env:ProgramData -ChildPath "Microsoft\IntuneManagementExtension\Logs\Lenovo-Remove-Bloatware.log"

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

# Alleen draaien op Lenovo devices
$manufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
if ($manufacturer -notlike "*Lenovo*") {
    Write-Log -Message "Geen Lenovo device, script stopt."
    exit 0
}

# Lijst met bekende Lenovo bloatware (klassiek + Store varianten)
$LenovoBloatware = @(
    "Lenovo Vantage",
    "Lenovo Vantage Service",
    "Lenovo Utility",
    "Lenovo Settings",
    "Lenovo Welcome",
    "Lenovo Now",
    "Commercial Vantage",
    "SmartAppearance",
    "Ai Meeting Manager",
    "Glance by Mirametrix",
    "Lenovo Smart Privacy Services",
    "Lenovo Hotkeys",
    "Lenovo System Update"
)

# Functie om AppX en MSI-apps te verwijderen
function Remove-LenovoApp {
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

# Speciale behandeling voor Lenovo Vantage Service (bekend dat uninstall-string soms niet stil is)
$LVS = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", 
                        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" |
       Where-Object { $_.DisplayName -eq "Lenovo Vantage Service" }

if ($LVS.QuietUninstallString) {
    try {
        Write-Log -Message "Silent uninstall Lenovo Vantage Service gestart"
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c",$LVS.QuietUninstallString -Wait
        Write-Log -Message "Lenovo Vantage Service verwijderd via QuietUninstallString."
    } catch {
        Write-Log -Message "Fout bij verwijderen Lenovo Vantage Service: $_" -Level "ERROR"
    }
}

# Doorloop de lijst met Lenovo bloatware
foreach ($app in $LenovoBloatware) {
    Remove-LenovoApp -AppName $app
}

Write-Log -Message "Lenovo bloatware verwijderen voltooid."