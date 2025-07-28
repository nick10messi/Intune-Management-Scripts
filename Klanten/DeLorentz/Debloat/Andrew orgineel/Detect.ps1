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

$found = $false

foreach ($Pattern in $AppPatterns) {
    if (
        Get-AppxPackage -Name $Pattern -AllUsers |
        Where-Object { $_.Name -like $Pattern } |
        Get-AppxProvisionedPackage -Online |
        Where-Object { $_.DisplayName -like $Pattern }
    ) {
        $found = $true
        break
    }
}

if ($found) {
    exit 1  # Bloatware detected, remediation needed
} else {
    exit 0  # Device clean
}