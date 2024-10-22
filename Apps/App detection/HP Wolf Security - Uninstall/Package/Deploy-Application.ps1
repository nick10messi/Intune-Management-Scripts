<#
.SYNOPSIS
	This script performs the installation or uninstallation of an application(s).
	# LICENSE #
	PowerShell App Deployment Toolkit - Provides a set of functions to perform common application deployment tasks on Windows.
	Copyright (C) 2017 - Sean Lillis, Dan Cunningham, Muhammad Mashwani, Aman Motazedian.
	This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
	You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
.DESCRIPTION
	The script is provided as a template to perform an install or uninstall of an application(s).
	The script either performs an "Install" deployment type or an "Uninstall" deployment type.
	The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.
	The script dot-sources the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.
.PARAMETER DeploymentType
	The type of deployment to perform. Default is: Install.
.PARAMETER DeployMode
	Specifies whether the installation should be run in Interactive, Silent, or NonInteractive mode. Default is: Interactive. Options: Interactive = Shows dialogs, Silent = No dialogs, NonInteractive = Very silent, i.e. no blocking apps. NonInteractive mode is automatically set if it is detected that the process is not user interactive.
.PARAMETER AllowRebootPassThru
	Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.
.PARAMETER TerminalServerMode
	Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Destkop Session Hosts/Citrix servers.
.PARAMETER DisableLogging
	Disables logging to file for the script. Default is: $false.
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeployMode 'Silent'; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -AllowRebootPassThru; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeploymentType 'Uninstall'; Exit $LastExitCode }"
.EXAMPLE
    Deploy-Application.exe -DeploymentType "Install" -DeployMode "Silent"
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
	[Parameter(Mandatory=$false)]
	[ValidateSet('Install','Uninstall','Repair')]
	[string]$DeploymentType = 'Install',
	[Parameter(Mandatory=$false)]
	[ValidateSet('Interactive','Silent','NonInteractive')]
	[string]$DeployMode = 'Interactive',
	[Parameter(Mandatory=$false)]
	[switch]$AllowRebootPassThru = $false,
	[Parameter(Mandatory=$false)]
	[switch]$TerminalServerMode = $false,
	[Parameter(Mandatory=$false)]
	[switch]$DisableLogging = $false
)

