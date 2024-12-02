###############################################################################################################################
#Change Startnet.cmd script, Add Wallaper and Add start script.
###############################################################################################################################
#User specific vars !!!!Change this to your own settings!!!!
#Possible Install URLs!
#https://occwsendpointmanager.blob.core.windows.net/osdv3/Scripts/Generic/OSDcloud_Choice.ps1
#https://occwsendpointmanager.blob.core.windows.net/osdv3/Scripts/Generic/OSDcloud_ENG_W10_22H2_Generic.ps1
#https://occwsendpointmanager.blob.core.windows.net/osdv3/Scripts/Generic/OSDcloud_ENG_W11_22H2_Generic.ps1
#https://occwsendpointmanager.blob.core.windows.net/osdv3/Scripts/Generic/OSDcloud_ENG_W11_23H2_Generic.ps1
#https://occwsendpointmanager.blob.core.windows.net/osdv3/Scripts/Generic/OSDcloud_NL_W10_22H2_Generic.ps1
#https://occwsendpointmanager.blob.core.windows.net/osdv3/Scripts/Generic/OSDcloud_NL_W11_22H2_Generic.ps1
#https://occwsendpointmanager.blob.core.windows.net/osdv3/Scripts/Generic/OSDcloud_NL_W11_23H2_Generic.ps1
#
#Customer Specific Scripts
#https://occwsendpointmanager.blob.core.windows.net/osdv3/Scripts/Customer/OSDcloud_NL_W11_23H2_Jumbo.ps1
###############################################################################################################################
Set-OSDCloudWorkspace -WorkspacePath 'C:\ProgramData\OSDCloud'
Edit-OSDCloudWinPE -CloudDriver *
$InstallURL = 'https://occwsendpointmanager.blob.core.windows.net/osdv3/Scripts/Customer/OSDcloud_NL_W11_23H2_RGF.ps1'
Write-Host -ForegroundColor Yellow "InstallURL is set at $($InstallURL)"
###############################################################################################################################
#Default varbs !!!!DONT TOUCH THIS PART!!!!!!
###############################################################################################################################
$WorkspacePath = Get-OSDCloudWorkspace
$WallpaperURL = 'https://occwsendpointmanager.blob.core.windows.net/osdv3/Background/OSD_Background_Image_V301.jpg'
$ConclusionSetupURL = 'https://occwsendpointmanager.blob.core.windows.net/osdv3/Initialization/Initialize-OSDConclusion-V3.ps1'
###############################################################################################################################
#Lets go !!!!DONT TOUCH THIS PART!!!!!!
###############################################################################################################################
# Set Image path if Jumbo ISO is being made
if ($InstallURL -like "*Jumbo*") {
    if (Test-Path "$WorkspacePath\Media - Jumbo") {
        Remove-Item -LiteralPath "$WorkspacePath\Media - Jumbo" -Recurse
        Copy-Item -LiteralPath "$WorkspacePath\Media" -Destination "$WorkspacePath\Media - Jumbo" -Recurse
    }
    else {
        Copy-Item -LiteralPath "$WorkspacePath\Media" -Destination "$WorkspacePath\Media - Jumbo" -Recurse
    }
    # Mount Image
    $MountMyWindowsImage = Mount-MyWindowsImage -ImagePath "$WorkspacePath\Media - Jumbo\Sources\boot.wim"
    $MountPath = $MountMyWindowsImage.Path
    $MountPath

    # Jumbo action to remove rtu53cx22x64 drivers. This fixes a compatibility issue with the network
    if ($InstallURL -like "*Jumbo*") {

        $RTUDriverPaths = Get-ChildItem -LiteralPath "$MountPath\Windows\System32\DriverStore\FileRepository" | Where-Object { $_.BaseName -like "rtu53cx22x64*" }
        foreach ($RTUDruverPath in $RTUDriverPaths.BaseName) {
            $INFFile = Get-ChildItem -LiteralPath "$MountPath\Windows\System32\DriverStore\FileRepository\$RTUDruverPath" | Where-Object { $_.Name -like "*.inf" }
            $INFFile
            Dism /Image:$MountPath /remove-driver /driver:"$($INFFile.FullName)"
        }
    }
}
else {
    # Mount image
    $MountMyWindowsImage = Mount-MyWindowsImage -ImagePath "$WorkspacePath\Media\Sources\boot.wim"
    $MountPath = $MountMyWindowsImage.Path
    $MountPath
}

