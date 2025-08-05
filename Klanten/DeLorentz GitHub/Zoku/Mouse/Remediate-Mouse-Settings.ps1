###########################################################################
# Auteur      : Nick Kok
# Doel        : Zet ThreeFingerSlideEnabled en Enhance Pointer Precision uit
# Versie      : 1.0
# Datum       : 05-08-2025
###########################################################################

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR")]
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logFolder = "$env:LOCALAPPDATA\Microsoft\IntuneLogs"
    if (-not (Test-Path $logFolder)) {
        New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
    }
    "$timestamp [$Level] $Message" | Out-File -FilePath "$logFolder\ThreeFingerSlide-Remediate.log" -Append -Encoding utf8
}

try {
    $ptpPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad"
    $mousePath = "HKCU:\Control Panel\Mouse"

    foreach ($path in @($ptpPath, $mousePath)) {
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
            Write-Log -Message "Registerpad aangemaakt: $path" -Level "INFO"
        }
    }

    Set-ItemProperty -Path $ptpPath -Name "ThreeFingerSlideEnabled" -Value 0 -Type DWord
    Write-Log -Message "ThreeFingerSlideEnabled ingesteld op 0" -Level "INFO"

    Set-ItemProperty -Path $mousePath -Name "MouseSpeed" -Value "0"
    Set-ItemProperty -Path $mousePath -Name "MouseThreshold1" -Value "0"
    Set-ItemProperty -Path $mousePath -Name "MouseThreshold2" -Value "0"
    Write-Log -Message "Enhance Pointer Precision uitgeschakeld via MouseSpeed, MouseThreshold1, MouseThreshold2" -Level "INFO"

    exit 0
} catch {
    Write-Log -Message "Fout bij aanpassen van register: $_" -Level "ERROR"
    exit 1
}