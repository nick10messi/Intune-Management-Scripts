# Define logging path
$LogPath = "C:\ProgramData\Debloat"
$LogFile = "$LogPath\Debloat_Remediation.log"

# Create log folder if it doesn't exist
if (!(Test-Path -Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}

# Start logging
function Log {
    param ([string]$Message)
    Add-Content -Path $LogFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
}

Log "Starting remediation..."

# Define bloatware apps to remove
$AppPatterns = @(
    "*Microsoft.Xbox*",
    "*Microsoft.XboxGameOverlay*",
    "*Microsoft.XboxGamingOverlay*",
    "*Microsoft.Xbox.TCUI*",
    "*Microsoft.XboxIdentityProvider*",
    "*Microsoft.XboxSpeechToTextOverlay*",
    "*Microsoft.XboxApp*",
    "*Microsoft.XboxGameCallableUI*",
    "*Microsoft.XboxGameBar*",
    "*Microsoft.XboxGameBarPlugin*",
    "*Microsoft.XboxGameBarWidgets*",
    "*Microsoft.MicrosoftSolitaireCollection*",
    "*Microsoft.ZuneMusic*",            # Xbox Music (legacy)
    "*Microsoft.ZuneVideo*",            # Movies & TV fallback
    "*Microsoft.MixedReality.Portal*",
    "*Microsoft.MSPaint*",              # Paint 3D (now removed from Store)
    "*Microsoft.SkypeApp*",             # Legacy Get Skype
    "*Microsoft.WindowsMaps*",
    "*Microsoft.Tips*",
    "*Microsoft.Getstarted*",
    "*Microsoft.GetHelp*"
)

foreach ($Pattern in $AppPatterns) {
    try {
        # Remove for current users
        $Packages = Get-AppxPackage -Name $Pattern -AllUsers
        foreach ($pkg in $Packages) {
            Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction SilentlyContinue
            Log "Removed AppxPackage: $($pkg.Name)"
        }

        # Remove for new users (provisioned packages)
        $Provisioned = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $Pattern }
        foreach ($prov in $Provisioned) {
            Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName -ErrorAction SilentlyContinue
            Log "Removed ProvisionedPackage: $($prov.DisplayName)"
        }
    }
    catch {
        Log "Error removing $Pattern $($_.Exception.Message)"
    }
}

Log "Remediation completed."