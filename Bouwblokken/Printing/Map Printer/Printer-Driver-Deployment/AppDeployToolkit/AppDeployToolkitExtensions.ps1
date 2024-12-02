<#
.SYNOPSIS
	This script is a template that allows you to extend the toolkit with your own custom functions.
    # LICENSE #
    PowerShell App Deployment Toolkit - Provides a set of functions to perform common application deployment tasks on Windows.
    Copyright (C) 2017 - Sean Lillis, Dan Cunningham, Muhammad Mashwani, Aman Motazedian.
    This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
    You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
.DESCRIPTION
	The script is automatically dot-sourced by the AppDeployToolkitMain.ps1 script.
.NOTES
    Toolkit Exit Code Ranges:
    60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
    69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
    70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1
.LINK
	http://psappdeploytoolkit.com
#>
[CmdletBinding()]
Param (
)

##*===============================================
##* VARIABLE DECLARATION
##*===============================================

# Variables: Script
[string]$appDeployToolkitExtName = 'PSAppDeployToolkitExt'
[string]$appDeployExtScriptFriendlyName = 'App Deploy Toolkit Extensions'
[version]$appDeployExtScriptVersion = [version]'3.8.3'
[string]$appDeployExtScriptDate = '30/09/2020'
[hashtable]$appDeployExtScriptParameters = $PSBoundParameters

##*===============================================
##* FUNCTION LISTINGS
##*===============================================

# <Your custom functions go here>

<# Documentatie Logging locatie: er zijn 2 aanpassingen gemaakt in Appdeploytoolkitmain.ps1 die niet hier kunnen ivm load order

(Regel 187)
# Get the management system
[boolean]$intuneManaged = [boolean](Get-Service -Name "Microsoft intune management extension" -ErrorAction SilentlyContinue)
[boolean]$SCCMManaged   = [boolean](Get-Service -Name "SMS Agent Host" -ErrorAction SilentlyContinue)




(Regel 352)
# Set log locations if SCCM or Intune joined
If ($intuneManaged -eq $true) {
	[string]$configMSILogDir     = $ExecutionContext.InvokeCommand.ExpandString($xmlConfig.Intune_Options.MSI_LogPath)
	[string]$configToolkitLogDir = $ExecutionContext.InvokeCommand.ExpandString($xmlConfig.Intune_Options.Toolkit_LogPath)
}

If (($intuneManaged -eq $false) -and ($SCCMManaged -eq $true)) {
	[string]$configMSILogDir     = $ExecutionContext.InvokeCommand.ExpandString($xmlConfig.SCCM_Options.MSI_LogPath)
	[string]$configToolkitLogDir = $ExecutionContext.InvokeCommand.ExpandString($xmlConfig.SCCM_Options.Toolkit_LogPath)
}


Hiernaast ook uitbreiding op AppDeploytoolkitConfig.xml 
(Regel 74)
	<!--Intune Options-->
	<Intune_Options>
		<Toolkit_LogPath>$env:ProgramData\Microsoft\IntuneManagementExtension\Logs</Toolkit_LogPath>
		<!-- Log path used for Toolkit logging. -->
		<MSI_LogPath>$env:ProgramData\Microsoft\IntuneManagementExtension\Logs</MSI_LogPath>
		<!-- Log path used for MSI logging. -->
	</Intune_Options>

	<!--Intune Options-->

	<!--SCCM Options-->
	<SCCM_Options>
		<Toolkit_LogPath>$env:windir\CCM\Logs</Toolkit_LogPath>
		<!-- Log path used for Toolkit logging. -->
		<MSI_LogPath>$env:windir\CCM\Logs</MSI_LogPath>
		<!-- Log path used for MSI logging. -->
	</SCCM_Options>
	<!--SCCM Options-->

#>

##*===============================================
##* END FUNCTION LISTINGS
##*===============================================

##*===============================================
##* SCRIPT BODY
##*===============================================

If ($scriptParentPath) {
	Write-Log -Message "Script [$($MyInvocation.MyCommand.Definition)] dot-source invoked by [$(((Get-Variable -Name MyInvocation).Value).ScriptName)]" -Source $appDeployToolkitExtName
} Else {
	Write-Log -Message "Script [$($MyInvocation.MyCommand.Definition)] invoked directly" -Source $appDeployToolkitExtName
}

##*===============================================
##* END SCRIPT BODY
##*===============================================
