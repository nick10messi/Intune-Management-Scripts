#################################################################################################
# Install MS Graph module and import Microsoft.Graph.DeviceManagement.Administration module
#################################################################################################

if (Get-module "Microsoft.graph" -ListAvailable) {
	Write-Host "Microsoft.graph geïnstalleerd, doorgaan"
}
else {
	Write-Host "Microsoft.graph niet geïnstalleerd, installeren"
	Install-Module "Microsoft.Graph" -Force	
}

Import-Module Microsoft.Graph.DeviceManagement.Administration
Import-Module Microsoft.Graph.Groups

####################################################
# Connect to customer tenant
####################################################

Connect-MgGraph -Scopes "DeviceManagementRBAC.ReadWrite.All","GroupMember.ReadWrite.All" -NoWelcome

####################################################
# Create Entra ID Security group: CWS-RG-EPM-Approvers
####################################################
if (Get-MgGroup | Where-Object { $_.DisplayName -eq "CWS-RG-EPM-Approvers" }) {
	Write-Host "Group CWS-RG-EPM-Approvers bestaat al, doorgaan"
}
else {
	Write-Host "Group CWS-RG-EPM-Approvers bestaat nog niet, aanmaken"
	New-MgGroup -DisplayName "CWS-RG-EPM-Approvers" -MailEnabled:$False -MailNickName 'CWS-RG-EPM-Approvers' -SecurityEnabled
}

####################################################
# Create Intune custom role: CWS-RG-EPM-Approvers
####################################################

$params = @{
	"@odata.type" = "#microsoft.graph.deviceAndAppManagementRoleDefinition"
	displayName = "CWS-RG-EPM-Approvers"
	description = "Custom Intune role voor het goed- of afkeuren van EPM Elevation Requests."
	rolePermissions = @(
		@{
			"@odata.type" = "microsoft.graph.rolePermission"
			resourceActions = @(
				@{
					"@odata.type" = "microsoft.graph.resourceAction"
					allowedResourceActions = @(
					    "Microsoft.Intune_SecurityBaselines_Read",
    					"Microsoft.Intune_EpmPolicy_Read",
    					"Microsoft.Intune_EpmPolicy_ViewReports",
						"Microsoft.Intune_EpmPolicy_ModifyElevationRequests",
						"Microsoft.Intune_EpmPolicy_ViewElevationRequests",
						"Microsoft.Intune_Organization_Read"
				)
				notAllowedResourceActions = @(				
			)
		}
	)
}
)
isBuiltIn = $false
}

New-MgDeviceManagementRoleDefinition -BodyParameter $params