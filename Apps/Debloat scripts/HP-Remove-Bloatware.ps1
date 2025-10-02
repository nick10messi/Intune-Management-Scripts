###########################################################################
# Auteur      : Nick Kok
# Doel        : Verwijderd alle HP bloatware
# Versie      : 1.1
# Datum       : 02-10-2025
###########################################################################

# Define constants and variables
$logFile = Join-Path -Path $env:ProgramData -ChildPath "Microsoft\IntuneManagementExtension\Logs\HP-Remove-Bloatware.log"

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

# Alleen draaien op HP devices
$manufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
if ($manufacturer -notlike "*HP*") {
    Write-Log -Message "Geen HP device, script stopt."
    exit 0
}

# Lijst met bekende HP bloatware (zowel AppX als klassieke namen)
$HPBloatware = @(
    "HP Client Security Manager",
    "HP Notifications",
    "HP Security Update Service",
    "HP System Default Settings",
    "HP Wolf Security",
    "HP Wolf Security Application Support for Sure Sense",
    "HP Wolf Security Application Support for Windows",
    "HP Wolf Security Application Support for Chrome",
    "HP Wolf Security - Console",
    "HP QuickDrop",
    "HP Privacy Settings",
    "HP Support Assistant",
    "HP System Information",
    "HP PC Hardware Diagnostics Windows",
    "HP Power Manager",
    "myHP",
    "RealtekSemiconductorCorp.HPAudioControl",
    "RealtekSemiconductorCorp.HPAudioControl_2.39.280.0_x64__dt26b99r8h8gj",
    "HP Sure Recover",
    "HP Sure Run Module"
)

# Functie om AppX en MSI-apps te verwijderen
function Remove-HPApp {
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
    $pkg = Get-AppxPackage -AllUsers | Where-Object { $_.Name -like "*$AppName*" -or $_.PackageFamilyName -like "*$AppName*" }
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

# Speciale behandeling voor HP Support Assistant (voorkomt pop-up dialoogvenster)
$hpsaPath = "C:\Program Files (x86)\Hewlett-Packard\HP Support Framework\UninstallHPSA.exe"
if (Test-Path $hpsaPath) {
    try {
        Start-Process -FilePath $hpsaPath -ArgumentList "/s /v/qn UninstallKeepPreferences=FALSE" -Wait
        Write-Log -Message "HP Support Assistant verwijderd via silent uninstall."
    } catch {
        Write-Log -Message "Fout bij verwijderen HP Support Assistant: $_" -Level "ERROR"
    }
}

# Doorloop de lijst met HP bloatware
foreach ($app in $HPBloatware) {
    Remove-HPApp -AppName $app
}

Write-Log -Message "HP bloatware verwijderen voltooid."
