#### Functions ####
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
#### End of functions ####

$ShortcutName = "NAME OF THE SHORTCUT WITHOUT .INK"

#### Detect Desktop shortcut ####
$Desktop_Location = Get-DesktopDir

if (Test-Path $Desktop_Location\$ShortcutName.lnk) {
    Write-Host "Shortcut $ShortcutName is gevonden"
}
else {
    Exit 1
}

### Detect Start Menu shortcut
$StartMenu_Location = Get-StartDir

if (Test-Path $StartMenu_Location\$ShortcutName.lnk) {
    Write-Host "Shortcut $ShortcutName is gevonden"
}
else {
    Exit 1
}