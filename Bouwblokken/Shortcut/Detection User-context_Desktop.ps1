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

#### End of functions ####
#### Detect Desktop shortcut ####
$Desktop_Location = Get-DesktopDir
$ShortcutName = "NAME OF THE SHORTCUT WITHOUT .INK"

if (Test-Path $Desktop_Location\$ShortcutName.lnk) {
    Write-Host "Shortcut $ShortcutName is gevonden"
}
else {
    Exit 1
}
