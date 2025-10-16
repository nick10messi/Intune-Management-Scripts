# Remove Print Mapping task
$Taskname = "Map Printer Canon-iR-ADV-C3520"
Unregister-ScheduledTask -TaskName $Taskname -Confirm:$false

# Remove printer from device
$Printer = "Canon iR-ADV C3520" #Name can be checked with Get-Printer command on reference device

if ((Get-Printer).Name -eq $Printer){
    Remove-Printer $Printer -ErrorAction SilentlyContinue
}
Else {
    Write-Host "Printer is al verwijderd"
}