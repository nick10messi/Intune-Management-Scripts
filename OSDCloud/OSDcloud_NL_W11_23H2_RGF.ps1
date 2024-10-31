#Welcome :)
$Driveletter = (Get-Volume | where-object { ($_.FileSystemLabel -eq 'OSDCloudUSB' -and $_.DriveType -eq 'Removable' -and $_.FileSystemType -eq 'NTFS' -and $_.OperationalStatus -eq 'OK' -and $_.Size -gt 18gb ) }).driveletter
$TranscriptPath = "$($driveletter):\Logs"
if (-NOT (Test-Path $TranscriptPath)) {
    New-Item -Path $TranscriptPath -ItemType Directory -Force -ErrorAction Stop | Out-Null    
}

$Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Deploy-OSDCloud_Conclusion.log"
Start-Transcript -Path (Join-Path $TranscriptPath $Transcript) -ErrorAction Ignore
Write-host -ForegroundColor DarkGray "========================================================================="
Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))" -NoNewline; Write-Host -ForegroundColor Cyan ' Starting Conclusion Hybride Werken Custom OSDCloud..'

#Check if Initialization has finished succesfully
$Initializationfile = "X:\Succesfull.txt"
if (-NOT(Test-Path $Initializationfile)) {
    Write-Host -ForegroundColor DarkGray "========================================================================="
    Write-host -ForegroundColor Red "OSDCloud did not finish Initialization correctly."
    Read-Host "Press Enter to shut down the Computer."
    Stop-Computer
    start-sleep -seconds 1000
}

#import module
Write-host -ForegroundColor DarkGray "========================================================================="
Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))" -NoNewline; Write-Host -ForegroundColor Cyan ' Importing OSD PowerShell Module'
$OSDRequiredVersion = "24.8.5.1"
$OSDInstalledVersion = (Get-InstalledModule -Name OSD).Version

if (-NOT($OSDInstalledVersion -eq $OSDRequiredVersion)) {
    Remove-Module -name OSD -Force -ErrorAction silentlycontinue
    Uninstall-Module -name OSD -Allversions -Force -ErrorAction silentlycontinue
    Install-Module -Name OSD -RequiredVersion $OSDRequiredVersion -Force -SkipPublisherCheck
    Import-Module OSD -RequiredVersion $OSDRequiredVersion -Force -ErrorAction Ignore -WarningAction Ignore
    $OSDVersion = (Get-Module -Name OSD).Version
}
else {
    Import-Module OSD -Force
    $OSDVersion = (Get-Module -Name OSD).Version
}

#Check if correct OSD Module is loaded
if (-NOT($OSDVersion -eq $OSDRequiredVersion)) {
    Write-Host -ForegroundColor DarkGray "========================================================================="
    Write-Host -ForegroundColor Red "OSDCloud $OSDVersion loaded. Required OSDCloud module version: $OSDRequiredVersion"
    Write-Host -ForegroundColor Red "Incorrect Module version loaded! Stopping OSD Cloud!"
    read-host "Press Enter to shut down the Computer."
    Stop-Computer  
}
else {
    Write-Host -ForegroundColor Green "OSDCloud $OSDVersion Ready"
}
Write-Host -ForegroundColor DarkGray "========================================================================="
Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))" -NoNewline; Write-Host -ForegroundColor Cyan ' Script details'
Write-Host -ForegroundColor DarkGray "Script version 3.0"
Write-host -ForegroundColor DarkGray "Going to install: Windows 11 23H2 x64 Pro NL-nl"
Write-Host -ForegroundColor DarkGray "========================================================================="

############################################################################################################################################################################
#Script content
############################################################################################################################################################################
Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))" -NoNewline; Write-Host -ForegroundColor Cyan ' Customer content script'
Write-host -ForegroundColor DarkGray 'Creating Customer script content'
$ScriptContent = @'
$filepath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs"
if (Test-Path $filepath) {
    Write-Output "$filepath is here, continue the script."
}
else {
    Write-Output "$filepath is not here, creating the location."
    New-Item -ItemType Directory -Force -Path $filepath
}
Start-Transcript -path "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Start-CustomerConfig.log" -append

Write-output "========================================================================="
Write-output "Starting Windows Update Driver"
Start-WindowsUpdateDriver
Write-output "Done"

#Move folders
Write-Output "========================================================================="
$source1 = 'C:\OSDCloud'
$destination = 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSDCloud'

