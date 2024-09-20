$hpwolf = Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -like "HP Wolf Security"} | Select-Object Name -ExpandProperty Name

if (($hpwolf) -eq "HP Wolf Security") {
    exit 1
}
else {
    exit 0
}