<#
.SYNOPSIS
This script connects to Microsoft Graph and automates the creation of security groups in Microsoft 365.

.DESCRIPTION
1. Defines functions to create static and dynamic security groups if they do not already exist:
   - `Create-StaticGroup`: Creates a static group with a specified name.
   - `Create-DynamicGroup`: Creates a dynamic group with a specified name and membership rule.
2. Specifies arrays for static and dynamic groups, including group names and membership rules.
3. Creates static groups by calling the `Create-StaticGroup` function for each name in the `$staticGroups` array.
4. Creates dynamic groups by calling the `Create-DynamicGroup` function for each name and rule in the `$dynamicGroups` array.
5. Outputs messages indicating whether groups were created or already exist.
6. Disconnects from Microsoft Graph after completing the operations.

.PARAMETER GroupName
The name of the group to be created. This parameter is used in both `Create-StaticGroup` and `Create-DynamicGroup` functions.

.PARAMETER MembershipRule
The membership rule used to define the criteria for membership in a dynamic group. This parameter is only used in the `Create-DynamicGroup` function.

.EXAMPLE
# To create the static and dynamic groups as defined in the script:
.\YourScript.ps1
# This command will create groups specified in the `$staticGroups` and `$dynamicGroups` arrays.
# The script will output messages indicating whether groups were created or already exist.
#>


#Modules
#Requires -modules  @{ ModuleName="Microsoft.Graph.Authentication"; RequiredVersion="2.23.0"},@{ ModuleName="Microsoft.Graph.Groups"; RequiredVersion="2.23.0"}

# Function to create a static group if it doesn't already exist
function New-StaticGroup {
    param (
        [string]$GroupName
    )

    try {
        $group = Get-MgGroup -Filter "displayName eq '$GroupName'"
    }
    catch {
        Write-Output "Error fetching group: $_"
        $group = $null
    }
    
    if (-not $group) {
        Write-Output "Creating static group: $GroupName"
        New-MgGroup -DisplayName $GroupName -MailEnabled:$false -MailNickname $GroupName -SecurityEnabled
    }
    else {
        Write-Output "Static group $GroupName already exists."
    }

}

# Function to create a dynamic group if it doesn't already exist
function New-DynamicGroup {
    param (
        [string]$GroupName,
        [string]$MembershipRule
    )

    try {
        $group = Get-MgGroup -Filter "displayName eq '$GroupName'"
    }
    catch {
        Write-Output "Error fetching group: $_"
        $group = $null
    }
    
    if (-not $group) {
        Write-Output "Creating dynamic group: $GroupName"
        New-MgGroup -DisplayName $GroupName -MailEnabled:$false -MailNickname $GroupName -SecurityEnabled `
            -GroupTypes DynamicMembership -MembershipRule $MembershipRule -MembershipRuleProcessingState On
    }
    else {
        Write-Output "Dynamic group $GroupName already exists."
    }
    
}

# Static group names
$staticGroups = @(
    "CWS-Windows_Personal_Autopatch_First_Users",
    "CWS-Windows_Personal_Autopatch_First_Devices",
    "CWS-Windows_Personal_Autopatch_Pilot_Users",
    "CWS-Windows_Personal_Autopatch_Pilot_Devices",
    "CWS-Windows_Personal_Autopatch_Production_Devices"
)

# Dynamic group details
$dynamicGroups = @(
    @{ Name = "CWS-Windows_Shared_Autopatch_Production_Devices"; Rule = '(device.enrollmentProfileName -startsWith "CWS Autopilot Shared Managed") or (device.enrollmentProfileName -startsWith "CWS_AutoPilot_Windows_Shared")' },
    @{ Name = "CWS-Windows_Kiosk_Autopatch_Production_Devices"; Rule = '(device.enrollmentProfileName -startsWith "CWS AutoPilot Single App Kiosk Managed") or (device.enrollmentProfileName -startsWith "CWS AutoPilot Multi App Kiosk Managed") or (device.enrollmentProfileName -startsWith "CWS_AutoPilot_Windows_Multi_App_Kiosk") or (device.enrollmentProfileName -startsWith "CWS_AutoPilot_Windows_Single_App_Kiosk")' }
)

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Group.ReadWrite.All" -NoWelcome -ContextScope Process -ErrorAction Stop
# Create static groups
foreach ($group in $staticGroups) {
    New-StaticGroup -GroupName $group
}

# Create dynamic groups
foreach ($dynamicGroup in $dynamicGroups) {
    New-DynamicGroup -GroupName $dynamicGroup.Name -MembershipRule $dynamicGroup.Rule
}

# Disconnect from Microsoft Graph
Disconnect-MgGraph
