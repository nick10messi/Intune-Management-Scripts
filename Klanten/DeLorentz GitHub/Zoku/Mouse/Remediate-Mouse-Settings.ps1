###########################################################################
# Auteur      : Nick Kok
# Doel        : Stelt ThreeFingerSlideEnabled, muisinstellingen en cursor-schema correct in
# Versie      : 1.0
# Datum       : 04-08-2025
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
    $cursorPath = "HKCU:\Control Panel\Cursors"

    foreach ($path in @($ptpPath, $mousePath, $cursorPath)) {
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
            Write-Log -Message "Registerpad aangemaakt: $path" -Level "INFO"
        }
    }

    Set-ItemProperty -Path $ptpPath -Name "ThreeFingerSlideEnabled" -Value 0 -Type DWord
    Write-Log -Message "ThreeFingerSlideEnabled ingesteld op 0" -Level "INFO"

    Set-ItemProperty -Path $mousePath -Name "MouseSpeed" -Value 0
    Set-ItemProperty -Path $mousePath -Name "MouseThreshold1" -Value 0
    Set-ItemProperty -Path $mousePath -Name "MouseThreshold2" -Value 0
    Write-Log -Message "MouseSpeed, MouseThreshold1 en MouseThreshold2 ingesteld op 0" -Level "INFO"

    Set-ItemProperty -Path $cursorPath -Name "(default)" -Value "Windows Black (large)"
    Write-Log -Message "Cursor-schema ingesteld op 'Windows Black (large)'" -Level "INFO"


    exit 0
} catch {
    Write-Log -Message "Fout bij aanpassen van register: $_" -Level "ERROR"
    exit 1
}