if (Test-Path $source1 -PathType Container) {
    Write-Output "Copy $source1 to $destination"
    Copy-Item -Path $source1 -Destination $destination -Recurse -Force
    Remove-Item -Path $source1 -Recurse -Force -ErrorAction SilentlyContinue
} else {
    Write-Output "$source1 does not exist."
}

Start-Sleep -Seconds 5

Write-Output "========================================================================="
$source2 = 'C:\hp'

if (Test-Path $source2 -PathType Container) {
    Write-Output "Copy $source2 to $destination"
    Copy-Item -Path $source2 -Destination $destination -Recurse -Force
    Remove-Item -Path $source2 -Recurse -Force -ErrorAction SilentlyContinue
} else {
    Write-Output "$source2 does not exist."
}

Start-Sleep -Seconds 5

Write-Output "========================================================================="
$source3 = 'C:\system.sav'

if (Test-Path $source3 -PathType Container) {
    Write-Output "Copy $source3 to $destination"
    Copy-Item -Path $source3 -Destination $destination -Recurse -Force
    Remove-Item -Path $source3 -Recurse -Force -ErrorAction SilentlyContinue
} else {
    Write-Output "$source3 does not exist."
}

Start-Sleep -Seconds 5
Write-Output "========================================================================="

Write-Output 'Going to remove script.'
Stop-Transcript
Remove-Item -Path $MyInvocation.MyCommand.Source
'@
Write-host -ForegroundColor DarkGray 'Done creating Customer script content'
############################################################################################################################################################################
#Customer settings
############################################################################################################################################################################
$WIMVersions = "Windows_11_23H2(_NL_)X64_PRO"
$BlobURL = "https://occwsendpointmanager.blob.core.windows.net/iso?sp=rl&st=2023-04-24T16:19:40Z&se=2070-04-25T00:19:40Z&spr=https&sv=2021-12-02&sr=c&sig=MnCkunNdQnXaUHfA5UlHTraHvflavnys25MrWlwLueY%3D"
$ScriptsPath = "C:\Windows\Setup\scripts"

############################################################################################################################################################################
#All Functions
############################################################################################################################################################################
Function downloadFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [string]$Path
    )
    
    function convertFileSize {
        param(
            $bytes
        )
    
        if ($bytes -lt 1MB) {
            return "$([Math]::Round($bytes / 1KB, 2)) KB"
        }
        elseif ($bytes -lt 1GB) {
            return "$([Math]::Round($bytes / 1MB, 2)) MB"
        }
        elseif ($bytes -lt 1TB) {
            return "$([Math]::Round($bytes / 1GB, 2)) GB"
        }
    }
    
    Write-Verbose "URL set to ""$($Url)""."
    
    if (!($Path)) {
        Write-Verbose "Path parameter not set, parsing Url for filename."
        $URLParser = $Url | Select-String -Pattern ".*\:\/\/.*\/(.*\.{1}\w*).*" -List
    
        $Path = "./$($URLParser.Matches.Groups[1].Value)"
    }
    
    Write-Verbose "Path set to ""$($Path)""."
    
    #Load in the WebClient object.
    Write-Verbose "Loading in WebClient object."
    try {
        $Downloader = New-Object -TypeName System.Net.WebClient
    }
    catch [Exception] {
        Write-Error $_ -ErrorAction Stop
    }
       
    try {
    
        #Start the download by using WebClient.DownloadFileTaskAsync, since this lets us show progress on screen.
        Write-Verbose "Starting download..."
        $FileDownload = $Downloader.DownloadFileTaskAsync($Url, $Path)
    
        #Register the event from WebClient.DownloadProgressChanged to monitor download progress.
        Write-Verbose "Registering the ""DownloadProgressChanged"" event handle from the WebClient object."
        Register-ObjectEvent -InputObject $Downloader -EventName DownloadProgressChanged -SourceIdentifier WebClient.DownloadProgressChanged | Out-Null
    
        #Wait two seconds for the registration to fully complete
        Start-Sleep -Seconds 3
    
        if ($FileDownload.IsFaulted) {
            Write-Verbose "An error occurred. Generating error."
            Write-Error $FileDownload.GetAwaiter().GetResult()
            break
        }
    
        #While the download is showing as not complete, we keep looping to get event data.
        while (!($FileDownload.IsCompleted)) {
    
            if ($FileDownload.IsFaulted) {
                Write-Verbose "An error occurred. Generating error."
                Write-Error $FileDownload.GetAwaiter().GetResult()
                break
            }
    
            $EventData = Get-Event -SourceIdentifier WebClient.DownloadProgressChanged | Select-Object -ExpandProperty "SourceEventArgs" -Last 1
    
            $ReceivedData = ($EventData | Select-Object -ExpandProperty "BytesReceived")
            $TotalToReceive = ($EventData | Select-Object -ExpandProperty "TotalBytesToReceive")
            $TotalPercent = $EventData | Select-Object -ExpandProperty "ProgressPercentage"
    
            Write-Progress -Activity "Downloading File From Conclusion storage Blob" -Status "Percent Complete: $($TotalPercent)%" -CurrentOperation "Downloaded $(convertFileSize -bytes $ReceivedData) / $(convertFileSize -bytes $TotalToReceive)" -PercentComplete $TotalPercent
        }
    }
    catch [Exception] {
        $ErrorDetails = $_
    
        switch ($ErrorDetails.FullyQualifiedErrorId) {
            "ArgumentNullException" { 
                Write-Error -Exception "ArgumentNullException" -ErrorId "ArgumentNullException" -Message "Either the Url or Path is null." -Category InvalidArgument -TargetObject $Downloader -ErrorAction Stop
            }
            "WebException" {
                Write-Error -Exception "WebException" -ErrorId "WebException" -Message "An error occurred while downloading the resource." -Category OperationTimeout -TargetObject $Downloader -ErrorAction Stop
            }
            "InvalidOperationException" {
                Write-Error -Exception "InvalidOperationException" -ErrorId "InvalidOperationException" -Message "The file at ""$($Path)"" is in use by another process." -Category WriteError -TargetObject $Path -ErrorAction Stop
            }
            Default {
                Write-Error $ErrorDetails -ErrorAction Stop
            }
        }
    }
    finally {
        #Cleanup tasks
        Write-Verbose "Cleaning up..."
        Write-Progress -Activity "Downloading File" -Completed
        Unregister-Event -SourceIdentifier WebClient.DownloadProgressChanged    
        $Downloader.Dispose()
    }
}
Function Get-StorageBlobItems {
    param (
        $URL
    )
  
    if ($Null -eq $Script:BlobFiles) {
        $uri = $URL.split('?')[0]
        $sas = $URL.split('?')[1]
        
        $newurl = $uri + "?restype=container&comp=list&" + $sas 
        
        #Invoke REST API
        $body = Invoke-RestMethod -uri $newurl
  
        #cleanup answer and convert body to XML. Skip first few bytes (UTF8 BOM)
        $xml = [xml]$body.Substring($body.IndexOf('<'))
  
        $Script:BlobFiles = $xml.ChildNodes.Blobs.Blob
    }
    Return $Script:BlobFiles
}

Function Get-BlobItems {
    param (
        $URL
    )
  
    $Files = Get-StorageBlobItems -URL $URL | Where-Object { $_.Name -match $WIMVersions }

    ForEach ($File in $Files) {
        [PSCustomObject][Ordered]@{
            'Name' = $File.Name
            'Hash' = [System.Convert]::FromBase64String($File.Properties.'Content-MD5')
        }
    }
}

function Block-FurtherSteps {
    param (
        [string]$PromptText = "Stop computer and fix issues"
    )

    # Initialize response variable
    $response = ''

    # Loop until the user enters 'Y' or 'N'
    do {
        # Prompt the user for confirmation to restart the computer
        $response = Read-Host "$PromptText (Press: Y)"
    } until ($response -eq 'Y' -or $response -eq 'y')

    # Check if the user entered 'Y' or 'y'
    if ($response -eq 'Y' -or $response -eq 'y') {
        # Restart the computer
        Stop-Computer -Force
        Write-Host 'Y'
    }
}
############################################################################################################################################################################
Write-Host -ForegroundColor DarkGray "========================================================================="
Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))" -NoNewline; Write-Host -ForegroundColor Cyan ' Checking if we have the latest WIM file on our USB!'
$Drive = Get-Volume | where-object { ($_.FileSystemLabel -eq 'OSDCloudUSB' -and $_.DriveType -eq 'Removable' -and $_.FileSystemType -eq 'NTFS' -and $_.OperationalStatus -eq 'OK' ) }

