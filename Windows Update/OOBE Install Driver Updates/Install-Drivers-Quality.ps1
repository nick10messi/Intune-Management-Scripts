# Zorg dat de NuGet-provider aanwezig is
if (-not (Get-PackageProvider -Name "NuGet" -ErrorAction SilentlyContinue)) {
    Write-Output "NuGet-provider niet gevonden. Installeren..."
    Install-PackageProvider -Name "NuGet" -Confirm:$false -Force
} else {
    Write-Output "NuGet-provider al aanwezig."
}

# Zorg dat PSGallery trusted is (anders krijg je prompt)
if (-not (Get-PSRepository -Name "PSGallery").InstallationPolicy -eq "Trusted") {
    Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
    Write-Output "PSGallery repository nu trusted ingesteld."
}

# Check of de OSD module beschikbaar is. Zo niet, installeer deze
if (-not (Get-Module -ListAvailable -Name OSD)) {
    Write-Output "OSD module nog niet geïnstalleerd. Installeren!"
    Install-Module OSD -ForceA
    Import-Module OSD
} 
else {
    Write-Output "OSD module al geïnstalleerd"
}

# Start driverupdate
try {
    Write-Output "Starten met installeren van beschikbare driverupdates..."
    Start-OOBEDeploy -UpdateDrivers
    Restart-Computer
} 
catch {
    Write-Error "Fout bij installeren van driverupdates: $_"
}