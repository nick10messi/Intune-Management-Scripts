###########################################################################
# Auteur      : Nick Kok
# Doel        : Stelt ThreeFingerSlideEnabled in op uitgeschakeld (0)
# Versie      : 1.0
# Datum       : 01-08-2025
###########################################################################

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR")]
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp [$Level] $Message" | Out-File -FilePath "$env:LOCALAPPDATA\Microsoft\IntuneLogs\ThreeFingerSlide-Detect.log" -Append -Encoding utf8
}

try {
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad"
    $valueName = "ThreeFingerSlideEnabled"

    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
        Write-Log -Message "Registerpad aangemaakt: $regPath" -Level "INFO"
    }

    Set-ItemProperty -Path $regPath -Name $valueName -Value 0 -Type DWord
    Write-Log -Message "ThreeFingerSlideEnabled succesvol ingesteld op 0 (uitgeschakeld)" -Level "INFO"
    exit 0
} catch {
    Write-Log -Message "Fout bij aanpassen van register: $_" -Level "ERROR"
    exit 1
}