$uri = $BlobURL.split('?')[0]
$sas = $BlobURL.split('?')[1]
$Script:BlobFiles = $null

#Check if USB Drive is detected
if ($Drive) {
    Write-Verbose "USB drive for WIM Files detected"
}
else {
    Write-host -ForegroundColor red "No USB drive detected! Cannot download WIM File going to exit!"
    Write-host -ForegroundColor red "Try another USB Port!"
    start-sleep 60
    exit
}

# Check if $Windir exist, if it's not, it will create the folder.
$WIMDir = "$($Drive.DriveLetter):\OSDCloud\OS"
if (test-path -Path $WIMDir) {
    Write-Verbose "$WIMDir exists"
}
else {
    $CreateFolder = New-Item -ItemType Directory -Path $WIMdir -Force
    Write-Verbose $CreateFolder
}

$BlobItems = Get-BlobItems -URL $BlobURL
# Collects HASH values of local WIM files in $results
$LocalFiles = New-Object System.Collections.ArrayList
$WimFiles = Find-OSDCloudFile -Name '*.wim' -Path '\OSDCloud\OS\' | Where-Object { ($_.Length -gt 3GB) -and ($_.versioninfo.Filename -notmatch 'C:' ) } | Sort-Object FullName | Sort-Object -Property Length -Unique
Foreach ($WimFile in $WimFiles) {
    $Null = $LocalFiles.add([PSCustomObject]@{
            Name = $WimFile.Name
            Hash = [byte[]]((Get-FileHash -path $WimFile.fullname -Algorithm MD5).Hash -replace '..', '0x$& ').TrimEnd().Split(' ')
        })
}

