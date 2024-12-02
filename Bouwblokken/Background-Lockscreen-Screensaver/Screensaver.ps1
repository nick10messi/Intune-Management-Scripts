### Edit this variable ###
$ImageURL = ""
$DestinationFile = "screensavername.scr"

# Data - Do not edit
$DestinationFolder = "$Env:ProgramData\Images\Screensaver"
$LogFile = "$Env:ProgramData\Microsoft\IntuneManagementExtension\logs\SetScreenSaver.log"
$DestinationPath = Join-Path -Path $DestinationFolder -ChildPath $DestinationFile

# Function to write to the log
function Write-Log {
    param (
        [string]$Message
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$Timestamp - $Message" | Out-File -FilePath $LogFile -Append -Force
}

# Ensure the destination folder exists
if (-not (Test-Path -Path $DestinationFolder)) {
    try {
        New-Item -ItemType Directory -Path $DestinationFolder -Force
        Write-Log "Created directory: $DestinationFolder"
    }
    catch {
        Write-Log "Failed to create directory $DestinationFolder $_"
        exit 1
    }
}

# Download the screensaver
try {
    Invoke-WebRequest -Uri $ImageURL -OutFile $DestinationPath
    Write-Log "Screensaver downloaded successfully to $DestinationPath"
}
catch {
    Write-Log "Failed to download the screensaver: $_"
    exit 1
}

Write-Log "Script completed successfully."