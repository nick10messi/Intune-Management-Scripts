# Controleer en installeer NuGet provider indien nodig
if (-not (Get-PackageProvider -Name "NuGet" -ErrorAction SilentlyContinue)) {
    Install-PackageProvider -Name NuGet -Force -Scope AllUsers
}

# Controleer of PSWindowsUpdate module al geïnstalleerd is
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Install-Module -Name PSWindowsUpdate -Force -Scope AllUsers
}

# Importeer de module (indien nog niet geïmporteerd)
Import-Module -Name PSWindowsUpdate -Force

# Schakel Microsoft Update in
Add-WUServiceManager -MicrosoftUpdate -ErrorAction SilentlyContinue -Confirm:$false

# Installeer updates zonder herstart
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot