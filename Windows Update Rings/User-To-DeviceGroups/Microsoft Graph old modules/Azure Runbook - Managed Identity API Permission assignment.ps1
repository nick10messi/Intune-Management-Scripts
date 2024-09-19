# Connect to tenant with necessary permissions
Connect-MgGraph -Scopes Application.Read.All, AppRoleAssignment.ReadWrite.All, RoleManagement.ReadWrite.Directory -NoWelcome

# Get Object ID of Managed Identity
$managedIdentityId = Read-Host "Voer het Object ID van de Managed Identity in"

# Retrieve Microsoft Graph Service Principal
$msgraph = Get-MgServicePrincipal -Filter "AppId eq '00000003-0000-0000-c000-000000000000'"

# Function to assign app roles
function Set-AppRole {
    param (
        [string]$roleName,
        [string]$managedIdentityId,
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