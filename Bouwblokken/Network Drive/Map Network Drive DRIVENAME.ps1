###########################################################################################
# Input values from generator
###########################################################################################

$driveMappingJson = '[{"Path":"\\\\UNC\\Path\\$env:username","DriveLetter":"U","Label":"DisplayName_Explorer","Id":0,"GroupFilter":null}]'

$driveMappingConfig = $driveMappingJson | ConvertFrom-Json -ErrorAction Stop
#used to create an array for groups
$driveMappingConfig = foreach ($d in $driveMappingConfig) {
    [PSCustomObject]@{
        Path        = $($d.Path)
        DriveLetter = $($d.DriveLetter)
        Label       = $($d.Label)
        Id          = $($d.Id)
        GroupFilter = $($d.GroupFilter -split ",")
    }
}
$DriveLabel = $driveMappingConfig.Label 
# Override with your Active Directory Domain Name e.g. 'ds.nicolonsky.ch' if you haven't configured the domain name as DHCP option
$searchRoot = ""

# If enabled all mounted PSdrives from filesystem except os drives get disconnected if not specified in drivemapping config
$removeStaleDrives = $false

###########################################################################################
# Helper function to determine a users group membership
###########################################################################################

# Kudos for Tobias Renström who showed me this!
function Get-ADGroupMembership {
    param(
        [parameter(Mandatory = $true)]
        [string]$UserPrincipalName
    )

    process {

        try {

            if ([string]::IsNullOrEmpty($env:USERDNSDOMAIN) -and [string]::IsNullOrEmpty($searchRoot)) {
                Write-Error "Security group filtering won't work because `$env:USERDNSDOMAIN is not available!"
                Write-Warning "You can override your AD Domain in the `$overrideUserDnsDomain variable"
            }
            else {

                # if no domain specified fallback to PowerShell environment variable
                if ([string]::IsNullOrEmpty($searchRoot)) {
                    $searchRoot = $env:USERDNSDOMAIN
                }

                $searcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher
                $searcher.Filter = "(&(userprincipalname=$UserPrincipalName))"
                $searcher.SearchRoot = "LDAP://$searchRoot"
                $distinguishedName = $searcher.FindOne().Properties.distinguishedname
                $searcher.Filter = "(member:1.2.840.113556.1.4.1941:=$distinguishedName)"

                [void]$searcher.PropertiesToLoad.Add("name")

                $list = [System.Collections.Generic.List[String]]@()

                $results = $searcher.FindAll()

                foreach ($result in $results) {
                    $resultItem = $result.Properties
                    [void]$List.add($resultItem.name)
                }

                $list
            }
        }
        catch {
            #Nothing we can do
            Write-Warning $_.Exception.Message
        }
    }
}

#check if running as system
function Test-RunningAsSystem {
    [CmdletBinding()]
    param()
    process {
        return [bool]($(whoami -user) -match "S-1-5-18")
    }
}


#Testing if groupmembership is given for user
function Test-GroupMembership {
    [CmdletBinding()]
    param (
        $driveMappingConfig,
        $groupMemberships
    )
    try {
        $obj = foreach ($d in $driveMappingConfig) {
            if (-not ([string]::IsNullOrEmpty($($d.GroupFilter)))) {
                foreach ($filter in $($d.GroupFilter)) {
                    if ($groupMemberships -contains $filter) {
                        $d
                    }
                    else {
                        #no match for group
                    }
                }
            }
            else {
                $d 
            }
        }
        $obj
    }
    catch {
        Write-Error "Unknown error testing group memberships: $($_.Exception.Message)"
    }
}

###########################################################################################
# Get current group membership for the group filter capabilities
###########################################################################################

Write-Output "Running as SYSTEM: $(Test-RunningAsSystem)"

if ($driveMappingConfig.GroupFilter) {
    try {
        #check if running as user and not system
        if (-not (Test-RunningAsSystem)) {

            $groupMemberships = Get-ADGroupMembership -UserPrincipalName $(whoami -upn)
        }
    }
    catch {
        #nothing we can do
    }
}
###########################################################################################
# Mapping network drives
###########################################################################################
#Get PowerShell drives and rename properties

