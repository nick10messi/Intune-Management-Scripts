$Taskname = "Restart IME service at network connection"

try {
    if (Get-ScheduledTask -TaskName $Taskname -ErrorAction SilentlyContinue) {
        Write-Output "Scheduled task exist, removing it."
        Unregister-ScheduledTask -TaskName $Taskname -Confirm:$false
    }
}
catch {
    Write-Output "error occured"
    Exit 1
}