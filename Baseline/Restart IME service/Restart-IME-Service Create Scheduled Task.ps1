###################################################################
# Check if folder: Logging exists, otherwise create it
###################################################################

$Logdir = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs"
$Logfile = "Restart-IME-Service Scheduled Task.log"

if (Test-Path $Logdir) {
    Write-Host "Directory bestaat al"
}
else {
    New-Item -Path $Logdir -ItemType Directory -Force
}

Start-Transcript -Path "$Logdir\$LogFile"

###################################################################
# Register a new Scheduled Task using the XML
###################################################################

$xml = ".\Restart IME service.xml"
$Taskname = "Restart IME service at network connection"

try {
    if (-NOT (Get-ScheduledTask -TaskName $Taskname -ErrorAction SilentlyContinue)) {
        Write-Output "Scheduled task does not exist, creating the task."
        Register-ScheduledTask -xml (Get-Content $xml | Out-String) -TaskName $Taskname -TaskPath "\"
    }
}
catch {
    Write-Output "error occured"
    Stop-Transcript
    Exit 1
}

Stop-Transcript