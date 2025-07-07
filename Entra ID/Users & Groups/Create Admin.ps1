<#
.AUTHOR
    Nick Kok

.SYNOPSIS
    This script creates an Admin account in Entra ID

.VERSION HISTORY
    v1.0.0 - [DD-MM-YYYY] Initial version
    v1.0.1 - [DD-MM-YYYY] ...
#>

function Get-RandomPassword {
    param(
        [Parameter(Mandatory = $false)]
        [int32]$Length = 0  # Default value of 0 to indicate not provided
    )

    if ($Length -eq 0) {
        $Length = Get-Random -Minimum 20 -Maximum 32  # Random length between 20 and 32
    }

    $charlist = '^_`!"#$%&()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~'.ToCharArray()
    $pwdList = @()
    
    for ($i = 0; $i -lt $Length; $i++) {
        $pwdList += $charList | Get-Random
    }

    $pass = -join $pwdList
    return $pass
}

#Check if Microsoft.Graph.Identity.DirectoryManagement module is installed
if (Get-Module -Name "Microsoft.Graph" -ListAvailable) {
    Write-Host "De PS-module: Microsoft.Graph is al geinstalleerd"
}
else {
    Install-Module -Name Microsoft.Graph -Force -AllowClobber
    Import-Module Microsoft.Graph
}

#Connect to Graph
Connect-MgGraph -scopes "User.ReadWrite.All", "domain.Read.All", "GroupMember.ReadWrite.All","RoleManagement.ReadWrite.Directory"

# Get First and Last name of AAD Admin
$First_Name = Read-Host -Prompt 'Enter the First name of the admin'
$Last_Name = Read-Host -Prompt 'Enter the Last name of the admin'

# Generate Mail nickname
$mailNickname = $First_Name + $Last_Name.Replace(" ", ".")

#Displayname of AAD Admin
$Displayname_end = "(beheeraccount)"
$DisplayNameFinal = $first_Name + " " + $Last_Name + " " + $Displayname_end
Write-Host "Creating admin account with displayname: $displaynameFinal"

#Get the onmicrosoft domain of the customer tenant
$domain = (Get-MgDomain | Where-Object { $_.Id -like '*.onmicrosoft.com' -and $_.Id -notlike '*.mail.onmicrosoft.com' }) | Select-Object Id -ExpandProperty Id
Write-Host "Creating admin account with Domain: @$domain"

#Create UPN b-name@<tenantname>.onmicrosoft.com
$UPN_Begin = "b-"
$UserPrincipalName = $UPN_Begin + $First_Name + "." + $Last_Name.Replace(" ", ".") + "@" + $domain
Write-Host "Creating admin account with UPN: $userPrincipalName"

#Creates the temporary password for the AAD Admin account (user has to change this at first logon)
$password = Get-RandomPassword

#Creates the AAD Admin account
$PasswordProfile = @{
    Password = $password
    ForceChangePasswordNextSignIn = $True
}
New-MgUser -DisplayName $DisplayNameFinal -GivenName $First_Name -Surname $Last_Name -PasswordProfile $PasswordProfile -AccountEnabled -MailNickName $mailNickname -UserPrincipalName $UserPrincipalName


# Get ObjectID of created AAD Admin
$AAD_Admin_ObjectID = Get-Mguser -UserId $UserPrincipalName | Select-Object Id -ExpandProperty Id 

# Choose role group
Do {
    $Chosen_RoleGroup = Read-Host "Selecteer de Rolegroup waar de AAD admin aan moet worden toegevoegd. Opties zijn: [s]ervicedesk, [o]n-Site Support, [h]ybride Werken, [v]eilig Werken, [sl]immer samenwerken, [c]loud desktop, [g]overnance architecture, [sec]urity, [a]zure, [k]lant Contact Center, [os] team, [app]lication packaging, [w]orkflow automation"
}
until ($Chosen_RoleGroup -eq 's' -or $Chosen_RoleGroup -eq 'o' -or $Chosen_RoleGroup -eq 'h' -or $Chosen_RoleGroup -eq 'v' -or $Chosen_RoleGroup -eq 'sl' -or $Chosen_RoleGroup -eq 'c' -or $Chosen_RoleGroup -eq 'g' -or $Chosen_RoleGroup -eq 'sec' -or $Chosen_RoleGroup -eq 'a' -or $chosen_RoleGroup -eq 'k' -or $Chosen_RoleGroup -eq 'os' -or $Chosen_RoleGroup -eq 'app' -or $Chosen_RoleGroup -eq 'w')

