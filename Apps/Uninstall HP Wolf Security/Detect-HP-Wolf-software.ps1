$hpwolf = Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -like "HP Wolf Security"} | Select-Object Name -ExpandProperty Name

if (($hpwolf) -eq "HP Wolf Security") {
    Write-Output "HP Wolf Security is geïnstalleerd"
    exit 1
}
else {
    Write-Output "HP Wolf Security is niet geïnstalleerd"
    exit 0
}