#Download wallpaper
$WallpaperSavePath = "$env:ProgramData\Enablement_Woonkamer.jpg"
Invoke-WebRequest -Method Get -Uri $WallpaperURL -OutFile $WallpaperSavePath

#download script
$ScriptSavePath = "$env:ProgramData\Initialize-OSDConclusion.ps1"
Invoke-WebRequest -Method Get -Uri $ConclusionSetupURL -OutFile $ScriptSavePath

#Add wallpaper to image
Copy-Item -Path $WallpaperSavePath -Destination "$env:TEMP\winpe.jpg" -Force | Out-Null
robocopy "$env:TEMP" "$MountPath\Windows\System32" winpe.jpg /ndl /njh /njs /b /np /r:0 /w:0

#Add script to X:\Program Files\WindowsPowerShell\Scripts\
Copy-Item -Path $ScriptSavePath -Destination "$env:TEMP\Initialize-OSDConclusion.ps1" -Force | Out-Null
robocopy "$env:TEMP" "$MountPath\Program Files\WindowsPowerShell\Scripts" 'Initialize-OSDConclusion.ps1' /ndl /njh /njs /b /np /r:0 /w:0

#Save module to WIM
Save-Module -Name OSD -Path "$MountPath\Program Files\WindowsPowerShell\Modules" -Force

#Create Startnet
$StartnetCMD = @"
@ECHO OFF
wpeinit
cd\
title Conclusion OSD
ECHO Initialize Setup
PowerShell -NoLogo -Ex ByPass -File "X:\Program Files\WindowsPowerShell\Scripts\Initialize-OSDConclusion.ps1"
ECHO Start Invoke-WebPSScript
start /wait PowerShell -NoL -C Invoke-WebPSScript '$InstallURL'
"@

#Add startnet to image
$StartnetCMD | Out-File -FilePath "$MountPath\Windows\System32\Startnet.cmd" -Encoding ascii -Width 2000 -Force

#Save image
$MountMyWindowsImage | Dismount-MyWindowsImage -save

#Clean-up image before generating new OSD file
Export-WindowsImage -SourceImagePath "$WorkspacePath\Media\Sources\boot.wim" -SourceIndex 1 -DestinationImagePath "$env:ProgramData\boot.wim" | Out-Null
robocopy "$env:ProgramData" "$WorkspacePath\Media\Sources" boot.wim /ndl /njh /njs /b /np /r:0 /w:0 /A-:SH
Start-Sleep -Seconds 5
Remove-Item -LiteralPath "$env:ProgramData\boot.wim" | Out-Null

#Create new ISO
New-OSDCloudISO -WorkspacePath $WorkspacePath

#Rename file according to running script
$OldFileName = "OSDCloud.iso"
$CurrentDate = Get-Date -Format "dd-MM-yyyy"
$SplitFileNames = ((($InstallURL.Split("/") | Where-Object { $_ -like "*.ps1" }).Split(".") | Where-Object { $_ -notcontains "ps1" }).Split("_"))
$MergeName = $null
foreach ($SplitName in $SplitFileNames) {
    if ($SplitName -eq "OSDcloud") {
        $MergeName += "OSDCloud_"
    }
    else {
        $MergeName += "$($SplitName)_"
    }
}

#Set filename and change it
$NewFileName = "$($MergeName)$($CurrentDate).iso"
Rename-Item -LiteralPath "$WorkspacePath\$OldFileName" -NewName "$NewFileName"
###############################################################################################################################
#End
###############################################################################################################################