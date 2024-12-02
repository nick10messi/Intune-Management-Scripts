[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [String]$ShortcutTargetPath,

    [Parameter(Mandatory = $true)]
    [String]$ShortcutDisplayName,

    [Parameter(Mandatory = $false)]
    [Switch]$StartMenuShortcut = $false,

    [Parameter(Mandatory = $false)]
    [Switch]$DesktopShortcut = $false,

    [Parameter(Mandatory = $false)]
    [String]$IconFile = $null,

    [Parameter(Mandatory = $false)]
    [String]$ShortcutArguments = $null,

    [Parameter(Mandatory = $false)]
    [String]$WorkingDirectory = $null
)

#Download icon if its located in a url
if ($iconfile -match '^https://' ) {
    $IconName = ($iconfile.split('/')[-1]).Split('?')[0]
    $IconLocation = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\ShortcutIcons\"
    if (!(Test-Path $IconLocation)) {
        New-Item -ItemType Directory -Force -Path $IconLocation
    }
    Invoke-WebRequest -Uri $IconFile -OutFile "$IconLocation$IconName"
    $Icon = $iconlocation + $IconName
}

#helper function to avoid uneccessary code
function Add-Shortcut {
    param (
        [Parameter(Mandatory)]
        [String]$ShortcutTargetPath,
        [Parameter(Mandatory)]
        [String] $DestinationPath,
        [Parameter()]
        [String] $WorkingDirectory
    )

    process {
        $WshShell = New-Object -comObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($destinationPath)
        $Shortcut.TargetPath = $ShortcutTargetPath
        $Shortcut.Arguments = $ShortcutArguments
        $Shortcut.WorkingDirectory = $WorkingDirectory
    
        if ($IconFile) {
            $Shortcut.IconLocation = $Icon
        }

        # Create the shortcut
        $Shortcut.Save()
        #cleanup
        [Runtime.InteropServices.Marshal]::ReleaseComObject($WshShell) | Out-Null
    }
}

#check if running as system
function Test-RunningAsSystem {
    [CmdletBinding()]
    param()
    process {
        return ($(whoami -user) -match "S-1-5-18")
    }
}

function Get-DesktopDir {
    [CmdletBinding()]
    param()
    process {
        if (Test-RunningAsSystem) {
            $desktopDir = Join-Path -Path $env:PUBLIC -ChildPath "Desktop"
        }
        else {
            $desktopDir = $([Environment]::GetFolderPath("Desktop"))
        }
        return $desktopDir
    }
}

function Get-StartDir {
    [CmdletBinding()]
    param()
    process {
        if (Test-RunningAsSystem) {
            $startMenuDir = Join-Path $env:ALLUSERSPROFILE "Microsoft\Windows\Start Menu\Programs"
        }
        else {
            $startMenuDir = "$([Environment]::GetFolderPath("StartMenu"))\Programs"
        }
        return $startMenuDir
    }
}

#### Desktop Shortcut
if ($DesktopShortcut.IsPresent -eq $true) {
    $destinationPath = Join-Path -Path $(Get-DesktopDir) -ChildPath "$shortcutDisplayName.lnk"
    Add-Shortcut -DestinationPath $destinationPath -ShortcutTargetPath $ShortcutTargetPath -WorkingDirectory $WorkingDirectory
}

#### Start menu entry
if ($StartMenuShortcut.IsPresent -eq $true) {
    $destinationPath = Join-Path -Path $(Get-StartDir) -ChildPath "$shortcutDisplayName.lnk"
    Add-Shortcut -DestinationPath $destinationPath -ShortcutTargetPath $ShortcutTargetPath -WorkingDirectory $WorkingDirectory
}
