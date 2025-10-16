$Taskname = "Map Printer Canon-iR-ADV-C3520"
$taskExists = Get-ScheduledTask | Where-Object {$_.TaskName -like $Taskname}

if($taskExists) {
  Write-Host "Success"
  Exit 0
} 
else {
  Exit 1
}