if (-not (Test-RunningAsSystem)) {

    $psDrives = Get-PSDrive | Where-Object { $_.Provider.Name -eq "FileSystem" -and $_.Root -notin @("$env:SystemDrive\", "D:\") } `
    | Select-Object @{N = "DriveLetter"; E = { $_.Name } }, @{N = "Path"; E = { $_.DisplayRoot } }

    # only map drives where group membership applicable
    $driveMappingConfig = Test-GroupMembership -driveMappingConfig $driveMappingConfig -groupMemberships $groupMemberships

    #iterate through all network drive configuration entries
    foreach ($drive in $driveMappingConfig) {

        try {
            #check if variable in unc path exists, e.g. for $env:USERNAME -> resolving
            if ($drive.Path -match '\$env:') {
                $drive.Path = $ExecutionContext.InvokeCommand.ExpandString($drive.Path)
            }

            #if label is null we need to set it to empty in order to avoid error
            if ($null -eq $drive.Label) {
                $drive.Label = ""
            }

            $exists = $psDrives | Where-Object { $_.Path -eq $drive.Path -or $_.DriveLetter -eq $drive.DriveLetter }
            $process = $true

            if ($null -ne $exists -and $($exists.Path -eq $drive.Path -and $exists.DriveLetter -eq $drive.DriveLetter )) {
                Write-Output "Drive '$($drive.DriveLetter):\' '$($drive.Path)' already exists with correct Drive Letter and Path"
                $process = $false

            }
            else {
                # Mapped with wrong config -> Delete it
                Get-PSDrive | Where-Object { $_.DisplayRoot -eq $drive.Path -or $_.Name -eq $drive.DriveLetter } | Remove-PSDrive -EA SilentlyContinue
            }

            if ($process) {
                Write-Output "Mapping network drive $($drive.Path)"
                $null = New-PSDrive -PSProvider FileSystem -Name $drive.DriveLetter -Root $drive.Path -Description $drive.Label -Persist -Scope global -EA Stop
                (New-Object -ComObject Shell.Application).NameSpace("$($drive.DriveLetter):").Self.Name = $drive.Label
            }
        }
        catch {
            $available = Test-Path $($drive.Path)
            if (-not $available) {
                Write-Error "Unable to access path '$($drive.Path)' verify permissions and authentication!"
            }
            else {
                Write-Error $_.Exception.Message
            }
        }
    }

    # Remove unassigned drives
    if ($removeStaleDrives -and $null -ne $psDrives) {
        $diff = Compare-Object -ReferenceObject $driveMappingConfig -DifferenceObject $psDrives -Property "DriveLetter" -PassThru | Where-Object { $_.SideIndicator -eq "=>" }
        foreach ($unassignedDrive in $diff) {
            Write-Warning "Drive '$($unassignedDrive.DriveLetter)' has not been assigned - removing it..."
            Remove-SmbMapping -LocalPath "$($unassignedDrive.DriveLetter):" -Force -UpdateProfile
        }
    }

    # Fix to ensure drives are mapped as persistent!
    $null = Get-ChildItem -Path HKCU:\Network -ErrorAction SilentlyContinue | ForEach-Object { New-ItemProperty -Name ConnectionType -Value 1 -Path $_.PSPath -Force -ErrorAction SilentlyContinue }
}

#!SCHTASKCOMESHERE!#

###########################################################################################
# If this script is running under system (IME) scheduled task is created  (recurring)
###########################################################################################

if (Test-RunningAsSystem) {
    Write-Output "Running as System --> creating scheduled task which will run on user logon"

    ###########################################################################################
    # Get the current script path and content and save it to the client
    ###########################################################################################

    $currentScript = Get-Content -Path $($PSCommandPath)

    $schtaskScript = $currentScript[(0) .. ($currentScript.IndexOf("#!SCHTASKCOMESHERE!#") - 1)]

    $scriptSavePath = $(Join-Path -Path $env:ProgramData -ChildPath "CustomScripts\Drive Mappings")

    if (-not (Test-Path $scriptSavePath)) {

        New-Item -ItemType Directory -Path $scriptSavePath -Force
    }

    $scriptSavePathName = "Drive Mapping - $DriveLabel.ps1"

    $scriptPath = $(Join-Path -Path $scriptSavePath -ChildPath $scriptSavePathName)

    $schtaskScript | Out-File -FilePath $scriptPath -Force

    ###########################################################################################
    # Create dummy vbscript to hide PowerShell Window popping up at logon
    ###########################################################################################

    $vbsDummyScript = "
    Dim shell,fso,file

    Set shell=CreateObject(`"WScript.Shell`")
    Set fso=CreateObject(`"Scripting.FileSystemObject`")

    strPath=WScript.Arguments.Item(0)

    If fso.FileExists(strPath) Then
        set file=fso.GetFile(strPath)
        strCMD=`"powershell -nologo -executionpolicy ByPass -command `" & Chr(34) & `"&{`" &_
        file.ShortPath & `"}`" & Chr(34)
        shell.Run strCMD,0
    End If
    "

    $scriptSavePathName = "EndpointDriveMapping-VBSHelper.vbs"

    $dummyScriptPath = $(Join-Path -Path $scriptSavePath -ChildPath $scriptSavePathName)

    $vbsDummyScript | Out-File -FilePath $dummyScriptPath -Force

    $wscriptPath = Join-Path $env:SystemRoot -ChildPath "System32\wscript.exe"

    ###########################################################################################
    # Register a scheduled task to run for all users and execute the script on logon
    ###########################################################################################

    $schtaskName = "Drive Mapping - $DriveLabel"
    $schtaskDescription = "Map network drive from Microsoft Intune"

    $trigger = New-ScheduledTaskTrigger -AtLogOn

    $class = cimclass MSFT_TaskEventTrigger root/Microsoft/Windows/TaskScheduler
    $trigger2 = $class | New-CimInstance -ClientOnly
    $trigger2.Enabled = $True
    $trigger2.Subscription = '<QueryList><Query Id="0" Path="Microsoft-Windows-NetworkProfile/Operational"><Select Path="Microsoft-Windows-NetworkProfile/Operational">*[System[Provider[@Name=''Microsoft-Windows-NetworkProfile''] and EventID=10002]]</Select></Query></QueryList>'

    $trigger3 = $class | New-CimInstance -ClientOnly
    $trigger3.Enabled = $True
    $trigger3.Subscription = '<QueryList><Query Id="0" Path="Microsoft-Windows-NetworkProfile/Operational"><Select Path="Microsoft-Windows-NetworkProfile/Operational">*[System[Provider[@Name=''Microsoft-Windows-NetworkProfile''] and EventID=4004]]</Select></Query></QueryList>'

    #Execute task in users context
    $principal= New-ScheduledTaskPrincipal -GroupId "S-1-5-32-545" -Id "Author"

    #call the vbscript helper and pass the PosH script as argument
    $action = New-ScheduledTaskAction -Execute $wscriptPath -Argument "`"$dummyScriptPath`" `"$scriptPath`""

    $settings= New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

    $null=Register-ScheduledTask -TaskName $schtaskName -Trigger $trigger,$trigger2,$trigger3 -Action $action  -Principal $principal -Settings $settings -Description $schtaskDescription -Force

    Start-ScheduledTask -TaskName $schtaskName
}