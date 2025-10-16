### Variables ###
$PrintShare = "\\PrintServer.domain\PrintShare" #UNC-path of the printer share
$DefaultPrinter = $false #Set this to $true to set the mapped printer as default printer

### Map printer if not already mapped
if ((Get-Printer).Name -eq $PrintShare){
    Write-Host "Printer is al gemapt"
}
Else {
    Add-Printer -ConnectionName $PrintShare -ErrorAction SilentlyContinue
	Start-Sleep -Seconds 10
}

### Set printer as default printer if $DefaultPrinter = $true
if ($DefaultPrinter -eq $true) {
    (New-Object -ComObject WScript.Network).SetDefaultPrinter($PrintShare)
}
else {
    Write-Host "Don't set mapped printer as the default printer"
}