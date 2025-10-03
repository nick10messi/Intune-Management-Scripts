# Initialiseer COM-object voor Windows Update
$updateSession = New-Object -ComObject Microsoft.Update.Session
$updateSearcher = $updateSession.CreateUpdateSearcher()
$searchResult = $updateSearcher.Search("IsInstalled=0 and Type='Software' and IsHidden=0")

if ($searchResult.Updates.Count -eq 0) {
    Write-Output "Geen updates gevonden."
    exit 0
}

# Updates downloaden
$updatesToDownload = New-Object -ComObject Microsoft.Update.UpdateColl
foreach ($update in $searchResult.Updates) {
    if ($update.EulaAccepted -eq $false) {
        $update.AcceptEula()
    }
    $updatesToDownload.Add($update) | Out-Null
}
$downloader = $updateSession.CreateUpdateDownloader()
$downloader.Updates = $updatesToDownload
$downloader.Download()

# Updates installeren
$updatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl
foreach ($update in $searchResult.Updates) {
    if ($update.IsDownloaded) {
        $updatesToInstall.Add($update) | Out-Null
    }
}
$installer = $updateSession.CreateUpdateInstaller()
$installer.Updates = $updatesToInstall
$installationResult = $installer.Install()

# Statusrapport
Write-Output "Resultaatcode: $($installationResult.ResultCode)"
Write-Output "Aantal geïnstalleerde updates: $($installationResult.Updates.Count)"
