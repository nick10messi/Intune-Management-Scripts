<#
.AUTHOR
    Nick Kok

.SYNOPSIS
    This script deploys the LayoutModification.xml to the default user

.VERSION HISTORY
    v1.0.0 - [29-4-2025] Initial version
    v1.0.1 - [DD-MM-YYYY] ...
#>

# Function to get the actual logged-in user's profile directory

function Get-LoggedInUserProfile {

    $LoggedInUser = Get-WmiObject Win32_ComputerSystem | Select-Object -ExpandProperty UserName
    
    if ($LoggedInUser -match "\\") {
    
    $LoggedInUser = $LoggedInUser.Split("\")[-1] # Extract just the username
    
    }
    
    return "C:\Users\$LoggedInUser"
    
}
    
# Get the correct user profile path (for non-system users)
    
$currentUserProfile = Get-LoggedInUserProfile
    
$currentDestination = "$currentUserProfile\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml"
    
# Define the path for Default Profile (for new users)
    
$defaultDestination = "C:\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml"
    
# Ensure necessary directories exist
    
$folders = @(
    
    "C:\Users\Default\AppData\Local\Microsoft\Windows\Shell",    
    "$currentUserProfile\AppData\Local\Microsoft\Windows\Shell"    
)
    
foreach ($folder in $folders) {
    
    if (!(Test-Path $folder)) {    
        New-Item -Path $folder -ItemType Directory -Force | Out-Null    
    }    
    }
    
    # Delete existing LayoutModification.xml if it exists in the current user profile    
    if (Test-Path $currentDestination) {    
        Remove-Item -Path $currentDestination -Force    
    }
    
# XML Content for Taskbar Layout
$xmlContent = @"    
<?xml version="1.0" encoding="utf-8"?>
<LayoutModificationTemplate
xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification"
xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout"
xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout"
xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout"
Version="1">
    <CustomTaskbarLayoutCollection>
        <defaultlayout:TaskbarLayout>
            <taskbar:TaskbarPinList>
                <taskbar:DesktopApp DesktopApplicationID="MicrosoftCorporationII.QuickAssist_8wekyb3d8bbwe!App" />
                <taskbar:DesktopApp DesktopApplicationID="Microsoft.OutlookForWindows_8wekyb3d8bbwe!Microsoft.OutlookforWindows" />
                <taskbar:DesktopApp DesktopApplicationID="MSTeams_8wekyb3d8bbwe!MSTeams" />
                <taskbar:DesktopApp DesktopApplicationID="Citrix.Workspace" />
                <taskbar:DesktopApp DesktopApplicationLinkPath="%AppData%\Microsoft\Windows\Start Menu\Programs\Nijmegen.lnk" />                
            </taskbar:TaskbarPinList>
        </defaultlayout:TaskbarLayout>
    </CustomTaskbarLayoutCollection>
</LayoutModificationTemplate>    
"@
    
# Write XML to Default and Current User Profiles    
$xmlContent | Out-File -FilePath $defaultDestination -Encoding utf8 -Force    
$xmlContent | Out-File -FilePath $currentDestination -Encoding utf8 -Force