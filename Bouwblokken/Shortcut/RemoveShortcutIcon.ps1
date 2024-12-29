[CmdletBinding()]
Param (
   [Parameter(Mandatory=$true)]
   [String]$ShortcutDisplayName,

   [Parameter(Mandatory = $false)]
   [Switch]$StartMenuShortcut = $false,

   [Parameter(Mandatory = $false)]
   [Switch]$DesktopShortcut = $false,

   [Parameter(Mandatory = $false)]
   [String]$IconFile = $null
)

#check if running as system
function Test-RunningAsSystem {
   [CmdletBinding()]
   param()
   process{
       return ($(whoami -user) -match "S-1-5-18")
   }
}

function Get-DesktopDir {
   [CmdletBinding()]
   param()
   process{
       if (Test-RunningAsSystem){
           $desktopDir = Join-Path -Path $env:PUBLIC -ChildPath "Desktop"
       }else{
           $desktopDir=$([Environment]::GetFolderPath("Desktop"))
       }
       return $desktopDir
   }
}

function Get-StartDir {
   [CmdletBinding()]
   param()
   process{
       if (Test-RunningAsSystem){
           $startMenuDir= Join-Path $env:ALLUSERSPROFILE "Microsoft\Windows\Start Menu\Programs"
       }else{
           $startMenuDir="$([Environment]::GetFolderPath("StartMenu"))\Programs"
       }
       return $startMenuDir
   }
}

# Remove icon from desktop
if ($DesktopShortcut.IsPresent -eq $true) {
    Remove-Item -Path $(Join-Path $(Get-DesktopDir) "$ShortcutDisplayName.lnk") -EA SilentlyContinue;     
}

# Remove icon from start
if ($StartMenuShortcut.IsPresent -eq $true) {
    Remove-Item -Path $(Join-Path $(Get-StartDir) "$ShortcutDisplayName.lnk") -EA SilentlyContinue    
}

if ($iconfile -match '^https://' ) {
    $IconName = $iconfile.split('/')[-1]
    $IconLocation = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\ShortcutIcons\"
    $Icon =  $iconlocation+$IconName
    Remove-Item $Icon -Force
}