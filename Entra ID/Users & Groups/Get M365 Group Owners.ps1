<#
.AUTHOR
    Nick Kok

.SYNOPSIS
    This script gets all Microsoft 365 Group owners and exports them to a CSV

.VERSION HISTORY
    v1.0.0 - [DD-MM-YYYY] Initial version
    v1.0.1 - [DD-MM-YYYY] ...
#>


# Check if Exchange Online module is installed
if (Get-Module -ListAvailable -Name ExchangeOnlineManagement) {
    Write-Host "Module Exchange Online already installed"
} 
else {
    Write-Host "Exchange Online Module does not exist, installing."
    Install-Module -Name ExchangeOnlineManagement -Force -AllowClobber
}

# Import Module and connect to Exchange Online
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline

#Get All Microsoft 365 Groups
$GroupData = @()
$Groups = Get-UnifiedGroup -ResultSize Unlimited -SortBy Name

#Loop through each Group
$Groups | Foreach-Object {

    #Get Group Owners
    $GroupOwners = Get-UnifiedGroupLinks -LinkType Owners -Identity $_.Id | Select DisplayName
    $GroupData += New-Object -TypeName PSObject -Property @{
    GroupName = $_.Alias
    OwnerName = $GroupOwners.DisplayName -join "; "
    }
}

#Export Group Owners data to CSV
$GroupData | Export-Csv -Path "$env:userprofile\Downloads\M365-Groups-Owners.csv"