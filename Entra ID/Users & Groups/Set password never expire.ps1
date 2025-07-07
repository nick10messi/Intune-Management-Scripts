<#
.AUTHOR
    Nick Kok

.SYNOPSIS
    This script sets the password of a specific Entra ID user to never expire

.VERSION HISTORY
    v1.0.0 - [DD-MM-YYYY] Initial version
    v1.0.1 - [DD-MM-YYYY] ...
#>

#Check if specific Graph-module is installed
if (Get-Module -ListAvailable -Name Microsoft.Graph.Users) {
    Write-Host "Module Microsoft.Graph.Users already installed"
} 
else {
    Write-Host "Microsoft.Graph.Users Module does not exist, installing."
    Install-Module -Name "Microsoft.Graph.Users" -Force -AllowClobber
}

#Import Module and connect to Graph
Import-Module "Microsoft.Graph.Users"
Connect-MgGraph -Scopes "User.ReadWrite.All" -ContextScope Process

#Get UserPrincipal
$UPN = Read-Host "Voer de UPN in van de gebruiker"

# Get current password policy for user
Get-MGuser -UserId $UPN -Property UserPrincipalName, PasswordPolicies | Select-Object UserPrincipalName, @{
    N = "PasswordNeverExpires"; E = { $_.PasswordPolicies -contains "DisablePasswordExpiration" }
}

# set password policy to never expire
Update-MgUser -UserId $UPN -PasswordPolicies DisablePasswordExpiration

# check all users
Get-MGuser -All -Property UserPrincipalName, PasswordPolicies, OnPremisesSyncEnabled  | Select-Object UserprincipalName, OnPremisesSyncEnabled, @{
    N = "PasswordNeverExpires";
    E = { $_.PasswordPolicies -contains "DisablePasswordExpiration" };
}