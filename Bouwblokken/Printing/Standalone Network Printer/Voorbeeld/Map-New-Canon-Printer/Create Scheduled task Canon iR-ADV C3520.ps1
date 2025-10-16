#####################################################
# Start transcript for logging
#####################################################
$LogDirectory = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs"
Start-Transcript -Path "$LogDirectory\PrintMapping-Canon-iR-ADV-C3520.log"

###################################################################
# Check if folder: Printer Mapping exists, otherwise create it
###################################################################
$PrintMappingFolder = "$env:ProgramData\Printer Mapping\"

if (Test-Path $PrintMappingFolder) {
    Write-Host "Directory bestaat al"
}
else {
    New-Item -Path $PrintMappingFolder -ItemType Directory -Force
}

###################################################################################################
# Copy the PrintMapping.cmd and the PrintMapping-Helper-Script.vbs to ProgramData\Printer Mapping
###################################################################################################
$PrintMapping_ps = ".\Map Printer Canon iR-ADV C3520.ps1"
$PrintMapping_Helper_Script = ".\PrintMapping-Helper-Script.vbs"

Copy-Item -Path $PrintMapping_ps -Destination $PrintMappingFolder 
Copy-Item -Path $PrintMapping_Helper_Script -Destination $PrintMappingFolder 

###################################################################
# Copy exported XML scheduled task
###################################################################
$xml = ".\Map Printer Canon iR-ADV C3520.xml"
Copy-Item -Path $xml -Destination $PrintMappingFolder

###################################################################
# Register a new Scheduled Task using the XML
###################################################################
$Taskname = "Map Printer Canon-iR-ADV-C3520"
Register-ScheduledTask -xml (Get-Content $xml | Out-String) -TaskName $Taskname -TaskPath "\"

Stop-Transcript