$Comparison = Compare-Object $BlobItems $LocalFiles -Property Hash -PassThru | Where-Object { $_.SideIndicator -eq '<=' }
if ($null -ne $Comparison) {
    foreach ($item in $Comparison) {
        #Items to copy were found
        Write-Host -ForegroundColor DarkGray "Older version of WIM detected!"
        Write-Host -ForegroundColor DarkGray "$($item.name) will be downloaded to $WIMDir" 
        $DownloadThisFile = $BlobItems.name | Where-Object { $_ -eq $($item.Name) }
        $downloadFileURL = "$uri" + "/" + $DownloadThisFile + "?" + "$sas"   
        
        $item.name = $item.Name.Replace('/', '\')
        $folders = $item.Name.replace('\install.wim', '')
        #Check if folder exist
        if (!(test-path "$wimdir\$folders")) {
            Write-Host  -ForegroundColor DarkGray "Creating Folder For WIM File"
            $FolderCreate = New-Item -ItemType Directory -Path "$wimdir\$folders" -Force
            Write-Verbose $FolderCreate        
        }
        else {
            Write-host -ForegroundColor DarkGray "Folder WIM File already exist"
        }
    
        Write-host -ForegroundColor DarkGray "Going to download WIM"
        DownloadFile $downloadFileURL "$WIMDir\$($item.name)"
    }
}
else {

    Write-host -ForegroundColor DarkGray "We have the latest version of the WIM file! Lets start the installation"

}

############################################################################################################################################################################
#All OSDCLOUD Magic
############################################################################################################################################################################
$Results = Find-OSDCloudFile -Name '*.wim' -Path '\OSDCloud\OS\Windows11\Windows_11_23H2_NL_X64_PRO' 
$Results = $Results | Sort-Object -Property Length -Unique | Sort-Object FullName | Where-Object { $_.Length -gt 3GB }

#OSDCloud parameters
$Global:MyOSDCloud = [ordered]@{
    LaunchMethod                = $Null
    AutomateAutopilot           = $null
    AutomateProvisioning        = $null
    AutomateShutdownScript      = $null
    AutomateStartupScript       = $null
    AutopilotJsonChildItem      = $null
    AutopilotJsonItem           = $null
    AutopilotJsonName           = $null
    AutopilotJsonObject         = $null
    AutopilotJsonString         = $null
    AutopilotJsonUrl            = $null
    AutopilotOOBEJsonChildItem  = $null
    AutopilotOOBEJsonItem       = $null
    AutopilotOOBEJsonName       = $null
    AutopilotOOBEJsonObject     = $null
    AzContext                   = $Global:AzContext
    AzOSDCloudBlobAutopilotFile = $Global:AzOSDCloudBlobAutopilotFile
    AzOSDCloudBlobDriverPack    = $Global:AzOSDCloudBlobDriverPack
    AzOSDCloudBlobImage         = $Global:AzOSDCloudBlobImage
    AzOSDCloudBlobPackage       = $Global:AzOSDCloudBlobPackage
    AzOSDCloudBlobScript        = $Global:AzOSDCloudBlobScript
    AzOSDCloudAutopilotFile     = $Global:AzOSDCloudAutopilotFile
    AzOSDCloudDriverPack        = $null
    AzOSDCloudImage             = $Global:AzOSDCloudImage
    AzOSDCloudPackage           = $null
    AzOSDCloudScript            = $null
    AzStorageAccounts           = $Global:AzStorageAccounts
    AzStorageContext            = $Global:AzStorageContext
    BuildName                   = 'OSDCloud'
    ClearDiskConfirm            = [bool]$true
    Debug                       = $false
    DownloadDirectory           = $null
    DownloadName                = $null
    DownloadFullName            = $null
    DevMode                     = $true
    SetTimeZone                 = $true
    DriverPack                  = $null
    DriverPackBaseName          = $null
    DriverPackExpand            = [bool]$false
    DriverPackName              = $null
    DriverPackOffline           = $null
    DriverPackSource            = $null
    DriverPackUrl               = $null
    ExpandWindowsImage          = $null
    Function                    = $MyInvocation.MyCommand.Name
    GetDiskFixed                = $null
    GetFeatureUpdate            = $null
    GetMyDriverPack             = $null
    HPIADrivers                 = $null
    HPIAFirmware                = $null
    HPIASoftware                = $null
    HPTPMUpdate                 = $null
    HPBIOSUpdate                = $null
    ImageFileFullName           = $null
    ImageFileItem               = $Results
    ImageFileName               = $null
    ImageFileSource             = $null
    ImageFileDestination        = $null
    ImageFileUrl                = $null
    IsOnBattery                 = $(Get-OSDGather -Property IsOnBattery)
    IsTest                      = ($env:SystemDrive -ne 'X:')
    IsVirtualMachine            = $(Test-IsVM)
    IsWinPE                     = ($env:SystemDrive -eq 'X:')
    IsoMountDiskImage           = $null
    IsoGetDiskImage             = $null
    IsoGetVolume                = $null
    Logs                        = "$env:SystemDrive\OSDCloud\Logs"
    Manufacturer                = Get-MyComputerManufacturer -Brief
    MSCatalogFirmware           = $true
    MSCatalogDiskDrivers        = $true
    MSCatalogNetDrivers         = $true
    MSCatalogScsiDrivers        = $true
    OOBEDeployJsonChildItem     = $null
    OOBEDeployJsonItem          = $null
    OOBEDeployJsonName          = $null
    OOBEDeployJsonObject        = $null
    ODTConfigFile               = 'C:\OSDCloud\ODT\Config.xml'
    ODTFile                     = $null
    ODTFiles                    = $null
    ODTSetupFile                = $null
    ODTSource                   = $null
    ODTTarget                   = 'C:\OSDCloud\ODT'
    ODTTargetData               = 'C:\OSDCloud\ODT\Office'
    OperatingSystems            = [array](Get-OSDCloudOperatingSystems)
    OSActivation                = $null
    OSBuild                     = $null
    OSBuildMenu                 = $null
    OSBuildNames                = $null
    OSEdition                   = 'Pro'
    OSEditionId                 = 'Professional'
    OSEditionMenu               = $null
    OSEditionValues             = $null
    OSImageIndex                = 1
    OSLanguage                  = $null
    OSLanguageMenu              = $null
    OSLanguageNames             = $null
    OSVersion                   = 'Windows 11'
    Product                     = Get-MyComputerProduct
    Restart                     = [bool]$false
    ScreenshotCapture           = $false
    ScreenshotPath              = "$env:TEMP\Screenshots"
    ScriptStartup               = $null
    ScriptShutdown              = $null
    SetWiFi                     = $null
    Shutdown                    = [bool]$false
    ShutdownSetupComplete       = [bool]$false
    SkipAllDiskSteps            = [bool]$false
    SkipAutopilot               = [bool]$false
    SkipAutopilotOOBE           = [bool]$false
    SkipClearDisk               = [bool]$false
    SkipODT                     = [bool]$false
    SkipOOBEDeploy              = [bool]$false
    SkipNewOSDisk               = [bool]$false
    SkipRecoveryPartition       = [bool]$false
    SplashScreen                = [bool]$false
    SyncMSUpCatDriverUSB        = [bool]$false
    RecoveryPartition           = $null
    TimeEnd                     = $null
    TimeSpan                    = $null
    TimeStart                   = [datetime](Get-Date)
    Transcript                  = $null
    USBPartitions               = $null
    Version                     = [Version](Get-Module -Name OSD -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).Version
    WindowsDefenderUpdate       = $true
    WindowsUpdate               = $true
    WindowsUpdateDrivers        = $true
    WindowsImage                = $null
    WindowsImageCount           = $null
    ZTI                         = [bool]$true
}

#Only for HP devices we make use of HPIA
if ($Manufacturer -eq 'HP') {
    $Global:MyOSDCloud.HPIADrivers = $true
    $Global:MyOSDCloud.HPIAFirmware = $true 
    $Global:MyOSDCloud.HPTPMUpdate = $false
    $Global:MyOSDCloud.HPBIOSUpdate = $true
    $Global:MyOSDCloud.DriverPackName = 'None'
}

Write-Host -ForegroundColor DarkGray "========================================================================="
#Start OSDCloud ZTI the RIGHT way
Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))" -NoNewline; Write-Host -ForegroundColor Cyan ' Start OSDCloud with Conclusion Parameters'
Invoke-OSDCloud
Write-Host -ForegroundColor DarkGray "========================================================================="
#Removing items
Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))" -NoNewline; Write-Host -ForegroundColor Cyan ' Removing .WIM file in C:\OSDCloud\os'
Get-ChildItem -Path 'C:\OSDCloud\OS\' -Include * | remove-Item -recurse 
Write-Host -ForegroundColor DarkGray "========================================================================="
############################################################################################################################################################################
#
############################################################################################################################################################################
Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))" -NoNewline; Write-Host -ForegroundColor Cyan ' Create Start-CustomerConfig script'
Write-host -ForegroundColor DarkGray "Creating script for Customer Config"
Out-File -FilePath $(Join-Path $ScriptsPath \Start-CustomerConfig.ps1) -Encoding Unicode -Force -InputObject $ScriptContent -Confirm:$False
Write-host -ForegroundColor DarkGray "Done!"