#Adds the AAD Admin account to the chosen Role Group
if ($Chosen_RoleGroup -eq 's') {
    $Servicedesk = Get-MgGroup -Filter "DisplayName eq 'RG-Servicedesk'" | Select-Object Id -ExpandProperty ID
    New-MgGroupMember -GroupId $Servicedesk -DirectoryObjectId $AAD_Admin_ObjectID
    Write-Host "$userprincipalname toegevoegd aan role group: RG-Servicedesk" -ForegroundColor Green
}
elseif ($Chosen_RoleGroup -eq 'o') {
    $OSS = Get-MgGroup -Filter "DisplayName eq 'RG-Onsite-Support'" | Select-Object Id -ExpandProperty ID
    New-MgGroupMember -GroupId $OSS -DirectoryObjectId $AAD_Admin_ObjectID
    Write-Host "$userprincipalname toegevoegd aan role group: RG-Onsite-Support" -ForegroundColor Green
}
elseif ($Chosen_RoleGroup -eq 'h') {
    $HybrideWerken = Get-MgGroup -Filter "DisplayName eq 'CWS-RG-Team-Hybride-Werken'" | Select-Object Id -ExpandProperty ID
    New-MgGroupMember -GroupId $HybrideWerken -DirectoryObjectId $AAD_Admin_ObjectID
    Write-Host "$userprincipalname toegevoegd aan role group: CWS-RG-Team-Hybride-Werken" -ForegroundColor Green
}
elseif ($Chosen_RoleGroup -eq 'v') {
    $VeiligWerken = Get-MgGroup -Filter "DisplayName eq 'CWS-RG-Team-Veilig-Werken'" | Select-Object Id -ExpandProperty ID
    New-MgGroupMember -GroupId $VeiligWerken -DirectoryObjectId $AAD_Admin_ObjectID
    Write-Host "$userprincipalname toegevoegd aan role group: CWS-RG-Team-Veilig-Werken" -ForegroundColor Green
}
elseif ($Chosen_RoleGroup -eq 'sl') {
    $SlimmerSamenWerken = Get-MgGroup -Filter "DisplayName eq 'CWS-RG-Team-Slimmer-Samen-Werken'" | Select-Object Id -ExpandProperty ID
    New-MgGroupMember -GroupId $SlimmerSamenWerken -DirectoryObjectId $AAD_Admin_ObjectID
    Write-Host "$userprincipalname toegevoegd aan role group: CWS-RG-Team-Slimmer-Samen-Werken" -ForegroundColor Green
}
elseif ($Chosen_RoleGroup -eq 'c') {
    $CloudDesktop = Get-MgGroup -Filter "DisplayName eq 'CWS-RG-Team-Cloud-Desktop'" | Select-Object Id -ExpandProperty ID
    New-MgGroupMember -GroupId $CloudDesktop -DirectoryObjectId $AAD_Admin_ObjectID
    Write-Host "$userprincipalname toegevoegd aan role group: CWS-RG-Team-Cloud-Desktop" -ForegroundColor Green
}
elseif ($Chosen_RoleGroup -eq 'g') {
    $GovernanceArchitecture = Get-MgGroup -Filter "DisplayName eq 'CWS-RG-Team-Governance-Architecture'" | Select-Object Id -ExpandProperty ID
    New-MgGroupMember -GroupId $GovernanceArchitecture -DirectoryObjectId $AAD_Admin_ObjectID
    Write-Host "$userprincipalname toegevoegd aan role group: CWS-RG-Team-Governance-Architecture" -ForegroundColor Green
}
elseif ($Chosen_RoleGroup -eq 'sec') {
    $Security = Get-MgGroup -Filter "DisplayName eq 'CWS-RG-Security'" | Select-Object Id -ExpandProperty ID
    New-MgGroupMember -GroupId $Security -DirectoryObjectId $AAD_Admin_ObjectID
    Write-Host "$userprincipalname toegevoegd aan role group: CWS-RG-Security" -ForegroundColor Green
}
elseif ($Chosen_RoleGroup -eq 'a') {
    $Azure = Get-MgGroup -Filter "DisplayName eq 'CWS-RG-Team-Azure'" | Select-Object Id -ExpandProperty ID
    New-MgGroupMember -GroupId $Azure -DirectoryObjectId $AAD_Admin_ObjectID
    Write-Host "$userprincipalname toegevoegd aan role group: CWS-RG-Team-Azure" -ForegroundColor Green
}
elseif ($Chosen_RoleGroup -eq 'k') {
    $KCC = Get-MgGroup -Filter "DisplayName eq 'CWS-RG-SD-Contact-Center'" | Select-Object Id -ExpandProperty ID
    New-MgGroupMember -GroupId $KCC -DirectoryObjectId $AAD_Admin_ObjectID
    Write-Host "$userprincipalname toegevoegd aan role group: CWS-RG-SD-Contact-Center" -ForegroundColor Green
}
elseif ($Chosen_RoleGroup -eq 'os') {
    $OS_team = Get-MgGroup -Filter "DisplayName eq 'CWS-RG-Team-OS-Beheer'" | Select-Object Id -ExpandProperty ID
    New-MgGroupMember -GroupId $OS_team -DirectoryObjectId $AAD_Admin_ObjectID
    Write-Host "$userprincipalname toegevoegd aan role group: CWS-RG-Team-OS-Beheer" -ForegroundColor Green
}
elseif ($Chosen_RoleGroup -eq 'app') {
    $Application_Packaging = Get-MgGroup -Filter "DisplayName eq 'CWS-RG-Application-Packaging'" | Select-Object Id -ExpandProperty ID
    New-MgGroupMember -GroupId $Application_Packaging -DirectoryObjectId $AAD_Admin_ObjectID
    Write-Host "$userprincipalname toegevoegd aan role group: CWS-RG-Application-Packaging" -ForegroundColor Green
}
elseif ($Chosen_RoleGroup -eq 'w') {
    $Application_Packaging = Get-MgGroup -Filter "DisplayName eq 'CWS-RG-Workflow-Automation'" | Select-Object Id -ExpandProperty ID
    New-MgGroupMember -GroupId $Application_Packaging -DirectoryObjectId $AAD_Admin_ObjectID
    Write-Host "$userprincipalname toegevoegd aan role group: CWS-RG-Workflow-Automation" -ForegroundColor Green
}
else {
    Write-Host "De ingevoerde waarde wordt niet geaccepteerd. Probeer het opnieuw" -ForegroundColor Red
}

Write-Host "AAD Admin created: $userprincipalname" -ForegroundColor Green
Write-Host "Wachtwoord: $password" -ForegroundColor Cyan

Disconnect-MgGraph | Out-Null
Write-Host "Microsoft Graph disconnected" -ForegroundColor Red