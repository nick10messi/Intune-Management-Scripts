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

#Determine final icon path
if ($IconFile -match '^https://') {
    # Download icon from URL
    $IconName = ($IconFile.Split('/')[-1]).Split('?')[0]
    $IconLocation = "$env:ProgramData\Shortcut_Icons"
    if (!(Test-Path $IconLocation)) {
        New-Item -ItemType Directory -Force -Path $IconLocation | Out-Null
    }
    $Icon = Join-Path $IconLocation $IconName
    Invoke-WebRequest -Uri $IconFile -OutFile $Icon
}
elseif (Test-Path -Path $IconFile -PathType Leaf) {
    # Icon file exists locally (e.g., bundled in package)
    $TargetIconPath = "$env:ProgramData\Shortcut_Icons\$(Split-Path -Leaf $IconFile)"
    if (!(Test-Path "$env:ProgramData\Shortcut_Icons")) {
        New-Item -ItemType Directory -Force -Path "$env:ProgramData\Shortcut_Icons" | Out-Null
    }
    Copy-Item -Path $IconFile -Destination $TargetIconPath -Force
    $Icon = $TargetIconPath
} else {
    $Icon = $null
}

function Add-Shortcut {
    param (
        [Parameter(Mandatory)]
        [String]$ShortcutTargetPath,
        [Parameter(Mandatory)]
        [String]$DestinationPath,
        [Parameter()]
        [String]$WorkingDirectory
    )

    process {
        $WshShell = New-Object -comObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($destinationPath)
        $Shortcut.TargetPath = $ShortcutTargetPath
        $Shortcut.Arguments = $ShortcutArguments
        $Shortcut.WorkingDirectory = $WorkingDirectory

        if ($Icon) {
            $Shortcut.IconLocation = $Icon
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