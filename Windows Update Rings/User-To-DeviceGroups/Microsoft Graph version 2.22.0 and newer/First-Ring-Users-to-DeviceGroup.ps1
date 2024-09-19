#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.DeviceManagement, Microsoft.Graph.Groups, Microsoft.Graph.Identity.DirectoryManagement
#
#DeviceManagementManagedDevices.Read.All, GroupMember.ReadWrite.All, User.Read.all, Directory.Read.All
#
# 2.0.0-preview2 version of Microsoft.Graph.Authentication module
#Connect-MgGraph -Identity

# previous versions of Microsoft.Graph.Authentication module
Connect-MgGraph -Identity 
Write-Host "Gathering all data to run this smooth."

$usergroup = Get-MgGroup -Filter "Displayname eq 'CWS-Windows_Personal_First'"
$allusers = Get-MgGroupMember -GroupId $usergroup.Id  -All
$devicegroup = Get-MgGroup -Filter "Displayname eq 'CWS-Windows_Personal_First_Devices'"
$alldevices = Get-MgGroupMember -GroupId $devicegroup.Id -All
$allIntuneDevices = Get-MgDeviceManagementManagedDevice -Filter "OperatingSystem eq 'Windows'" -All

$ObjectIdUsers = @()
foreach ($GroupOfUsers in $allusers) {
    if ($GroupOfUsers.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.user') {
        $ObjectIdUsers += [PSCustomObject]@{
            Name     = $GroupOfUsers.AdditionalProperties.displayName
            UPN      = $GroupOfUsers.AdditionalProperties.userPrincipalName
            ObjectId = $GroupOfUsers.Id
        }
    }
    elseif ($GroupOfUsers.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.group') {
        $NestedGroup = Get-MgGroupMember -GroupId $GroupOfUsers.Id -All 
        foreach ($NestedGroupObjectID in $NestedGroup) {
            $ObjectIdUsers += [PSCustomObject]@{
                Name     = $NestedGroupObjectID.AdditionalProperties.displayName
                UPN      = $NestedGroupObjectID.AdditionalProperties.userPrincipalName
                ObjectId = $NestedGroupObjectID.Id
            }
            
        }
    }   
}

$ObjectIdDevice = @()
foreach ($ObjectIdUser in $ObjectIdUsers) {
    $DeviceInfo = $allIntuneDevices | where-object { $_.UserPrincipalName -eq $ObjectIdUser.upn }
    if (!$DeviceInfo) {
        "No device for user: $($ObjectIdUser.Name). Cannot add here to the group."
    }
    else {
        foreach ($Device in $DeviceInfo) {
            $DeviceID = Get-MgDevice -Filter "deviceId eq '$($Device.AzureAdDeviceId)'"
            if ($DeviceID) {
                $ObjectIdDevice += [PSCustomObject]@{
                    Name     = $ObjectIdUser.Name
                    DeviceID = $DeviceID.Id
                }
            }
        }
    }
}

ForEach ($Comparison in Compare-object -ReferenceObject @($alldevices.Id | Select-Object -Unique) -DifferenceObject @($ObjectIdDevice.DeviceID | Select-Object -Unique) -IncludeEqual) {
    Switch ($Comparison.SideIndicator) {
        "<=" {
            $username = $ObjectIdDevice | where-object { $_.DeviceID -eq $Comparison.InputObject }
            Remove-MgGroupMemberByRef -GroupId $devicegroup.Id -DirectoryObjectId $Comparison.InputObject
            "Removing Object: $($Comparison.DeviceID) of users: $($username.name)." 
        }
        "=>" {
            $username = $ObjectIdDevice | where-object { $_.DeviceID -eq $Comparison.InputObject }
            New-MgGroupMember -GroupId $devicegroup.Id -DirectoryObjectId $Comparison.InputObject
            "Adding Object: $($Comparison.InputObject) of users: $($username.name)."
        }
        "==" {
            $username = $ObjectIdDevice | where-object { $_.DeviceID -eq $Comparison.InputObject }
            "The user: $($username.name) is already in: $($devicegroup.DisplayName) With device ID: $($Comparison.InputObject)." 
        }
    }
}
"All Done."