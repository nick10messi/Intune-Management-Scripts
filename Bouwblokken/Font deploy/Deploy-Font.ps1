# Variables
$BlobUrl = ""
$FontPath = "$env:ProgramData\Fonts"
$LogFile = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\InstallFont.log"
$DownloadedFontPath = Join-Path -Path $FontPath -ChildPath "<font-file>.ttf/otf"

# Function to Write to Log File
function Write-Log {
    param (
        [string]$Message
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "$Timestamp - $Message"
    Add-Content -Path $LogFile -Value $LogMessage
}

# Start Logging
Write-Log "Starting font installation process."

try {
    # Ensure the Fonts directory exists
    if (-not (Test-Path -Path $FontPath)) {
        Write-Log "Fonts directory not found. Creating directory at: $FontPath"
        New-Item -Path $FontPath -ItemType Directory -Force | Out-Null
    }

    # Download the font file from Azure Storage Blob
    Write-Log "Downloading font from: $BlobUrl"
    Invoke-WebRequest -Uri $BlobUrl -OutFile $DownloadedFontPath -ErrorAction Stop
    Write-Log "Font downloaded successfully to: $DownloadedFontPath"

    # Install the font by adding it to the system registry
    Write-Log "Registering the font in the system registry."
    $FontName = [System.IO.Path]::GetFileNameWithoutExtension($DownloadedFontPath)
    $RegistryKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
    Set-ItemProperty -Path $RegistryKey -Name "$FontName (TrueType)" -Value $DownloadedFontPath

    # Refresh the font cache
    Write-Log "Refreshing the font cache."
    & regsvr32 /u /s "$DownloadedFontPath"
    & regsvr32 /s "$DownloadedFontPath"

    Write-Log "Font installation completed successfully."
}
catch {
    Write-Log "An error occurred: $_"
    throw
}