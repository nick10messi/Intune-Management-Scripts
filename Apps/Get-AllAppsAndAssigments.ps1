<#
.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.
#>

####################################################

function Get-AuthToken {

    <#
    .SYNOPSIS
    This function is used to authenticate with the Graph API REST interface
    .DESCRIPTION
    The function authenticate with the Graph API Interface with the tenant name
    .EXAMPLE
    Get-AuthToken
    Authenticates you with the Graph API interface
    .NOTES
    NAME: Get-AuthToken
    #>
    
    [cmdletbinding()]
    
    param
    (
        [Parameter(Mandatory=$true)]
        $User
    )
    
    $userUpn = New-Object "System.Net.Mail.MailAddress" -ArgumentList $User
    
    $tenant = $userUpn.Host
    
    Write-Host "Checking for AzureAD module..."
    
        $AadModule = Get-Module -Name "AzureAD" -ListAvailable
    
        if ($AadModule -eq $null) {
    
            Write-Host "AzureAD PowerShell module not found, looking for AzureADPreview"
            $AadModule = Get-Module -Name "AzureADPreview" -ListAvailable
    
        }
    
        if ($AadModule -eq $null) {
            write-host
            write-host "AzureAD Powershell module not installed..." -f Red
            write-host "Install by running 'Install-Module AzureAD' or 'Install-Module AzureADPreview' from an elevated PowerShell prompt" -f Yellow
            write-host "Script can't continue..." -f Red
            write-host
            exit
        }
    
    # Getting path to ActiveDirectory Assemblies
    # If the module count is greater than 1 find the latest version
    
        if($AadModule.count -gt 1){
    
            $Latest_Version = ($AadModule | select version | Sort-Object)[-1]
    
            $aadModule = $AadModule | ? { $_.version -eq $Latest_Version.version }
    
                # Checking if there are multiple versions of the same module found
    
                if($AadModule.count -gt 1){
    
                $aadModule = $AadModule | select -Unique
    
                }
    
            $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
            $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
    
        }
    
        else {
    
            $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
            $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
    
        }
    
    [System.Reflection.Assembly]::LoadFrom($adal) | Out-Null
    
    [System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null
    
    $clientId = "d1ddf0e4-d672-4dae-b554-9d5bdfd93547"
    
    $redirectUri = "urn:ietf:wg:oauth:2.0:oob"
    
    $resourceAppIdURI = "https://graph.microsoft.com"
    
    $authority = "https://login.microsoftonline.com/$Tenant"
    
        try {
    
        $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
    
        # https://msdn.microsoft.com/en-us/library/azure/microsoft.identitymodel.clients.activedirectory.promptbehavior.aspx
        # Change the prompt behaviour to force credentials each time: Auto, Always, Never, RefreshSession
    
        $platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList "Auto"
    
        $userId = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier" -ArgumentList ($User, "OptionalDisplayableId")
    
        $authResult = $authContext.AcquireTokenAsync($resourceAppIdURI,$clientId,$redirectUri,$platformParameters,$userId).Result
    
            # If the accesstoken is valid then create the authentication header
    
            if($authResult.AccessToken){
    
            # Creating header for Authorization token
    
            $authHeader = @{
                'Content-Type'='application/json'
                'Authorization'="Bearer " + $authResult.AccessToken
                'ExpiresOn'=$authResult.ExpiresOn
                }
    
            return $authHeader
    
            }
    
            else {
    
            Write-Host
            Write-Host "Authorization Access Token is null, please re-run authentication..." -ForegroundColor Red
            Write-Host
            break
    
            }
    
        }
    
        catch {
    
        write-host $_.Exception.Message -f Red
        write-host $_.Exception.ItemName -f Red
        write-host
        break
    
        }
    
    }
    
    ####################################################
    
    Function Get-IntuneApplication(){
    
    <#
    .SYNOPSIS
    This function is used to get applications from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets any applications added
    .EXAMPLE
    Get-IntuneApplication
    Returns any applications configured in Intune
    .NOTES
    NAME: Get-IntuneApplication
    #>
    
    [cmdletbinding()]
    
    $graphApiVersion = "Beta"
    $Resource = "deviceAppManagement/mobileApps"
        
        try {
            
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-RestMethod -Uri $uri –Headers $authToken –Method Get).Value | ? { (!($_.'@odata.type').Contains("managed")) }
    
        }
        
        catch {
    
        $ex = $_.Exception
        Write-Host "Request to $Uri failed with HTTP Status $([int]$ex.Response.StatusCode) $($ex.Response.StatusDescription)" -f Red
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        write-host
        break
    
        }
    
    }
    
    ####################################################
    
    Function Get-ApplicationAssignment(){
    
    <#
    .SYNOPSIS
    This function is used to get an application assignment from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets an application assignment
    .EXAMPLE
    Get-ApplicationAssignment
    Returns an Application Assignment configured in Intune
    .NOTES
    NAME: Get-ApplicationAssignment
    #>
    
    [cmdletbinding()]
    
    param
    (
        $ApplicationId
    )
    
    $graphApiVersion = "Beta"
    $Resource = "deviceAppManagement/mobileApps/$ApplicationId/?`$expand=categories,assignments"
        
        try {
            
            if(!$ApplicationId){
    
            write-host "No Application Id specified, specify a valid Application Id" -f Red
            break
    
            }
    
            else {
            
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
            (Invoke-RestMethod -Uri $uri –Headers $authToken –Method Get)
            
            }
        
        }
        
        catch {
    
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        write-host
        break
    
        }
    
    } 
    
    ####################################################
    
    #region Authentication
    
    write-host
    
    # Checking if authToken exists before running authentication
    if($global:authToken){
    
        # Setting DateTime to Universal time to work in all timezones
        $DateTime = (Get-Date).ToUniversalTime()
    
        # If the authToken exists checking when it expires
        $TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes
    
            if($TokenExpires -le 0){
    
            write-host "Authentication Token expired" $TokenExpires "minutes ago" -ForegroundColor Yellow
            write-host
    
                # Defining User Principal Name if not present
    
                if($User -eq $null -or $User -eq ""){
    
                $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
                Write-Host
    
                }
    
            $global:authToken = Get-AuthToken -User $User
    
            }
    }
    
    # Authentication doesn't exist, calling Get-AuthToken function
    
    else {
    
        if($User -eq $null -or $User -eq ""){
    
        $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
        Write-Host
    
        }
    
    # Getting the authorization token
    $global:authToken = Get-AuthToken -User $User
    
    }
    
    #endregion
    
    ####################################################
    # Retrieve all apps from the tenant
    $apps = Get-IntuneApplication
    Write-Host "Retrieved $($apps.count) apps" -ForegroundColor Green
     
    # Create a new array object
    $Output=New-Object System.Collections.ArrayList
     
    ForEach($App in $Apps){
        Write-Host "`nGetting assignments for app: $($app.displayname)" -ForegroundColor Yellow
        $AppID = $app.id
     
        $graphApiVersion = "Beta"
        $Resource = "deviceAppManagement/mobileApps/$AppID/?`$expand=categories,assignments"
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
     
        $AppQuery = (invoke-RestMethod -Uri $uri –Headers $authToken –Method Get)
     
        If(($AppQuery.assignments -eq $null) -or ($AppQuery.assignments -eq "") -or ($AppQuery.assignments.count -lt 1)){
     
                Write-Host "No assignments for this app" -ForegroundColor Yellow
                $groupname = "No assigments"
                $Output.Add( (New-Object -TypeName PSObject -Property @{"Name"="$($app.displayname)";"Group" = "$GroupName";"Assignment" = "N.v.t.";"Platform" = "N.v.t."} ) )
    
     
        } else {
     
            #Write-Host "Platform odata: $($AppQuery.'@odata.type')"
     
                    # The many diff types of app in Intune, we switch the variable to the correct platform
     
            $Platform = switch -Wildcard ( $AppQuery.'@odata.type' )
            {
                *androidForWorkApp* { 'Android for Work' }
                *microsoftStoreForBusiness* { 'Microsoft Store' }
                *iosVppApp* { 'Apple VPP' }
                *windowsPhoneXAP* { 'Windows Phone XAP'}
                *webApp* { 'Web Link'}
                default { 'Unknown' }
            }
     
            ForEach($assignment in $AppQuery.assignments){            
                # Available or Required
                write-host "Assignment intent: $($assignment.intent)"
     
                If ($($assignment.target.'@odata.type') -like "*allLicensedUsersAssignmentTarget"){
                    Write-Host "Published to All Users"
                    $GroupName = "All Users"
                } elseIf ($($assignment.target.'@odata.type') -like "*allDevicesAssignmentTarget"){
                    Write-Host "Published to All Devices"
                    $GroupName = "All Devices"
                } else {
                    # Lookup the AAD Group displayname
                    write-host "Group ID: $($assignment.target.GroupID)"
                    $GroupName = (Get-AzureADgroup -ObjectId $assignment.target.GroupID).DisplayName
                }
     
                # Add all the properties into a new object in the array
                Write-Host "Group Name: $GroupName"
                $Output.Add( (New-Object -TypeName PSObject -Property @{"Name"="$($app.displayname)";"Group" = "$GroupName";"Assignment" = "$($assignment.intent)";"Platform" = "$Platform"} ) )
     
            }
     
        }
     
    }
     
    # Format the column order by modifying the table output
    $File = "C:\temp\AllAppsAndAssigments.csv"
    Write-Host "Going to export all the data to $file"
    $output | Select-Object Name,Group,Assignment | Export-Csv $File