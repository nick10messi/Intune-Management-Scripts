### Edit this variable ###
$ImageURL = ""
$DestinationFile = "image.jpg/png"

# Data - Do NOT edit these
$DestinationFolder = "$Env:ProgramData\Images\Destop"
$LogFile = "$Env:ProgramData\Microsoft\IntuneManagementExtension\logs\SetDesktopBackground.log"
$DestinationPath = Join-Path -Path $DestinationFolder -ChildPath $DestinationFile

# Function to write to the log
function Write-Log {
    param (
        [string]$Message
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$Timestamp - $Message" | Out-File -FilePath $LogFile -Append -Force
}

Write-Log "Script started."

# Ensure the destination folder exists
if (-not (Test-Path -Path $DestinationFolder)) {
    try {
        New-Item -ItemType Directory -Path $DestinationFolder -Force
        Write-Log "Created directory: $DestinationFolder"
    } catch {
        Write-Log "Failed to create directory $DestinationFolder $_"
        exit 1
    }
}

# Download the image
try {
    Invoke-WebRequest -Uri $ImageUrl -OutFile $DestinationFile
    Write-Log "Image downloaded successfully to $DestinationFile"
} catch {
    Write-Log "Failed to download the image: $_"
    exit 1
}

# Set the wallpaper by updating the registry
try {
  Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "Wallpaper" -Value $DestinationPath
  
  # Update the desktop to apply changes
  RUNDLL32.EXE USER32.DLL,UpdatePerUserSystemParameters 1, True
  
  Write-Log "Wallpaper set successfully using registry."
} catch {
    Write-Log "Failed to set wallpaper in registry: $_"
    exit 1
}

Write-Log "Script completed successfully."