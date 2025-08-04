###########################################################################
# Auteur      : Nick Kok
# Doel        : Detecteert of ThreeFingerSlideEnabled, muisinstellingen en cursor-schema correct staan
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
    "$timestamp [$Level] $Message" | Out-File -FilePath "$logFolder\ThreeFingerSlide-Detect.log" -Append -Encoding utf8
}

try {
    $ptpPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad"
    $mousePath = "HKCU:\Control Panel\Mouse"
    $cursorPath = "HKCU:\Control Panel\Cursors"

    $threeFinger = Get-ItemProperty -Path $ptpPath -Name "ThreeFingerSlideEnabled" -ErrorAction Stop | Select-Object -ExpandProperty ThreeFingerSlideEnabled
    $mouseSpeed = Get-ItemProperty -Path $mousePath -Name "MouseSpeed" -ErrorAction Stop | Select-Object -ExpandProperty MouseSpeed
    $mouseThreshold1 = Get-ItemProperty -Path $mousePath -Name "MouseThreshold1" -ErrorAction Stop | Select-Object -ExpandProperty MouseThreshold1
    $mouseThreshold2 = Get-ItemProperty -Path $mousePath -Name "MouseThreshold2" -ErrorAction Stop | Select-Object -ExpandProperty MouseThreshold2
    $cursorScheme = Get-ItemProperty -Path $cursorPath -ErrorAction Stop | Select-Object -ExpandProperty "(default)"

    if (
        $threeFinger -ne 0 -or 
        $mouseSpeed -ne 0 -or 
        $mouseThreshold1 -ne 0 -or 
        $mouseThreshold2 -ne 0 -or 
        $cursorScheme -ne "Windows Black (large)"
    ) {
        Write-Log -Message "Instellingen niet correct: ThreeFingerSlideEnabled=$threeFinger, MouseSpeed=$mouseSpeed, MouseThreshold1=$mouseThreshold1, MouseThreshold2=$mouseThreshold2, CursorsDefault=$cursorScheme" -Level "INFO"
        exit 1
    } else {
        Write-Log -Message "Alle instellingen zijn correct." -Level "INFO"
        exit 0
    }
} catch {
    Write-Log -Message "Fout bij lezen van register: $_" -Level "ERROR"
    exit 1
}