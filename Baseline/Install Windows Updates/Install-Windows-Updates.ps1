# Zorg ervoor dat script met verhoogde rechten draait
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Output "Dit script moet als Administrator worden uitgevoerd."
    exit 1
}

# Forceer ophalen van alle beschikbare updates
$Session = New-Object -ComObject Microsoft.Update.Session
$Searcher = $Session.CreateUpdateSearcher()
$Searcher.ServerSelection = 2  # 2 = Microsoft Update (inclusief drivers en optionele updates)
$SearchResult = $Searcher.Search("IsInstalled=0")

if ($SearchResult.Updates.Count -eq 0) {
    Write-Output "Geen updates beschikbaar."
    exit 0
}

# Installeer alle gevonden updates
$UpdatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl

foreach ($Update in $SearchResult.Updates) {
    Write-Output "Toevoegen: $($Update.Title)"
    $UpdatesToInstall.Add($Update) | Out-Null
}

$Installer = $Session.CreateUpdateInstaller()
$Installer.Updates = $UpdatesToInstall
$InstallationResult = $Installer.Install()

Write-Output "Installatiestatus: $($InstallationResult.ResultCode)"
Write-Output "Aantal geïnstalleerde updates: $($InstallationResult.Updates.Count)"