############################################################################################################################################################################
#
############################################################################################################################################################################
# Define the path to your PowerShell script
$ScriptFile = "$ScriptsPath\SetupComplete.ps1"

# Read the content of the script as an array of strings
$scriptContent = Get-Content $ScriptFile

# Remove the line containing the "Start-Transcript" command
$lineToRemove = 'Start-Transcript -Path ''C:\OSDCloud\Logs\SetupComplete.log'' -ErrorAction Ignore'
$indexToRemove = $scriptContent.IndexOf($lineToRemove)

if ($indexToRemove -ne -1) {
    # Remove the line
    $scriptContent = $scriptContent -ne $scriptContent[$indexToRemove]
}

# Locate the lines where extra content needs to be inserted
$indexLine1 = $scriptContent.IndexOf('$ModulePath = (Get-ChildItem -Path "$($Env:ProgramFiles)\WindowsPowerShell\Modules\osd" | Where-Object {$_.Attributes -match "Directory"} | select -Last 1).fullname')
$indexLine2 = $scriptContent.IndexOf("Restart-Computer -Force")
$indexLine3 = $scriptContent.IndexOf("Start-WindowsUpdateDriver")

# Define the additional context to be added
$extraContext1 = @(
    'Start-Transcript -Path "C:\OSDCloud\Logs\SetupComplete.log" -ErrorAction Ignore',
    '$Counter = 0',
    'Write-Output "Checking Network Connection"',
    'do {',
    '    $null = pnputil.exe /scan-devices',
    '    Start-Sleep -Seconds 10',
    '    $TestConnection = Test-WebConnection',
    '    if ($TestConnection) {',
    '        Write-Output "Network Connection Established"',
    '    }',
    '    else {',
    '        $Counter++',
    '        switch ($Counter) {',
    '            5 { Write-Output "No Network Connection"; ipconfig /all; Get-WmiObject -Class win32_networkadapter }',
    '            10 { Write-Output "No Network Connection"; ipconfig /all; Get-WmiObject -Class win32_networkadapter }',
    '            15 { Write-Output "No Network Connection"; ipconfig /all; Get-WmiObject -Class win32_networkadapter }',
    '            20 { Write-Output "No Network Connection"; ipconfig /all; Get-WmiObject -Class win32_networkadapter }',
    '        }',
    '    }',
    '} until (($TestConnection -eq $true) -or ($Counter -eq 20))',
    '# Stop OSD Cloud if no connection was established after 5 attempts',
    'if ((-NOT($TestConnection -eq $true)) -or ($Counter -eq 20)) {',
    '    Write-Output "No Network Connection! Stopping OSD Cloud!"',
    '    Stop-Transcript',
    '    Stop-Computer',
    '}'
)

