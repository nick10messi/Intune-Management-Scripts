<#
.SYNOPSIS
This script connects to Microsoft Graph and automates the process of syncing users to an device group based on intune devices.

.DESCRIPTION
1. Connects to Microsoft Graph using the `Connect-MgGraph` cmdlet.
2. Retrieves members of the specified user and device groups and gathers managed Windows devices from Intune.
3. Processes users from the specified user group, checking for exclusions.
4. Processes devices based on the users, retrieving device details from Intune.
5. Compares the current device group membership with the list of devices and updates the group accordingly:
   - Adds missing devices.
   - Removes devices that should no longer be in the group.
   - Skips devices that are already correctly in the group.
6. Outputs detailed information about added, removed, excluded, or skipped users and devices.

.PARAMETER UserGroupDisplayName
The display name of the user group to process.

.PARAMETER DeviceGroupDisplayName
The display name of the device group to update.

.PARAMETER GroupsToExclude
(Optional) An array of group names whose members should be excluded from the operation.

.EXAMPLE
Set-UserToDevicesGroups -UserGroupDisplayName 'All Users' -DeviceGroupDisplayName 'CWS-Windows_Personal_Autopatch_Production_Devices' -GroupsToExclude @('CWS-Windows_Personal_Autopatch_Pilot_Users', 'CWS-Windows_Personal_Autopatch_First_Users')

This command updates the membership of the `CWS-Windows_Personal_Autopatch_Production_Devices` group based on the users in the `All Users` group, excluding members of the specified excluded groups.
#>

#modules
#Requires -modules  @{ ModuleName="Microsoft.Graph.Authentication"; RequiredVersion="2.24.0"},@{ ModuleName="Microsoft.Graph.Groups"; RequiredVersion="2.24.0"},@{ ModuleName="Microsoft.Graph.DeviceManagement"; RequiredVersion="2.24.0"},@{ ModuleName="Microsoft.Graph.Users"; RequiredVersion="2.24.0"},@{ ModuleName="Microsoft.Graph.Identity.DirectoryManagement"; RequiredVersion="2.24.0"},@{ ModuleName="Microsoft.Graph.Beta.DeviceManagement"; RequiredVersion="2.24.0"}


# Connect to Microsoft Graph
try {
    Connect-MgGraph -Identity -ContextScope Process -ErrorAction Stop
    Write-Output "INFO: Connected to Microsoft Graph."
}
catch {
    Write-Output "ERROR: Failed to connect to Microsoft Graph: $_"
    return
}

