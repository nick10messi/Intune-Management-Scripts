### Edit this variable ###
$ImageURL = ""
$DestinationFile = "lockscreen.jpg/png"

# Data - Do NOT edit these
$DestinationFolder = "$Env:ProgramData\Images\Lockscreen"
$LogFile = "$Env:ProgramData\Microsoft\IntuneManagementExtension\logs\SetLockScreenImage.log"
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
    }
  catch {
      Write-Log "Failed to create directory $DestinationFolder $_"
      exit 1
    }
}

# Download the image
try {
    Invoke-WebRequest -Uri $ImageURL -OutFile $DestinationPath
    Write-Log "Image downloaded successfully to $DestinationPath"
}
catch {
    Write-Log "Failed to download the image: $_"
    exit 1
}

# Update the lock screen image
try {
    # Copy the image to the system lock screen folder
    Copy-Item -Path $DestinationPath -Destination $LockScreenImagePath -Force
    Write-Log "Lock screen image updated successfully at $LockScreenImagePath"

    # Update registry to point to the new image
    $LockscreenRegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"
    
    if ((Test-Path -Path $LockscreenRegistryPath) -ne $true) { New-Item $LockscreenRegistryPath -force -ea SilentlyContinue }

    New-ItemProperty -Path $LockscreenRegistryPath -Name "LockScreenImageStatus" -Value 1 -PropertyType DWord  -Force -ea SilentlyContinue

    New-ItemProperty -Path $LockscreenRegistryPath -Name "LockScreenImagePath" -Value $DestinationPath -PropertyType String  -Force -ea SilentlyContinue

    New-ItemProperty -Path $LockscreenRegistryPath -Name "LockScreenImageUrl" -Value $DestinationPath -PropertyType String  -Force -ea SilentlyContinue;
 

    Write-Log "Lock screen registry keys updated successfully."
}
catch {
    Write-Log "Failed to update lock screen image: $_"
    exit 1
}

Write-Log "Script completed successfully."