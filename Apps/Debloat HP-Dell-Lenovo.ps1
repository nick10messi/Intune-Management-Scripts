############################################################################################################
#                                         Initial Setup                                                    #
#                                                                                                          #
############################################################################################################
param (
    [string[]]$customwhitelist
)

##Elevate if needed

If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Write-Host "You didn't run this script as an Administrator. This script will self elevate to run as an Administrator and continue."
    Start-Sleep 1
    Write-Host "                                               3"
    Start-Sleep 1
    Write-Host "                                               2"
    Start-Sleep 1
    Write-Host "                                               1"
    Start-Sleep 1
    Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`" -WhitelistApps {1}" -f $PSCommandPath, ($WhitelistApps -join ',')) -Verb RunAs
    Exit
}

#no errors throughout
$ErrorActionPreference = 'silentlycontinue'


#Create Folder
$DebloatFolder = "C:\ProgramData\Debloat"
If (Test-Path $DebloatFolder) {
    Write-Output "$DebloatFolder exists. Skipping."
}
Else {
    Write-Output "The folder '$DebloatFolder' doesn't exist. This folder will be used for storing logs created after the script runs. Creating now."
    Start-Sleep 1
    New-Item -Path "$DebloatFolder" -ItemType Directory
    Write-Output "The folder $DebloatFolder was successfully created."
}

Start-Transcript -Path "C:\ProgramData\Debloat\Debloat.log"

############################################################################################################
#                                        Remove Manufacturer Bloat                                         #
#                                                                                                          #
############################################################################################################
##Check Manufacturer
write-host "Detecting Manufacturer"
$details = Get-CimInstance -ClassName Win32_ComputerSystem
$manufacturer = $details.Manufacturer


if ($manufacturer -like "*HP*") {
    Write-Host "HP detected"
    #Remove HP bloat


##HP Specific
$UninstallPrograms = @(
    "HP Client Security Manager",
    "HP Notifications",
    "HP Security Update Service",
    "HP System Default Settings",
    "HP Wolf Security",
    "HP Wolf Security Application Support for Sure Sense",
    "HP Wolf Security Application Support for Windows",
    "AD2F1837.HPPCHardwareDiagnosticsWindows",
    "AD2F1837.HPPowerManager",
    "AD2F1837.HPPrivacySettings",
    "AD2F1837.HPQuickDrop",
    "AD2F1837.HPSupportAssistant",
    "AD2F1837.HPSystemInformation",
    "AD2F1837.myHP",
    "RealtekSemiconductorCorp.HPAudioControl",
    "HP Sure Recover",
    "HP Sure Run Module",
    "RealtekSemiconductorCorp.HPAudioControl_2.39.280.0_x64__dt26b99r8h8gj",
    "HP Wolf Security - Console",
    "HP Wolf Security Application Support for Chrome 122.0.6261.139",
    "Windows Driver Package - HP Inc. sselam_4_4_2_453 AntiVirus  (11/01/2022 4.4.2.453)"
)



$UninstallPrograms = $UninstallPrograms | Where-Object{$appstoignore -notcontains $_}

$HPidentifier = "AD2F1837"

#$ProvisionedPackages = Get-AppxProvisionedPackage -Online | Where-Object {(($UninstallPrograms -contains $_.DisplayName) -or (($_.DisplayName -like "*$HPidentifier"))-and ($_.DisplayName -notin $WhitelistedApps))}

#$InstalledPackages = Get-AppxPackage -AllUsers | Where-Object {(($UninstallPrograms -contains $_.Name) -or (($_.Name -like "^$HPidentifier"))-and ($_.Name -notin $WhitelistedApps))}

$InstalledPrograms = $allstring | Where-Object {$UninstallPrograms -contains $_.Name}
foreach ($app in $UninstallPrograms) {
        
    if (Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app -ErrorAction SilentlyContinue) {
        Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app | Remove-AppxProvisionedPackage -Online
        Write-Host "Removed provisioned package for $app."
    } else {
        Write-Host "Provisioned package for $app not found."
    }

    if (Get-AppxPackage -Name $app -ErrorAction SilentlyContinue) {
        Get-AppxPackage -allusers -Name $app | Remove-AppxPackage -AllUsers
        Write-Host "Removed $app."
    } else {
        Write-Host "$app not found."
    }

UninstallAppFull -appName $app
    

}

##Belt and braces, remove via CIM too
foreach ($program in $UninstallPrograms) {
Get-CimInstance -Classname Win32_Product | Where-Object Name -Match $program | Invoke-CimMethod -MethodName UnInstall
}


#Remove HP Documentation if it exists
if (test-path -Path "C:\Program Files\HP\Documentation\Doc_uninstall.cmd") {
$A = Start-Process -FilePath "C:\Program Files\HP\Documentation\Doc_uninstall.cmd" -Wait -passthru -NoNewWindow
}

##Remove HP Connect Optimizer if setup.exe exists
if (test-path -Path 'C:\Program Files (x86)\InstallShield Installation Information\{6468C4A5-E47E-405F-B675-A70A70983EA6}\setup.exe') {
invoke-webrequest -uri "https://raw.githubusercontent.com/andrew-s-taylor/public/main/De-Bloat/HPConnOpt.iss" -outfile "C:\Windows\Temp\HPConnOpt.iss"

&'C:\Program Files (x86)\InstallShield Installation Information\{6468C4A5-E47E-405F-B675-A70A70983EA6}\setup.exe' @('-s', '-f1C:\Windows\Temp\HPConnOpt.iss')
}


##Remove other crap
if (Test-Path -Path "C:\Program Files (x86)\HP\Shared" -PathType Container) {Remove-Item -Path "C:\Program Files (x86)\HP\Shared" -Recurse -Force}
if (Test-Path -Path "C:\Program Files (x86)\Online Services" -PathType Container) {Remove-Item -Path "C:\Program Files (x86)\Online Services" -Recurse -Force}
if (Test-Path -Path "C:\ProgramData\HP\TCO" -PathType Container) {Remove-Item -Path "C:\ProgramData\HP\TCO" -Recurse -Force}
if (Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Amazon.com.lnk" -PathType Leaf) {Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Amazon.com.lnk" -Force}
if (Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Angebote.lnk" -PathType Leaf) {Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Angebote.lnk" -Force}
if (Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\TCO Certified.lnk" -PathType Leaf) {Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\TCO Certified.lnk" -Force}
if (Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Booking.com.lnk" -PathType Leaf) {Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Booking.com.lnk" -Force}
if (Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Adobe offers.lnk" -PathType Leaf) {Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Adobe offers.lnk" -Force}

Write-Host "Removed HP bloat"
}



if ($manufacturer -like "*Dell*") {
    Write-Host "Dell detected"
    #Remove Dell bloat

##Dell

$UninstallPrograms = @(
    "Dell Optimizer",
    "Dell Power Manager",
    "DellOptimizerUI",
    "Dell SupportAssist OS Recovery",
    "Dell SupportAssist",
    "Dell Optimizer Service",
    "Dell Optimizer Core",
    "DellInc.PartnerPromo",
    "DellInc.DellOptimizer",
    "DellInc.DellCommandUpdate",
    "DellInc.DellPowerManager",
    "DellInc.DellDigitalDelivery",
    "DellInc.DellSupportAssistforPCs",
    "DellInc.PartnerPromo",
    "Dell Command | Update",
    "Dell Command | Update for Windows Universal",
    "Dell Command | Update for Windows 10",
    "Dell Command | Power Manager",
    "Dell Digital Delivery Service",
    "Dell Digital Delivery",
    "Dell Peripheral Manager",
    "Dell Power Manager Service",
    "Dell SupportAssist Remediation",
    "SupportAssist Recovery Assistant",
    "Dell SupportAssist OS Recovery Plugin for Dell Update",
    "Dell SupportAssistAgent",
    "Dell Update - SupportAssist Update Plugin",
    "Dell Core Services",
    "Dell Pair",
    "Dell Display Manager 2.0",
    "Dell Display Manager 2.1",
    "Dell Display Manager 2.2",
    "Dell SupportAssist Remediation",
    "Dell Update - SupportAssist Update Plugin",
    "DellInc.PartnerPromo"
)



    $UninstallPrograms = $UninstallPrograms | Where-Object{$appstoignore -notcontains $_}


foreach ($app in $UninstallPrograms) {
        
    if (Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app -ErrorAction SilentlyContinue) {
        Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app | Remove-AppxProvisionedPackage -Online
        Write-Host "Removed provisioned package for $app."
    } else {
        Write-Host "Provisioned package for $app not found."
    }

    if (Get-AppxPackage -Name $app -ErrorAction SilentlyContinue) {
        Get-AppxPackage -allusers -Name $app | Remove-AppxPackage -AllUsers
        Write-Host "Removed $app."
    } else {
        Write-Host "$app not found."
    }

    UninstallAppFull -appName $app

    

}

##Belt and braces, remove via CIM too
foreach ($program in $UninstallPrograms) {
    write-host "Removing $program"
    Get-CimInstance -Query "SELECT * FROM Win32_Product WHERE name = '$program'" | Invoke-CimMethod -MethodName Uninstall
    }

##Manual Removals

##Dell Optimizer
$dellSA = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -like "Dell*Optimizer*Core" } | Select-Object -Property UninstallString
 
ForEach ($sa in $dellSA) {
    If ($sa.UninstallString) {
        try {
        cmd.exe /c $sa.UninstallString -silent
        }
        catch {
            Write-Warning "Failed to uninstall Dell Optimizer"
        }
    }
}


##Dell Dell SupportAssist Remediation
$dellSA = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -match "Dell SupportAssist Remediation" } | Select-Object -Property QuietUninstallString
 
ForEach ($sa in $dellSA) {
    If ($sa.QuietUninstallString) {
        try {
            cmd.exe /c $sa.QuietUninstallString
            }
            catch {
                Write-Warning "Failed to uninstall Dell Support Assist Remediation"
            }    }
}

##Dell Dell SupportAssist OS Recovery Plugin for Dell Update
$dellSA = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -match "Dell SupportAssist OS Recovery Plugin for Dell Update" } | Select-Object -Property QuietUninstallString
 
ForEach ($sa in $dellSA) {
    If ($sa.QuietUninstallString) {
        try {
            cmd.exe /c $sa.QuietUninstallString
            }
            catch {
                Write-Warning "Failed to uninstall Dell Support Assist Remediation"
            }    }
}



    ##Dell Display Manager
$dellSA = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -like "Dell*Display*Manager*" } | Select-Object -Property UninstallString
 
ForEach ($sa in $dellSA) {
    If ($sa.UninstallString) {
        try {
        cmd.exe /c $sa.UninstallString /S
        }
        catch {
            Write-Warning "Failed to uninstall Dell Optimizer"
        }
    }
}

    ##Dell Peripheral Manager

            try {
            start-process c:\windows\system32\cmd.exe '/c "C:\Program Files\Dell\Dell Peripheral Manager\Uninstall.exe" /S'
            }
            catch {
                Write-Warning "Failed to uninstall Dell Optimizer"
            }


    ##Dell Pair

            try {
                start-process c:\windows\system32\cmd.exe '/c "C:\Program Files\Dell\Dell Pair\Uninstall.exe" /S'
            }
            catch {
                Write-Warning "Failed to uninstall Dell Optimizer"
            }

        }


if ($manufacturer -like "Lenovo") {
    Write-Host "Lenovo detected"

    #Remove HP bloat

##Lenovo Specific
    # Function to uninstall applications with .exe uninstall strings

    function UninstallApp {

        param (
            [string]$appName
        )

        # Get a list of installed applications from Programs and Features
        $installedApps = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*,
        HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
        Where-Object { $_.DisplayName -like "*$appName*" }

        # Loop through the list of installed applications and uninstall them

        foreach ($app in $installedApps) {
            $uninstallString = $app.UninstallString
            $displayName = $app.DisplayName
            Write-Host "Uninstalling: $displayName"
            Start-Process $uninstallString -ArgumentList "/VERYSILENT" -Wait
            Write-Host "Uninstalled: $displayName" -ForegroundColor Green
        }
    }

    ##Stop Running Processes

    $processnames = @(
    "SmartAppearanceSVC.exe"
    "UDClientService.exe"
    "ModuleCoreService.exe"
    "ProtectedModuleHost.exe"
    "*lenovo*"
    "FaceBeautify.exe"
    "McCSPServiceHost.exe"
    "mcapexe.exe"
    "MfeAVSvc.exe"
    "mcshield.exe"
    "Ammbkproc.exe"
    "AIMeetingManager.exe"
    "DADUpdater.exe"
    "CommercialVantage.exe"
    )

    foreach ($process in $processnames) {
        write-host "Stopping Process $process"
        Get-Process -Name $process | Stop-Process -Force
        write-host "Process $process Stopped"
    }

    $UninstallPrograms = @(
        "E046963F.AIMeetingManager",
        "E0469640.SmartAppearance",
        "MirametrixInc.GlancebyMirametrix",
        "E046963F.LenovoCompanion",
        "E0469640.LenovoUtility",
        "E0469640.LenovoSmartCommunication",
        "E046963F.LenovoSettingsforEnterprise",
        "E046963F.cameraSettings",
        "4505Fortemedia.FMAPOControl2_2.1.37.0_x64__4pejv7q2gmsnr",
        "ElevocTechnologyCo.Ltd.SmartMicrophoneSettings_1.1.49.0_x64__ttaqwwhyt5s6t",
        "Lenovo User Guide"
    )


            $UninstallPrograms = $UninstallPrograms | Where-Object { $appstoignore -notcontains $_ }
    
    
        
    $InstalledPrograms = $allstring | Where-Object {(($_.Name -in $UninstallPrograms))}

    
foreach ($app in $UninstallPrograms) {
        
    if (Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app -ErrorAction SilentlyContinue) {
        Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app | Remove-AppxProvisionedPackage -Online
        Write-Host "Removed provisioned package for $app."
    } else {
        Write-Host "Provisioned package for $app not found."
    }

    if (Get-AppxPackage -Name $app -ErrorAction SilentlyContinue) {
        Get-AppxPackage -allusers -Name $app | Remove-AppxPackage -AllUsers
        Write-Host "Removed $app."
    } else {
        Write-Host "$app not found."
    }

    UninstallAppFull -appName $app
   

}


##Belt and braces, remove via CIM too
foreach ($program in $UninstallPrograms) {
    Get-CimInstance -Classname Win32_Product | Where-Object Name -Match $program | Invoke-CimMethod -MethodName UnInstall
    }

    # Get Lenovo Vantage service uninstall string to uninstall service
    $lvs = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object DisplayName -eq "Lenovo Vantage Service"
    if (!([string]::IsNullOrEmpty($lvs.QuietUninstallString))) {
        $uninstall = "cmd /c " + $lvs.QuietUninstallString
        Write-Host $uninstall
        Invoke-Expression $uninstall
    }

    # Uninstall Lenovo Smart
    UninstallApp -appName "Lenovo Smart"

    # Uninstall Ai Meeting Manager Service
    UninstallApp -appName "Ai Meeting Manager"

    # Uninstall ImController service
    ##Check if exists
    $path = "c:\windows\system32\ImController.InfInstaller.exe"
    if (Test-Path $path) {
        Write-Host "ImController.InfInstaller.exe exists"
        $uninstall = "cmd /c " + $path + " -uninstall"
        Write-Host $uninstall
        Invoke-Expression $uninstall
    }
    else {
        Write-Host "ImController.InfInstaller.exe does not exist"
    }
    ##Invoke-Expression -Command 'cmd.exe /c "c:\windows\system32\ImController.InfInstaller.exe" -uninstall'

    # Remove vantage associated registry keys
    Remove-Item 'HKLM:\SOFTWARE\Policies\Lenovo\E046963F.LenovoCompanion_k1h2ywk1493x8' -Recurse -ErrorAction SilentlyContinue
    Remove-Item 'HKLM:\SOFTWARE\Policies\Lenovo\ImController' -Recurse -ErrorAction SilentlyContinue
    Remove-Item 'HKLM:\SOFTWARE\Policies\Lenovo\Lenovo Vantage' -Recurse -ErrorAction SilentlyContinue
    #Remove-Item 'HKLM:\SOFTWARE\Policies\Lenovo\Commercial Vantage' -Recurse -ErrorAction SilentlyContinue

     # Uninstall AI Meeting Manager Service
     $path = 'C:\Program Files\Lenovo\Ai Meeting Manager Service\unins000.exe'
     $params = "/SILENT"
     if (test-path -Path $path) {
     Start-Process -FilePath $path -ArgumentList $params -Wait
     }
    # Uninstall Lenovo Vantage
    $pathname = (Get-ChildItem -Path "C:\Program Files (x86)\Lenovo\VantageService").name
    $path = "C:\Program Files (x86)\Lenovo\VantageService\$pathname\Uninstall.exe"
    $params = '/SILENT'
    if (test-path -Path $path) {
        Start-Process -FilePath $path -ArgumentList $params -Wait
    }
 
    ##Uninstall Smart Appearance
    $path = 'C:\Program Files\Lenovo\Lenovo Smart Appearance Components\unins000.exe'
    $params = '/SILENT'
    if (test-path -Path $path) {
        try {
            Start-Process -FilePath $path -ArgumentList $params -Wait
        }
        catch {
            Write-Warning "Failed to start the process"
        }
    }
$lenovowelcome = "c:\program files (x86)\lenovo\lenovowelcome\x86"
if (Test-Path $lenovowelcome) {
    # Remove Lenovo Now
    Set-Location "c:\program files (x86)\lenovo\lenovowelcome\x86"

    # Update $PSScriptRoot with the new working directory
    $PSScriptRoot = (Get-Item -Path ".\").FullName
    try {
        invoke-expression -command .\uninstall.ps1 -ErrorAction SilentlyContinue
    } catch {
        write-host "Failed to execute uninstall.ps1"
    }

    Write-Host "All applications and associated Lenovo components have been uninstalled." -ForegroundColor Green
}

$lenovonow = "c:\program files (x86)\lenovo\LenovoNow\x86"
if (Test-Path $lenovonow) {
    # Remove Lenovo Now
    Set-Location "c:\program files (x86)\lenovo\LenovoNow\x86"

    # Update $PSScriptRoot with the new working directory
    $PSScriptRoot = (Get-Item -Path ".\").FullName
    try {
        invoke-expression -command .\uninstall.ps1 -ErrorAction SilentlyContinue
    } catch {
        write-host "Failed to execute uninstall.ps1"
    }

    Write-Host "All applications and associated Lenovo components have been uninstalled." -ForegroundColor Green
}


$filename = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\User Guide.lnk"

if (Test-Path $filename) {
    Remove-Item -Path $filename -Force
}
}

write-host "Completed"

Stop-Transcript