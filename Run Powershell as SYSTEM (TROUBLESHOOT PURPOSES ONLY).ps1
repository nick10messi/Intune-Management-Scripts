# Variables
$PSTools_Link = "https://download.sysinternals.com/files/PSTools.zip"

# Create Path for PSTools
if (-NOT (Test-Path "$env:ProgramData\PSTools")) {
    New-Item -ItemType Directory -Force -Path "$env:ProgramData\PSTools"
}

# Download PSTools
(New-Object System.Net.WebClient).DownloadFile("$PSTools_Link","$env:ProgramData\PSTools\PSTools.zip")

# Unpack files
Expand-Archive -Path "$env:ProgramData\PSTools\PSTools.zip" -DestinationPath "$env:ProgramData\PSTools"

# Create and set file for ASR Regkey removal
$Content = @"
reg export "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender\Policy Manager" "$env:ProgramData\PSTools\ASRRegistryBackup.reg" /y
timeout /t 2
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender\Policy Manager" /v ASRRules /f
timeout /t 2
"@
New-Item -ItemType File -Force -Path "$env:ProgramData\PSTools\ASRRegRemove.cmd"
Set-Content -Path "$env:ProgramData\PSTools\ASRRegRemove.cmd" -Value $Content

# Create and set file for ASR Regkey restore
$Content = @"
reg import "$env:ProgramData\PSTools\ASRRegistryBackup.reg"
"@
New-Item -ItemType File -Force -Path "$env:ProgramData\PSTools\ASRRegRestore.cmd"
Set-Content -Path "$env:ProgramData\PSTools\ASRRegRestore.cmd" -Value $Content

# Register ASR removal task
$User = "SYSTEM"
$Action = New-ScheduledTaskAction -Execute "$env:ProgramData\PSTools\ASRRegRemove.cmd"
Register-ScheduledTask -TaskName "ASRRemoval" -User $User -Action $Action -Force -RunLevel Highest

# Register ASR restore task
$User = "SYSTEM"
$Action = New-ScheduledTaskAction -Execute "$env:ProgramData\PSTools\ASRRegRestore.cmd"
Register-ScheduledTask -TaskName "ASRRestore" -User $User -Action $Action -Force -RunLevel Highest

# Run ASR Key removal
Start-ScheduledTask -TaskName "ASRRemoval"
Start-Sleep -Seconds 5

# Run Powershell as System and wait untill it the process is closed.
Start-Process "$env:ProgramData\PSTools\PsExec.exe" -ArgumentList "-accepteula -i -s powershell.exe" -Wait

# Restore ASR Rules from the backup file
Start-ScheduledTask -TaskName "ASRRestore"
Start-Sleep -Seconds 5

# Clean-up PSTools folder
Remove-Item -Path "$env:ProgramData\PSTools" -Force -Recurse

# Clean-up scheduled tasks
Get-ScheduledTask | Where-Object {$_.TaskName -eq "ASRRemoval"} | Unregister-ScheduledTask -Confirm:$false
Get-ScheduledTask | Where-Object {$_.TaskName -eq "ASRRestore"} | Unregister-ScheduledTask -Confirm:$false

# End script
Write-Host "All done" -ForegroundColor Green