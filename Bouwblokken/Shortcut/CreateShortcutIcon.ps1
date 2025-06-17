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

#Download icon if it's located in a URL
if ($IconFile -match '^https://') {
    $IconName = ($IconFile.Split('/')[-1]).Split('?')[0]
    $IconLocation = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\ShortcutIcons\"
    if (!(Test-Path $IconLocation)) {
        New-Item -ItemType Directory -Force -Path $IconLocation | Out-Null
    }
    Invoke-WebRequest -Uri $IconFile -OutFile "$IconLocation$IconName"
    $Icon = Join-Path $IconLocation $IconName
} else {
    # Support for local file paths (including .dll,index format)
    $Icon = $IconFile
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
            if ($Icon -match '^(.*\.dll),(\d+)$') {
                $iconPath = $matches[1]
                $iconIndex = $matches[2]
                $Shortcut.IconLocation = "$iconPath,$iconIndex"
            } else {
                $Shortcut.IconLocation = $Icon
            }
        }

        $Shortcut.Save()
        [Runtime.InteropServices.Marshal]::ReleaseComObject($WshShell) | Out-Null
    }
}

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
            return Join-Path -Path $env:PUBLIC -ChildPath "Desktop"
        } else {
            return [Environment]::GetFolderPath("Desktop")
        }
    }
}

function Get-StartDir {
    [CmdletBinding()]
    param()
    process {
        if (Test-RunningAsSystem) {
            return Join-Path $env:ALLUSERSPROFILE "Microsoft\Windows\Start Menu\Programs"
        } else {
            return "$([Environment]::GetFolderPath("StartMenu"))\Programs"
        }
    }
}

# Desktop Shortcut
if ($DesktopShortcut.IsPresent -eq $true) {
    $destinationPath = Join-Path -Path (Get-DesktopDir) -ChildPath "$ShortcutDisplayName.lnk"
    Add-Shortcut -DestinationPath $destinationPath -ShortcutTargetPath $ShortcutTargetPath -WorkingDirectory $WorkingDirectory
}

# Start menu entry
if ($StartMenuShortcut.IsPresent -eq $true) {
    $destinationPath = Join-Path -Path (Get-StartDir) -ChildPath "$ShortcutDisplayName.lnk"
    Add-Shortcut -DestinationPath $destinationPath -ShortcutTargetPath $ShortcutTargetPath -WorkingDirectory $WorkingDirectory
}