function Set-UserToDevicesGroups {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserGroupDisplayName,

        [Parameter(Mandatory = $true)]
        [string]$DeviceGroupDisplayName,

        [Parameter(Mandatory = $false)]
        [array]$GroupsToExclude
    )

    # Gather data
    try {
        Write-Output "INFO: Gathering all data to run this smoothly..."
        
        # Haal gebruikersgroep op
        $usergroup = Get-MgGroup -Filter "DisplayName eq '$UserGroupDisplayName'"
        if ($usergroup) {
            $UserGroupMembers = Get-MgGroupMember -GroupId $usergroup.Id -All
        }
        else {
            throw "ERROR: No group found with the name '$UserGroupDisplayName'. Exiting."
        }
    
        # Haal apparaatgroep op
        $devicegroup = Get-MgGroup -Filter "DisplayName eq '$DeviceGroupDisplayName'"
        if ($devicegroup) {
            $alldevices = Get-MgGroupMember -GroupId $devicegroup.Id -All
        }
        else {
            throw "ERROR: No group found with the name '$DeviceGroupDisplayName'. Exiting."
        }
    
        # Haal alle Intune-apparaten op
        $allIntuneDevices = Get-MgDeviceManagementManagedDevice -Filter "OperatingSystem eq 'Windows'" -All
        # Haal apparaatgroep op
        if ($allIntuneDevices) {

            # Maak een lege hashtable voor de apparaten
            $IntuneDeviceLookup = @{}
    
            # Vul de hashtables met Id, DeviceId en UserPrincipalName
            foreach ($Device in $allIntuneDevices) {
                # Opslaan op basis van Id
                if ($Device.Id) {
                    $IntuneDeviceLookup[$Device.Id] = $Device
                }
    
                # Opslaan op basis van DeviceId
                if ($Device.AzureAdDeviceId) {
                    $IntuneDeviceLookup[$Device.AzureAdDeviceId] = $Device
                }
    
                # Opslaan op basis van DeviceId
                if ($Device.UserPrincipalName) {
                    $IntuneDeviceLookup[$Device.UserPrincipalName] = $Device
                }
    
            }
        }
        else {
            throw "ERROR: No group found with the name '$allIntuneDevices'. Exiting."
        }

        $AllEntraIDDevices = Get-MgDevice -All
        if ($AllEntraIDDevices) {
            $DeviceLookup = @{}
            ForEach ($Device in $AllEntraIDDevices) {
                if ($Device.DeviceId) {
                    $DeviceLookup[$Device.DeviceId] = $Device
                }
                
                if ($Device.Id) {
                    $DeviceLookup[$Device.Id] = $Device
                }
    
            }
        }
        else {
            throw "ERROR: No group found with the name '$AllEntraIDDevices'. Exiting."
        }
    }
    catch {
        Write-Output "ERROR: Failed to gather data: $_"
        return
    }
    

    # Process user objects
    $ObjectIdUsers = New-Object System.Collections.ArrayList
    foreach ($Member in $UserGroupMembers) {
        try {
            if ($Member.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.user') {
                if ($GroupsToExclude) {
                    # Check if user is a member of any excluded groups
                    $userGroups = Get-MgUserMemberOf -UserId $Member.id -All -ExpandProperty *
                    # Check if nested user is a member of any excluded groups
                    $isExcluded = $userGroups | Where-Object { $_.AdditionalProperties.displayName -in $GroupsToExclude }

                    if ($isExcluded) {
                        $excludedGroups = ($isExcluded.AdditionalProperties.displayName -split ',') -join ', '
                        Write-Output "EXCLUDED: $($Member.AdditionalProperties.displayName) - $excludedGroups."
                        continue
                    }
                }

                $null = $ObjectIdUsers.Add([PSCustomObject][ordered]@{
                        Name     = $Member.AdditionalProperties.displayName
                        UPN      = $Member.AdditionalProperties.userPrincipalName
                        ObjectId = $Member.Id
                    })
            }
            elseif ($Member.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.group') {
                $NestedGroup = Get-MgGroupMember -GroupId $Member.Id -All
                foreach ($NestedGroupObjectID in $NestedGroup) {
                    if ($NestedGroupObjectID.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.user') {
                        if ($GroupsToExclude) {
                            # Get groups the nested user is a member of
                            $nestedUserGroups = Get-MgUserMemberOf -UserId $Member.id -All -ExpandProperty *
                            # Check if nested user is a member of any excluded groups
                            $isExcluded = $nestedUserGroups | Where-Object { $_.AdditionalProperties.displayName -in $GroupsToExclude }
    
                            if ($isExcluded) {
                                $excludedGroups = ($isExcluded | ForEach-Object { $_.AdditionalProperties.displayName }) -join ', '
                                Write-Output "EXCLUDED: $($NestedMember.AdditionalProperties.displayName) - $excludedGroups."
                                continue
                            }
                        }

                        $null = $ObjectIdUsers.Add([PSCustomObject][ordered]@{
                                Name     = $NestedGroupObjectID.AdditionalProperties.displayName
                                UPN      = $NestedGroupObjectID.AdditionalProperties.userPrincipalName
                                ObjectId = $NestedGroupObjectID.Id
                            })
                    }
                }
            }
        }
        catch {
            Write-Output "ERROR: Failed to process user or nested group: $_"
        }
    }

    # Process device objects
    $ObjectIdDevice = New-Object System.Collections.ArrayList
    foreach ($ObjectIdUser in $ObjectIdUsers) {
        try {
            $DeviceInfo = $IntuneDeviceLookup[$ObjectIdUser.UPN]
            if ($DeviceInfo) {
                foreach ($Device in $DeviceInfo) {
                    $DeviceID = $DeviceLookup[$($DeviceInfo.AzureAdDeviceId)]
                    #$DeviceID = Get-MgDevice -Filter "deviceId eq '$($Device.AzureAdDeviceId)'"
                    if ($DeviceID) {
                        $null = $ObjectIdDevice.add([PSCustomObject][ordered]@{
                                Name       = $ObjectIdUser.Name
                                DeviceID   = $DeviceID.Id
                                DeviceName = $DeviceID.DisplayName
                            })
                    }
                }
            }
            else {
                Write-Output "WARNING: No device for user $($ObjectIdUser.Name). Cannot add to the group."
            }
        }
        catch {
            Write-Output "ERROR: Failed to process devices for user $($ObjectIdUser.Name). $_"
        }
    }

    # Compare and update group memberships
    $DeviceIdComparison = Compare-Object -ReferenceObject @($alldevices.Id | Select-Object -Unique) -DifferenceObject @($ObjectIdDevice.DeviceID | Select-Object -Unique) -IncludeEqual
    ForEach ($Comparison in $DeviceIdComparison) {
        $DeviceName = ($DeviceLookup[$($Comparison.InputObject)]).DisplayName

        Switch ($Comparison.SideIndicator) {
            "<=" {
                $username = $IntuneDeviceLookup[$($GetIntuneDeviceID.DeviceId)].UserDisplayName
                Remove-MgGroupMemberByRef -GroupId $devicegroup.Id -DirectoryObjectId $Comparison.InputObject
                Write-Output "REMOVING: $username - $DeviceName - from - $($devicegroup.DisplayName) "
            }
            "=>" {
                $username = ($ObjectIdDevice | Where-Object { $_.DeviceID -eq $Comparison.InputObject }).Name
                New-MgGroupMember -GroupId $devicegroup.Id -DirectoryObjectId $Comparison.InputObject
                Write-Output "ADDING: $username - $DeviceName - to - $($devicegroup.DisplayName)"
            }
            "==" {
                $username = ($ObjectIdDevice | Where-Object { $_.DeviceID -eq $Comparison.InputObject }).Name
                Write-Output "Skipping: $username - $DeviceName - is already in - $($devicegroup.DisplayName)."
            }
        }
    }
    Write-Output '##############################################################################################################'
    
    $DeviceIdComparison | ForEach-Object {
        Switch ($_.SideIndicator) {
            '==' { Write-Output "Skipped: $($_.Count)" }
            '<=' { Write-Output "Removed: $($_.Count)" }
            '=>' { Write-Output "Added: $($_.Count)" }
        }
    }
    Write-Output '##############################################################################################################'
    Write-Output "INFO: All Done."
}


Set-UserToDevicesGroups -UserGroupDisplayName 'CWS-Windows_Personal_Autopatch_Pilot_Users' -DeviceGroupDisplayName 'CWS-Windows_Personal_Autopatch_Pilot_Devices' -GroupsToExclude @('CWS-Windows_Personal_Autopatch_First_Users')

Set-UserToDevicesGroups -UserGroupDisplayName 'CWS-Windows_Personal_Autopatch_First_Users' -DeviceGroupDisplayName 'CWS-Windows_Personal_Autopatch_First_Devices' -GroupsToExclude @('CWS-Windows_Personal_Autopatch_Pilot_Users')

Set-UserToDevicesGroups -UserGroupDisplayName 'Alle gebruikers' -DeviceGroupDisplayName 'CWS-Windows_Personal_Autopatch_Production_Devices' -GroupsToExclude @('CWS-Windows_Personal_Autopatch_Pilot_Users', 'CWS-Windows_Personal_Autopatch_First_Users')

# Disconnect from Microsoft Graph
Disconnect-MgGraph