# PS-script Content
$TaskName = "TASKNAME"
$PSScript ='CONTENT SCRIPT'
 
# Creates Folder for PS-script
$PSScriptLocation = 'C:\programdata\CustomScripts'
If(!(Test-Path $PSScriptLocation)) {
        New-Item -ItemType directory -Path $PSScriptLocation -Force | Out-Null
}
 
#Creates PS-script from script content
$PSScriptFile = "$PSScriptLocation\NAME.ps1"
$PSScript | Out-File -FilePath ($PSScriptFile)
 
# Create Scheduled Task
$PowershellArg = '-windowstyle hidden -ExecutionPolicy Bypass -file ' + '"' + $PSScriptFile + '"'
$principal = New-ScheduledTaskPrincipal -UserID "SYSTEM" -RunLevel Highest
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $PowershellArg
$Trigger = New-ScheduledTaskTrigger -AtLogOn
$Set = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -Compatibility Win8 -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Settings $Set -Principal $principal
Register-ScheduledTask -Force -TaskName $TaskName -InputObject $Task