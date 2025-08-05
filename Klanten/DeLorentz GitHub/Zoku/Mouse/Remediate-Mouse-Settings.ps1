###########################################################################
# Auteur      : Nick Kok
# Doel        : Stelt touchpad, muisinstellingen en cursorstijl (klassiek en modern) correct in
# Versie      : 1.2
# Datum       : 01-08-2025
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
    $modernCursorPath = "HKCU:\Software\Microsoft\Accessibility\CursorIndicator"
    $cursorDir = "$env:SystemRoot\\Cursors"

    foreach ($path in @($ptpPath, $mousePath, $cursorPath, $modernCursorPath)) {
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
            Write-Log -Message "Registerpad aangemaakt: $path" -Level "INFO"
        }
    }

    # Touchpadinstelling
    Set-ItemProperty -Path $ptpPath -Name "ThreeFingerSlideEnabled" -Value 0 -Type DWord
    Write-Log -Message "ThreeFingerSlideEnabled ingesteld op 0" -Level "INFO"

    # Muisinstellingen
    Set-ItemProperty -Path $mousePath -Name "MouseSpeed" -Value "0"
    Set-ItemProperty -Path $mousePath -Name "MouseThreshold1" -Value "0"
    Set-ItemProperty -Path $mousePath -Name "MouseThreshold2" -Value "0"
    Write-Log -Message "MouseSpeed, MouseThreshold1 en MouseThreshold2 ingesteld op 0" -Level "INFO"

    # Klassiek schema instellen
    Set-Item -Path $cursorPath -Value "Windows Black (large)"
    Set-ItemProperty -Path $cursorPath -Name "Arrow"         -Value "$cursorDir\\arrow_l.cur"
    Set-ItemProperty -Path $cursorPath -Name "Hand"          -Value "$cursorDir\\hand_l.cur"
    Set-ItemProperty -Path $cursorPath -Name "Help"          -Value "$cursorDir\\help_l.cur"
    Set-ItemProperty -Path $cursorPath -Name "AppStarting"   -Value "$cursorDir\\wait_l.ani"
    Set-ItemProperty -Path $cursorPath -Name "Wait"          -Value "$cursorDir\\busy_l.ani"
    Set-ItemProperty -Path $cursorPath -Name "Crosshair"     -Value "$cursorDir\\cross_l.cur"
    Set-ItemProperty -Path $cursorPath -Name "IBeam"         -Value "$cursorDir\\beam_l.cur"
    Set-ItemProperty -Path $cursorPath -Name "NWPen"         -Value "$cursorDir\\pen_l.cur"
    Set-ItemProperty -Path $cursorPath -Name "No"            -Value "$cursorDir\\no_l.cur"
    Set-ItemProperty -Path $cursorPath -Name "SizeNS"        -Value "$cursorDir\\size1_l.cur"
    Set-ItemProperty -Path $cursorPath -Name "SizeWE"        -Value "$cursorDir\\size2_l.cur"
    Set-ItemProperty -Path $cursorPath -Name "SizeNWSE"      -Value "$cursorDir\\size3_l.cur"
    Set-ItemProperty -Path $cursorPath -Name "SizeNESW"      -Value "$cursorDir\\size4_l.cur"
    Set-ItemProperty -Path $cursorPath -Name "SizeAll"       -Value "$cursorDir\\move_l.cur"
    Set-ItemProperty -Path $cursorPath -Name "UpArrow"       -Value "$cursorDir\\up_l.cur"
    Set-ItemProperty -Path $cursorPath -Name "Scheme Source" -Value 2
    Write-Log -Message "Klassiek cursor-schema 'Windows Black (large)' toegepast" -Level "INFO"

    # CursorBaseSize instellen (voor moderne weergave)
    Set-ItemProperty -Path $cursorPath -Name "CursorBaseSize" -Value 48 -Type DWord
    Write-Log -Message "CursorBaseSize ingesteld op 48px" -Level "INFO"

    # Moderne cursorinstellingen
    Set-ItemProperty -Path $modernCursorPath -Name "CursorType" -Value 2 -Type DWord   # 2 = zwart
    Set-ItemProperty -Path $modernCursorPath -Name "CursorSize" -Value 3 -Type DWord   # 3 = groot
    Write-Log -Message "Moderne cursorstijl ingesteld op zwart en groot" -Level "INFO"

    # API-aanroep om wijzigingen door te voeren
    $code = @'
using System;
using System.Runtime.InteropServices;

public class NativeMethods {
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern bool SystemParametersInfo(int uAction, int uParam, IntPtr lpvParam, int fuWinIni);
}
'@

    Add-Type -TypeDefinition $code
    [void][NativeMethods]::SystemParametersInfo(0x0057, 0, [IntPtr]::Zero, 0x01)
    Write-Log -Message "Cursorwijziging direct toegepast via SystemParametersInfo" -Level "INFO"

    exit 0
} catch {
    Write-Log -Message "Fout bij aanpassen van register: $_" -Level "ERROR"
    exit 1
}
