
function Write-Line {
    Write-Host "----------------------------------------------------------------------------"
}

function Check-IsElevated { # Controleren of het script als administrator wordt uitgevoerd.
    Write-Line
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object System.Security.Principal.WindowsPrincipal($id)
    if ($p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Het script wordt uitgevoerd als administrator." -ForegroundColor Green
    } else { 
        Write-Host "Start het script opnieuw als administrator." -ForegroundColor Red 
        pause
        exit
    }  
 }

 # Check if powershell version is not PowerShell 7
 function Check-PowerShellVersion {
    if ($PSVersionTable.PSVersion.Major -eq 7) {
        Write-Line
        Write-Host "Dit script werkt niet met PowerShell 7, start het script met Windows PowerShell 5." -ForegroundColor Red
        pause
        exit
    }
}

 function Install-Benodigdheden { # Installeren van de benodigdheden.
    Write-Line
    Write-Host "Bezig met het installeren van benodigdheden..." 
    $env:Path += ";C:\Program Files\WindowsPowerShell\Scripts" # Toevoegen van de scripts folder aan de environment path.
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null # Installeren van de NuGet package provider.
    Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted| Out-Null # Instellen van de PowerShell Gallery als trusted repository.
    Install-Module -Name PowerShellGet -Force | Out-Null # Installeren van de PowerShellGet module.
    Install-Script -Name Get-WindowsAutopilotInfo -Force | Out-Null # Installeren van de Get-WindowsAutopilotInfo script.
}

function Upload-HardwareHash { # Uploaden van de hardware hash.
    Write-Line
    try {
        Write-Host "1. Persoonsgebonden: Apparaten die worden gebruikt door een specifieke gebruiker."
        Write-Host "2. Shared: Gedeelde apparaten die worden gebruikt door meerdere gebruikers" 
        Write-Line
        $groupTag = Read-Host "Selecteer de gewenste configuratie door het bijbehorende nummer te kiezen"
        Write-Line
        if ($groupTag -eq "1") { # Als de gebruiker 1 invoert is de grouptag: Windows_Persoonsgebonden.
            Write-Host "De hardware hash wordt geexporteerd naar de CSV met de grouptag: Windows_Persoonsgebonden."
            Get-Windowsautopilotinfo.ps1 -GroupTag "Windows_Persoonsgebonden" -OutputFile "${PSScriptRoot}\AutopilotHWID.csv" -append -ErrorAction Stop
        }
        elseif ($groupTag -eq "2") { # Als de gebruiker 2 invoert is de grouptag: Windows_Shared.
            Write-Host "De hardware hash wordt geexporteerd naar de CSV met de grouptag: Windows_Shared."
            Get-Windowsautopilotinfo.ps1 -GroupTag "Windows_Shared" -OutputFile "${PSScriptRoot}\AutopilotHWID.csv" -append -ErrorAction Stop
        }
        else {
            Write-Host "Ongeldige invoer, kies een groep tag door 1 of 2 in te voeren." -ForegroundColor Red
            Upload-HardwareHash # Opnieuw vragen om een groep tag te kiezen.
        }
        Write-Line
        Write-Host "1. Upload de csv met de hardware hash naar de Intune portal onder: Devices > Windows > Enrollment > Devices. " -ForegroundColor Yellow # Instructie weergeven.
        Write-Host "2. Wacht tot het Autopilot profiel is toegewezen en herstart vervolgens het apparaat (shutdown -r -t 0)." -ForegroundColor Yellow # Instructie weergeven.
    }
    catch {
        Write-Host "Er is iets fout gegaan bij het exporteren van de hardware hash." -ForegroundColor Red # Foutmelding weergeven.
        Write-Host "Foutmelding: $_" -ForegroundColor Red # Foutmelding weergeven in detail.
    }
}

# Starten van het script.
Check-IsElevated # Controleren of het script als administrator wordt uitgevoerd.
Check-PowerShellVersion # Controleren of het script wordt uitgevoerd met Windows PowerShell 5 en niet met 7.
Install-Benodigdheden # Installeren van de benodigdheden.
Upload-HardwareHash # Uploaden van de hardware hash.
pause