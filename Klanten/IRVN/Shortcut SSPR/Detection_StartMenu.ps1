#### Functions ####
function Test-RunningAsSystem {
    [CmdletBinding()]
    param()
    process {
        return ($(whoami -user) -match "S-1-5-18")
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
#### Detect Start Menu shortcut ####
$StartMenu_Location = Get-StartDir
$ShortcutName = "IRVN Wachtwoord Reset"

if (Test-Path $StartMenu_Location\$ShortcutName.lnk) {
    Write-Host "Shortcut $ShortcutName is gevonden"
}
else {
    Exit 1
}