Try {
	## Set the script execution policy for this process
	Try { Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' } Catch {}

	##*===============================================
	##* VARIABLE DECLARATION
	##*===============================================
	[string]$appScriptVersion = '1.0.0' 
	[string]$appScriptDate = 'XX/XX/20XX'

	##* Do not modify section below
	#region DoNotModify

	## Variables: Exit Code
	[int32]$mainExitCode = 0

	## Variables: Script
	[string]$deployAppScriptFriendlyName = 'Deploy Application'
	[version]$deployAppScriptVersion = [version]'3.8.4.6'
	[string]$deployAppScriptDate = '13/03/2024'
	[hashtable]$deployAppScriptParameters = $psBoundParameters

	## Variables: Environment
	If (Test-Path -LiteralPath 'variable:HostInvocation') { $InvocationInfo = $HostInvocation } Else { $InvocationInfo = $MyInvocation }
	[string]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent

	#Load required variables from PackageData.xml
	#First load the PackageData.xml File
	$PackageDataFile = Join-Path -Path $scriptDirectory -ChildPath "PackageData.xml"
    Try {[Xml.XmlDocument]$xmlPackageDataFile = Get-Content -LiteralPath $PackageDataFile} 
	Catch {
        [int32]$mainExitCode = 69009
        Write-Error -Message "Failed to read PackageData.xml." -ErrorAction 'Continue'
        Exit $mainExitCode
    }
    [Xml.XmlElement]$xmlPackageData = $xmlPackageDataFile.PackageData

	#Now load the Application details from PackageData.xml
	[Xml.XmlElement]$xmlApplication = $xmlPackageData.Application
    [string]$appVendor = $xmlApplication.AppManufacturer 		# Set Deploy-Application Variable
    [string]$AppManufacturer = $appVendor						# Set Variable matching tag in PackageData.xml for future parsing
    [string]$appName = $xmlApplication.AppName 					# Set Deploy-Application Variable
	[string]$appNameSuffix = $xmlApplication.AppNameSuffix		# Set Variable matching tag in PackageData.xml for future parsing
    [string]$appVersion = $xmlApplication.AppVersion 			# Set Deploy-Application Variable
    [string]$appArch = $xmlApplication.AppArchitecture 			# Set Deploy-Application Variable
    [string]$appArchitecture = $appArch 						# Set Variable matching tag in PackageData.xml for future parsing
    [string]$appLang = $xmlApplication.AppLanguage 				# Set Deploy-Application Variable.
    [string]$appLanguage = $AppLang								# Set Variable matching tag in PackageData.xml for future parsing

	#Now load the Package details from PackageData.xml
	[Xml.XmlElement]$xmlPackage = $xmlPackageData.Package
    [string]$appID = $xmlPackage.PackageID 						# Set Deploy-Application Variable
    [string]$packageID = $appID									# Set Variable matching tag in PackageData.xml for future parsing
	[string]$appRevision = $xmlPackage.PackageVersion			# Set Deploy-Application Variable
    [String]$packageVersion = $appRevision						# Set Variable matching tag in PackageData.xml for future parsing
	[string]$appScriptAuthor = $xmlPackage.PackageAuthor		# Set Deploy-Application Variable
    [string]$packageAuthor = $appScriptAuthor					# Set Variable matching tag in PackageData.xml for future parsing

	#Get the PackageName from the XMl file and convert it, if it contains PS code.
	[boolean]$InstallNameAsCode = $False 
	If ($xmlPackage.PackageName) {
		If ($xmlPackage.PackageName.ResolveAsCode) {
			[boolean]$InstallNameAsCode = [boolean]::Parse($xmlPackage.PackageName.ResolveAsCode)
			If ($InstallNameAsCode) {
				Try {[string]$installName = Invoke-Expression -Command $($xmlPackage.PackageName.InnerText)} 
				Catch {
					[int32]$mainExitCode = 69010
					Write-Error -Message "Failed to process code for InstallName from PackageData.xml." -ErrorAction 'Continue'
					Exit $mainExitCode
				}
			}
		} 
		Else {
			$InstallNameAsCode = $False
		}
		If (!$InstallNameAsCode){
			Try {[string]$InstallName = $ExecutionContext.InvokeCommand.ExpandString($($xmlPackage.PackageName).Replace('_','`_'))} Catch {
				[int32]$mainExitCode = 69011
				Write-Error -Message "Failed to get InstallName from PackageData.xml." -ErrorAction 'Continue'
				Exit $mainExitCode
			}
		}
	} Else {
		# If PackageName is not set in the XML use the default below
		[string]$installName = $packageID + "_" + $appName + $(If($appNameSuffix){" $appNameSuffix"}) + $(If($appArch -eq 'x64'){' x64'}) + "_" + $appVersion
	}
	[string]$installTitle = $packageID + " " + $appManufacturer + " " + $appName + $(If($appNameSuffix){" $appNameSuffix"}) + $(If($appArch -eq 'x64'){' x64'}) + " " + $appVersion

	#Add AppNameSuffix to AppName if set. Not sure if AppName is used anywhere else in the script. If so it should be with the suffix included. So it is done just te be sure.
	$appName = $appName + $(If($appNameSuffix){" $appNameSuffix"})

	## Dot source the required App Deploy Toolkit Functions
	Try {
		[string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
		If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) { Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]." }
		If ($DisableLogging) { . $moduleAppDeployToolkitMain -DisableLogging } Else { . $moduleAppDeployToolkitMain }
	}
	Catch {
		If ($mainExitCode -eq 0){ [int32]$mainExitCode = 60008 }
		Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
		## Exit the script, returning the exit code to SCCM
		If (Test-Path -LiteralPath 'variable:HostInvocation') { $script:ExitCode = $mainExitCode; Exit } Else { Exit $mainExitCode }
	}

	#endregion
	##* Do not modify section above
	##*===============================================
	##* END VARIABLE DECLARATION
	##*===============================================

	#region InstallSection
	If ($deploymentType -ine 'Uninstall' -and $deploymentType -ine 'Repair') {
		##*===============================================
		##* PRE-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Installation'

		## Show Progress Message (with the default message)
		Show-InstallationProgress

		## <Perform Pre-Installation tasks here>
		#Show-InstallationWelcome -CloseApps '<exe-name without .exe>=<Friendly Name>' -CloseAppsCountdown 900 -Silent:$False

		##*===============================================
		##* INSTALLATION
		##*===============================================
		[string]$installPhase = 'Installation'
		# List of programs to uninstall
		$UninstallPrograms = @(
    		"HP Wolf Security"
    		"HP Wolf Security Application Support for Sure Sense"
    		"HP Wolf Security Application Support for Windows"
			"HP Wolf Security - Console"
			"HP Security Update Service"
		)

		$InstalledPrograms = Get-Package | Where-Object {$UninstallPrograms -contains $_.Name}

		# Remove installed programs
		$InstalledPrograms | ForEach-Object {

    	Write-Host -Object "Attempting to uninstall: [$($_.Name)]..."

    	Try {
        	$Null = $_ | Uninstall-Package -AllVersions -Force -ErrorAction Stop
        	Write-Host -Object "Successfully uninstalled: [$($_.Name)]"
    	}
    	Catch {Write-Warning -Message "Failed to uninstall: [$($_.Name)]"}
	}

	# Fallback attempt 1 to remove HP Wolf Security using msiexec
	Try {
    	MsiExec /x "{0E2E04B0-9EDD-11EB-B38C-10604B96B11E}" /qn /norestart
    	Write-Host -Object "Fallback to MSI uninistall for HP Wolf Security initiated"
	}
	Catch {
    	Write-Warning -Object "Failed to uninstall HP Wolf Security using MSI - Error message: $($_.Exception.Message)"
	}

	# Fallback attempt 2 to remove HP Wolf Security using msiexec
	Try {
    	MsiExec /x "{4DA839F0-72CF-11EC-B247-3863BB3CB5A8}" /qn /norestart
    	Write-Host -Object "Fallback to MSI uninistall for HP Wolf 2 Security initiated"
	}
	Catch {
    	Write-Warning -Object  "Failed to uninstall HP Wolf Security 2 using MSI - Error message: $($_.Exception.Message)"
	}

		##*===============================================
		##* POST-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Installation'
		## <Perform Post-Installation tasks here>


		##*===============================================
		##* USER-SETTINGS
		##*===============================================
        [string]$installPhase = 'Install-UserSettings'
        #Install Usersettings Deployment and apply usersettings each time the package is installed.
        #Set-UserSettingsDeployment -ActiveSetupTrigger EachInstall

	}
	#endregion InstallSection
    #region UninstallSection
	ElseIf ($deploymentType -ieq 'Uninstall')
	{
		##*===============================================
		##* PRE-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Uninstallation'

		## Show Progress Message (with the default message)
		Show-InstallationProgress

		## <Perform Pre-Uninstallation tasks here>
		#Show-InstallationWelcome -CloseApps '<exe-name without .exe>=<Friendly Name>' -CloseAppsCountdown 900 -Silent:$False

		##*===============================================
		##* UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Uninstallation'
		# <Perform Uninstallation tasks here>


		##*===============================================
		##* POST-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Uninstallation'

		## <Perform Post-Uninstallation tasks here>


		##*===============================================
		##* USER-SETTINGS
		##*===============================================
        [string]$installPhase = 'Uninstall-UserSettings'
        Remove-UserSettingsDeployment
		
	}
	#endregion UninstallSection
    #region RepairSection
	ElseIf ($deploymentType -ieq 'Repair')
	{
		##*===============================================
		##* PRE-REPAIR
		##*===============================================
		[string]$installPhase = 'Pre-Repair'

		## Show Progress Message (with the default message)
		Show-InstallationProgress

		## <Perform Pre-Repair tasks here>

		##*===============================================
		##* REPAIR
		##*===============================================
		[string]$installPhase = 'Repair'
		# <Perform Repair tasks here>

		##*===============================================
		##* POST-REPAIR
		##*===============================================
		[string]$installPhase = 'Post-Repair'

		## <Perform Post-Repair tasks here>


    }
	#endregion RepairSection
	##*===============================================
	##* END SCRIPT BODY
	##*===============================================

	## Call the Exit-Script function to perform final cleanup operations
	[string]$installPhase = 'Finalization'
	Exit-Script -ExitCode $mainExitCode
}
Catch {
	[string]$installPhase = 'Finalization'
	[int32]$mainExitCode = 60001
	[string]$mainErrorMessage = "$(Resolve-Error)"
	Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
	#Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
	Exit-Script -ExitCode $mainExitCode
}
