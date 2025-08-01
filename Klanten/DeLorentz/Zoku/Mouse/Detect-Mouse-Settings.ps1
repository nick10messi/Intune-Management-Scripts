###########################################################################
# Auteur      : Nick Kok
# Doel        : Detecteert of ThreeFingerSlideEnabled is ingeschakeld
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
    $currentValue = Get-ItemProperty -Path $regPath -Name $valueName -ErrorAction Stop | Select-Object -ExpandProperty $valueName

    if ($currentValue -ne 0) {
        Write-Log -Message "ThreeFingerSlideEnabled is ingeschakeld (waarde: $currentValue)" -Level "INFO"
        exit 1
    } else {
        Write-Log -Message "ThreeFingerSlideEnabled is correct uitgeschakeld (waarde: 0)" -Level "INFO"
        exit 0
    }
} catch {
    Write-Log -Message "Fout bij lezen van register: $_" -Level "ERROR"
    exit 1
}