$extraContext2 = @(
    'Write-Output "Running Start-CustomerConfig | Time: $($(Get-Date).ToString("hh:mm:ss"))"',
    '& "C:\Windows\Setup\scripts\Start-CustomerConfig.ps1"',
    'Write-Output "Completed Section [Start-CustomerConfig] | Time: $($(Get-Date).ToString("hh:mm:ss"))"',
    'Write-Output "-------------------------------------------------------------"'
)

$extraContext3 = @(
    'Start-Sleep -Seconds 10',
    'Write-Output "Waiting for network initialization..."',
    '$timeout = 0',
    'while ($timeout -lt 20) {',
    '    Start-Sleep -Seconds $timeout',
    '    $timeout += 5',
    '    $IP = Test-Connection -ComputerName $(hostname) -Count 1 | Select-Object -ExpandProperty IPV4Address',
    '    if (-not $IP) {',
    '        Write-output "Network adapter error!"',
    '    } elseif ($IP.IPAddressToString.StartsWith("169.254") -or $IP.IPAddressToString.Equals("127.0.0.1")) {',
    '        Write-output  "IP not assigned by DHCP. Renewing DHCP lease..."',
    '        ipconfig /release | Out-Null',
    '        ipconfig /renew | Out-Null',
    '    } else {',
    '        Write-output "Network configured with IP: $($IP.IPAddressToString)"',
    '        break',
    '    }',
    '}'
)
# Insert extra context1 before the first specific line
$scriptContent = $scriptContent[0..($indexLine1 - 1)] + $extraContext1 + $scriptContent[$indexLine1..($scriptContent.Length - 1)]

# Recalculate $indexLine2 and $indexLine3 after insertion of $extraContext1
$indexLine2 = $scriptContent.IndexOf("Restart-Computer -Force")
$indexLine3 = $scriptContent.IndexOf("Start-WindowsUpdateDriver")

# Insert extra context2 before the second specific line
$scriptContent = $scriptContent[0..($indexLine2 - 1)] + $extraContext2 + $scriptContent[$indexLine2..($scriptContent.Length - 1)]

# Recalculate $indexLine3 after insertion of $extraContext2
$indexLine3 = $scriptContent.IndexOf("Start-WindowsUpdateDriver")

# Insert extra context3 **after** the "Start-WindowsUpdateDriver" line
$scriptContent = $scriptContent[0..$indexLine3] + $extraContext3 + $scriptContent[($indexLine3 + 1)..($scriptContent.Length - 1)]

# Write the modified script content back to the file
$scriptContent | Out-File $ScriptFile -Force

############################################################################################################################################################################
#
############################################################################################################################################################################
#Stop transcripts
Write-Host -ForegroundColor DarkGray "========================================================================="
Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))" -NoNewline; Write-Host -ForegroundColor Cyan ' Stop all transcripts'
$Driveletter = (Get-Volume | where-object { ($_.FileSystemLabel -eq 'OSDCloudUSB' -and $_.DriveType -eq 'Removable' -and $_.FileSystemType -eq 'NTFS' -and $_.OperationalStatus -eq 'OK' ) }).driveletter
Write-host -ForegroundColor DarkGray "Move:"$($driveletter):\logs\$transcript" to: C:\OSDCloud\Logs"
Stop-Transcript
Stop-Transcript
Move-Item "$($driveletter):\logs\$transcript" -Destination 'C:\OSDCloud\Logs' -force
Write-Host -ForegroundColor DarkGray "========================================================================="

#Restarting device after its done.
Write-Warning "Device is ready to go!"
Write-Warning "Press CTRL + C to cancel, you have 10 seconds!"
Start-Sleep -Seconds 10
Write-Host -ForegroundColor DarkGray "========================================================================="
Restart-Computer

############################################################################################################################################################################
#All Done
############################################################################################################################################################################