<#
.SYNOPSIS
This script assigns specified app roles to a Managed Identity in Microsoft Graph.

.DESCRIPTION
1. Connects to Microsoft Graph using specific permissions required for app role assignments.
2. Retrieves the Object ID of the Managed Identity from user input.
3. Retrieves the Microsoft Graph service principal by its Application ID.
4. Defines a function to assign app roles to the Managed Identity.
5. Assigns a predefined list of app roles to the Managed Identity.

.PARAMETER managedIdentityId
The Object ID of the Managed Identity to which roles will be assigned.

.PARAMETER msgraph
The Microsoft Graph Service Principal object retrieved using its App ID.

.PARAMETER roleName
The name of the app role to assign to the Managed Identity.

.EXAMPLE
# Assign roles to a Managed Identity
$managedIdentityId = Read-Host "Voer het Object ID van de Managed Identity in"
Set-AppRole -roleName "DeviceManagementManagedDevices.Read.All" -managedIdentityId $managedIdentityId -msgraph $msgraph

This example assigns the `DeviceManagementManagedDevices.Read.All` role to the specified Managed Identity.

#>
param (
  [Parameter(mandatory=$True)]
  [string]$ManagedIdentityId
)

#Requires -modules  @{ ModuleName="Microsoft.Graph.Authentication"; RequiredVersion="2.23.0"},@{ ModuleName="Microsoft.Graph.Applications"; RequiredVersion="2.23.0"}

# Connect to tenant with necessary permissions
Connect-MgGraph -Scopes Application.Read.All, AppRoleAssignment.ReadWrite.All, RoleManagement.ReadWrite.Directory -NoWelcome -ContextScope Process -ErrorAction Stop

# Retrieve Microsoft Graph Service Principal
$msgraph = Get-MgServicePrincipal -Filter "AppId eq '00000003-0000-0000-c000-000000000000'"

# Function to assign app roles
function Set-AppRole {
    param (
        [Parameter(Mandatory = $true)]
        [string]$roleName,
        [Parameter(Mandatory = $true)]
        [string]$managedIdentityId,
        [Parameter(Mandatory = $true)]
        [object]$msgraph
    )

    $appRole = $msgraph.AppRoles | Where-Object { $_.Value -eq $roleName }
    if ($appRole) {
        New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $managedIdentityId -PrincipalId $managedIdentityId -ResourceId $msgraph.Id -AppRoleId $appRole.Id
        Write-Output "Assigned $roleName successfully."
    } else {
        Write-Output "Role $roleName not found."
    }
}

# List of roles to assign
$rolesToAssign = @(
    "DeviceManagementManagedDevices.Read.All",
    "Directory.Read.All",
    "User.Read.All",
    "GroupMember.ReadWrite.All"
)

# Assign each role
foreach ($role in $rolesToAssign) {
    Set-AppRole -roleName $role -managedIdentityId $managedIdentityId -msgraph $msgraph
}

# Disconnect from Microsoft Graph
Disconnect-MgGraph