<#
.AUTHOR
    Nick Kok

.SYNOPSIS
    This script deletes an Entra ID admin account

.VERSION HISTORY
    v1.0.0 - [DD-MM-YYYY] Initial version
    v1.0.1 - [DD-MM-YYYY] ...
#>

#Check if Az.Resources module is installed
if (Get-Module -Name "Az.Resources" -ListAvailable){
    Write-Host "De PS-module: Az.Accounts is al geinstalleerd"
}
else {
    Install-Module Az.Resources -force -AllowClobber
    Import-Module Az.Resources
}

#Check if Microsoft.Graph.Identity.DirectoryManagement module is installed
if (Get-Module -Name "Microsoft.Graph" -ListAvailable){
    Write-Host "De PS-module: Microsoft.Graph is al geinstalleerd"
}
else {
    Install-Module -Name Microsoft.Graph -Force -AllowClobber
    Import-Module Microsoft.Graph
}

#Connect to Entra ID and Graph
Connect-Azaccount
Connect-MgGraph -scopes "User.Read.All","Group.Read.All","User.ReadWrite.All","domain.Read.All","GroupMember.ReadWrite.All" -NoWelcome

# Get First and Last name of Entra ID Admin
$First_Name = Read-Host -Prompt 'Enter the First name of the admin'
$Last_Name = Read-Host -Prompt 'Enter the Last name of the admin'

#Get the onmicrosoft domain of the customer tenant
$domain = (Get-MgDomain | Where-Object {$_.Id -like '*.onmicrosoft.com'}) | Select-Object Id -ExpandProperty Id

#Delete UPN b-name@<tenantname>.onmicrosoft.com
$UPN_Begin = "b-"
$UserPrincipalName = $UPN_Begin + $First_Name + "." + $Last_Name.Replace(" ",".") + "@" + $domain

#Deletes the Entra ID Admin account
Remove-AzADUser -UserPrincipalName $UserPrincipalName -Confirm:$false
Write-Host "$UserPrincipalName is now deleted in Entra ID and will remain in the recycle bin for 30 days before permanent deletion" -ForegroundColor Green