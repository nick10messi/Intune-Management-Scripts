$Taskname = "Restart IME service at network connection"
$taskExists = Get-ScheduledTask | Where-Object {$_.TaskName -like $Taskname}

if($taskExists) {
  Write-Output "Success"
  Exit 0
} 
else {
  Write-Output "Scheduled task not detected"
  Exit 1
}