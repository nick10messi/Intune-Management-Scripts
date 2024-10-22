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
[version]$appDeployExtScriptVersion = [version]'3.8.2.146'
[string]$appDeployExtScriptDate = '26/06/2024'
[hashtable]$appDeployExtScriptParameters = $PSBoundParameters
[string]$dirUserSettings = Join-Path -Path $scriptParentPath -ChildPath 'UserSettings'



##*===============================================
##* FUNCTION LISTINGS
##*===============================================

#region Function Set-UserSettingsDeployment
Function Set-UserSettingsDeployment {
<#
.SYNOPSIS
	Enable enable usersettings to be applied when user logs-on. Uses the Function Set-ActiveSetup so that the Usersettings al immediately applied for the current logged-on user.
	Checks for existence of the file 'UserSettings\ApplyUserSettings.cmd' in the script folder. Usersettings deployment is only applied if this file exists.
	All files in the UserSettings folder are copied to %PROGRAMDATA%\ActiveSetupPackages\$InstallName.
	If the file 'PersistSettings.cmd' exists an entry is made in HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run to execute the cmd. So this cmd is executed each time a user logs on.
	The file 'ApplyUserSettings.cmd' also has to exist for the Run key entry for 'PersistSettings.cmd' to be made. 
	The 'PersistSettings.cmd' is also run imediately for the current logged-on user.
    Update 3.8.2.6: Added parameter to allow selection between AppRevision/PackageVersion or Install Time stamp for ActiveSetup version. This wil either trigger Active setup only once for each AppRevision/PackageVersion of each time the Package is installed.
.DESCRIPTION
	Enables deployment of usersettings.
.PARAMETER ActiveSetupTrigger 
    Specifies when UserSettings ActiveSetup is triggered to run. Default is: EachAppRevision. Options: EachAppRevision, EachInstall
.EXAMPLE
	Set-UserSettingsDeployment
.NOTES
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
	    [string]$Name = $InstallName,
	    [Parameter(Mandatory=$false)]
	    [ValidateSet('EachAppRevision','EachInstall')]
	    [string]$ActiveSetupTrigger = 'EachAppRevision',
		[Parameter(Mandatory=$false)]
		[ValidateSet('AllUsers','CurrentUser')]
		[string]$Scope = 'AllUsers',
		[Switch]$AllowInstallOnServer
	)

	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}

	Process {
		#Only Install Usersettings Deployment when installing on a workstation of AllowInstallOnServer = True and the Usersettings folder in the package exists.
		$Workstation = 1
        If ((((Get-WmiObject win32_OperatingSystem).ProductType -eq $Workstation) -or $AllowInstallOnServer) -and (Test-Path $dirUserSettings)) {
			#Start install of Usersettings Deployment
			Switch($Scope) {
				"AllUsers" {
					$TargetDir = "$envProgramData\PSADT_Packages\$Name\UserSettings"
					#Only apply usersettings if the ApplyUserSettings.cmd file exists in the UserSettings folder
					Write-Log -Message "Copying contents of UserSettings folder to $TargetDir"  -Source ${CmdletName}
					Copy-FileEx -Path "$dirUserSettings\*" -Destination $TargetDir -Recurse -DestinationType Folder -ContinueOnError $false
					If (Test-Path $(Join-Path -Path $TargetDir -ChildPath 'ApplyUserSettings.cmd')) {
						Switch($ActiveSetupTrigger) {
							"EachAppRevision" {
								Set-ActiveSetup -StubExePath $(Join-Path -Path $TargetDir -ChildPath 'ApplyUserSettings.cmd') -Version $appRevision.Replace('.', ',')
							}
							"EachInstall" {
								Set-ActiveSetup -StubExePath $(Join-Path -Path $TargetDir -ChildPath 'ApplyUserSettings.cmd')
							}
						}
					}
					$RunKeyHive = 'HKLM'
					$PersistSettingsPath = Join-Path -Path $TargetDir -ChildPath 'PersistSettings.cmd'				
				}
				"CurrentUser" {
					$TargetDir = "$envLocalAppData\PSADT_Packages\$Name\UserSettings"
					#Only apply usersettings if the ApplyUserSettings.cmd file exists in the UserSettings folder
					If (Test-Path $(Join-Path -Path $dirUserSettings -ChildPath 'ApplyUserSettings.cmd')) {
						Execute-Process -Path $(Join-Path -Path $dirUserSettings -ChildPath 'ApplyUserSettings.cmd') -IgnoreExitCodes "*"
					}
					$RunKeyHive='HKCU'
				}
			}
			
			#Set execution of script for persisting user settings if PersistSettings.cmd exists
			If (Test-Path $(Join-Path -Path $dirUserSettings -ChildPath 'PersistSettings.cmd')){
				If (!(Test-Path $(Join-Path -Path $Targetdir -ChildPath 'PersistSettings.cmd'))){
					Write-Log -Message "Copying contents of UserSettings folder to $TargetDir"  -Source ${CmdletName}
					Copy-FileEx -Path "$dirUserSettings\*" -Destination $TargetDir -DestinationType Folder -ContinueOnError $false
				}
				Write-Log -Message "Adding Persisting Usersettings script to $RunKeyHive Run key" -Source ${CmdletName}
				Set-RegistryKey -Key "$($RunKeyHive):SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name $Name -Value $(Join-Path -Path $Targetdir -ChildPath 'PersistSettings.cmd')
				If ($SessionZero) {
					If ($RunAsActiveUser) {
						Write-Log -Message "Session 0 detected: Execute $(Join-Path -Path $Targetdir -ChildPath 'PersistSettings.cmd') for currently logged in user [$($RunAsActiveUser.NTAccount)]." -Source ${CmdletName}
						Execute-ProcessAsUser -Path $(Join-Path -Path $Targetdir -ChildPath 'PersistSettings.cmd') -Wait -ContinueOnError $true
					}
					Else {
						Write-Log -Message "Session 0 detected: No logged in users detected. $(Join-Path -Path $Targetdir -ChildPath 'PersistSettings.cmd') will execute when users log into their account." -Source ${CmdletName}
					}
				}
				Else {
					Execute-Process -Path $(Join-Path -Path $Targetdir -ChildPath 'PersistSettings.cmd') -Wait -ContinueOnError $true
				}
			}
		}
		ElseIf (!(Test-Path $dirUserSettings)){
			Write-Log -Message "No Usersettings folder found in package folder. Skipping Usersettings deployment." -Source ${CmdletName}
		}
		Else {
			Write-Log -Message "Install running on a Server. Skipping install of Usersettings Deployment." -Source ${CmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion
	
#region Function Remove-UserSettingsDeployment
Function Remove-UserSettingsDeployment{
<#
.SYNOPSIS
	Removes the User Settings configuration from disk and from the registry.
.DESCRIPTION
	Removes the User Settings configuration from disk and from the registry.
.PARAMETER Name
	Name of the ActiveSetup to remove. Default: $InstallName. This parameter can be used to remove the UserConfiguration of another application.
.EXAMPLE
	Remove-UserSettingsDeployment
.NOTES
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
	    [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
	    [string]$Name = $InstallName
	)

    Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
    Process {

        Write-Log -Message "Running User Setting Deployment Removal for $Name" -Source ${CmdletName}
        [string]$ActiveSetupRegKey = "HKLM:SOFTWARE\Microsoft\Active Setup\Installed Components\$Name"
        [string]$RunKey = "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
        [string]$RunKeyUser = "HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
        [String]$TargetDir = "$envProgramData\PSADT_Packages\$Name\UserSettings"
		# OldTargetDir was the loction where UserSettingsDeployment was stored in older versions of the Set-UserSettingsDeployment function
		[String]$OldTargetDir = "$envProgramData\ActiveSetupPackages\$Name"
		[String]$TargetDirUser = "$envLocalAppData\PSADT_Packages\$Name\UserSettings"


        If (Test-Path $ActiveSetupRegKey -PathType Container) {
            Write-Log -Message "Removing User Settings configuration ActiveSetup." -Source ${CmdletName}
            Remove-RegistryKey -Key $ActiveSetupRegKey
        }
        Else {
            Write-Log -Message "No ActiveSetup found for $Name." -Source ${CmdletName}
        }
  
        If (Test-RegistryValue -Key $RunKey -Value $Name) {
            Write-Log -Message "Removing Persistent User Settings HKLM-Run $Name." -Source ${CmdletName}
            Remove-RegistryKey -Key $RunKey -Name $Name
        }
        Else {
            Write-Log -Message "No Run key found for $Name." -Source ${CmdletName}
        }
  
        If (Test-RegistryValue -Key $RunKeyUser -Value $Name) {
            Write-Log -Message "Removing Persistent User Settings HKCU-Run $Name." -Source ${CmdletName}
            Remove-RegistryKey -Key $RunKeyUser -Name $Name
        }
        Else {
            Write-Log -Message "No Run key found for CurrentUser for $Name." -Source ${CmdletName}
        }		

        If (Test-Path $TargetDir)
        {
            Write-Log -Message "Removing User Settings configuration folder $TargetDir" -Source ${CmdletName}
            Remove-FolderAndEmptyParents -Path $TargetDir -ParentHeight 2
        }
		Else {
			Write-Log -Message "UserSettings Configuration folder $TargetDir not found." -Source ${CmdletName}
			If (Test-Path $OldTargetDir){
				# Remove UserSettingsDeployment from location where it was stored in older versions of the Set-UserSettingsDeployment function
				Write-Log -Message "Removing User Settings configuration folder $OldTargetDir" -Source ${CmdletName}
				Remove-FolderAndEmptyParents -Path $OldTargetDir
			}
			Else
			{
				Write-Log -Message "UserSettings Configuration folder $OldTargetDir not found." -Source ${CmdletName}
			}
		}

        If (Test-Path $TargetDirUser)
        {
            Write-Log -Message "Removing User Settings configuration folder $TargetDirUser" -Source ${CmdletName}
            Remove-FolderAndEmptyParents -Path $TargetDirUser -ParentHeight 2
        }
        Else
        {
            Write-Log -Message "UserSettings Configuration folder $TargetDirUser not found." -Source ${CmdletName}
        }
		Write-Log -Message "Finished User Setting Deployment Removal for $Name" -Source ${CmdletName}

    }
    End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Copy-FileEx
Function Copy-FileEx {
<#
.SYNOPSIS
	Copy a file or group of files to a destination path. This function is a copy of the Copy-File function in AppDeployToolkitMain. With the added parameter to control the destinationtype.
    The original Copy-File function detects the destination type based on whether or not is has a (filetype) extention. But a folder can also have an extension (meaning it can contain a '.' in it's name) so the orginal function does not work correctly in that case.
    In the case the destination is a folder containing a '.' in it's name the orginal Copy-File function does not create the destination folder if it does not exist, which leads to incorrect recusive copying. Copy-FileEx solves this issue.
.DESCRIPTION
	Copy a file or group of files to a destination path.
.PARAMETER Path
	Path of the file to copy.
.PARAMETER Destination
	Destination Path of the file to copy.
.PARAMETER Recurse
	Copy files in subdirectories.
.PARAMETER Flatten
	Flattens the files into the root destination directory.
.PARAMETER DestinationType
    Specifies the type of destination. Default is: Detect. Options: Detect = Detect destination type based on wheter of not is has an file-extension. If so destination type is assumed to be a file, if not a directory. Options: Detect = Detect destionation type, File = Destination type is a file, Folder = Destination type is a folder. 
.PARAMETER ContinueOnError
	Continue if an error is encountered. This will continue the deployment script, but will not continue copying files if an error is encountered. Default is: $true.
.PARAMETER ContinueFileCopyOnError
	Continue copying files if an error is encountered. This will continue the deployment script and will warn about files that failed to be copied. Default is: $false.
.EXAMPLE
	Copy-FileEx -Path "$dirSupportFiles\MyApp.ini" -Destination "$envWindir\MyApp.ini"
.EXAMPLE
	Copy-FileEx -Path "$dirSupportFiles\*.*" -Destination "$envTemp\tempfiles"
	Copy all of the files in a folder to a destination folder.
.EXAMPLE
	Copy-FileEx -Path "$dirSupportFiles\*.*" -Destination "$envTemp\tempfiles.001" -DestinationType Folder
	Copy all of the files in a folder to a destination folder.
.NOTES
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string[]]$Path,
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Destination,
		[Parameter(Mandatory=$false)]
		[switch]$Recurse = $false,
		[Parameter(Mandatory=$false)]
		[switch]$Flatten,
	    [Parameter(Mandatory=$false)]
	    [ValidateSet('Detect','File','Folder')]
	    [string]$DestinationType = 'Detect',
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true,
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueFileCopyOnError = $false
	)

	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			$null = $fileCopyError
            

    	    If ($DestinationType -eq "Detect")
            {
                If((-not ([IO.Path]::HasExtension($Destination))))
                {$DestinationType = "Folder"}
                Else
                {$DestinationType = "File"}
                Write-Log -Message "Destination type detected as '$Destinationtype'." -Source ${CmdletName}
            }
       
			If (($DestinationType -eq "Folder") -and (-not (Test-Path -LiteralPath $Destination -PathType 'Container'))){
				Write-Log -Message "Destination folder does not exist, creating destination folder [$destination]." -Source ${CmdletName}
				$null = New-Item -Path $Destination -Type 'Directory' -Force -ErrorAction 'Stop'
			}

			if ($Flatten) {
				If ($Recurse) {
					Write-Log -Message "Copy file(s) recursively in path [$path] to destination [$destination] root folder, flattened." -Source ${CmdletName}
					If (-not $ContinueFileCopyOnError) {
						$null = Get-ChildItem -Path $path -Recurse | Where-Object {!($_.PSIsContainer)} | ForEach-Object {
							Copy-Item -Path ($_.FullName) -Destination $destination -Force -ErrorAction 'Stop'
						}
					}
					Else {
						$null = Get-ChildItem -Path $path -Recurse | Where-Object {!($_.PSIsContainer)} | ForEach-Object {
							Copy-Item -Path ($_.FullName) -Destination $destination -Force -ErrorAction 'SilentlyContinue' -ErrorVariable FileCopyError
						}
					}
				}
				Else {
					Write-Log -Message "Copy file in path [$path] to destination [$destination]." -Source ${CmdletName}
					If (-not $ContinueFileCopyOnError) {
						$null = Copy-Item -Path $path -Destination $destination -Force -ErrorAction 'Stop'
					}
					Else {
						$null = Copy-Item -Path $path -Destination $destination -Force -ErrorAction 'SilentlyContinue' -ErrorVariable FileCopyError
					}
				}
			}
			Else {
				$null = $FileCopyError
				If ($Recurse) {
					Write-Log -Message "Copy file(s) recursively in path [$path] to destination [$destination]." -Source ${CmdletName}
					If (-not $ContinueFileCopyOnError) {
						$null = Copy-Item -Path $Path -Destination $Destination -Force -Recurse -ErrorAction 'Stop'
					}
					Else {
						$null = Copy-Item -Path $Path -Destination $Destination -Force -Recurse -ErrorAction 'SilentlyContinue' -ErrorVariable FileCopyError
					}
				}
				Else {
					Write-Log -Message "Copy file in path [$path] to destination [$destination]." -Source ${CmdletName}
					If (-not $ContinueFileCopyOnError) {
						$null = Copy-Item -Path $Path -Destination $Destination -Force -ErrorAction 'Stop'
					}
					Else {
						$null = Copy-Item -Path $Path -Destination $Destination -Force -ErrorAction 'SilentlyContinue' -ErrorVariable FileCopyError
					}
				}
			}

			If ($fileCopyError) {
				Write-Log -Message "The following warnings were detected while copying file(s) in path [$path] to destination [$destination]. `n$FileCopyError" -Severity 2 -Source ${CmdletName}
			}
			Else {
				Write-Log -Message "File copy completed successfully." -Source ${CmdletName}
			}
		}
		Catch {
			Write-Log -Message "Failed to copy file(s) in path [$path] to destination [$destination]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to copy file(s) in path [$path] to destination [$destination]: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Remove-FolderAndEmptyParents
Function Remove-FolderAndEmptyParents {
<#
.SYNOPSIS
	Remove the specified folder recusively and also remove its parents, when empty, to the specified height.
.DESCRIPTION
	Remove the specified folder recusively and also remove its parents, when empty, to the specified height.
.PARAMETER Path
	Path of folder to remove.
.PARAMETER ParentHeight
	The height to which the parents of the folder should be removed if they are empty. Default = 1
.EXAMPLE
	Remove-FolderAndEmptyParents -Path "C:\Program Files\Manufacturer\ApplicationName" -ParentHeight 1
	Removes the folder "C:\Program Files\Manufacturer\ApplicationName" and it's contents. Also removes the folder "C:\Program Files\Manufacturer" if it is empty after removing the "ApplicationName" subfolder.
.NOTES
    The parameter 'Inloop' is only for internal use.
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Path,
	    [Parameter(Mandatory=$false)]
	    [Int32]$ParentHeight = 1,
		[Parameter(Mandatory=$false)]
		[switch]$InLoop = $false
	)

	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		If ($InLoop -eq $false){
			Write-Log -Message "Removing the folder $Path and it's empty parents to a maximum height of $ParentHeight" -Source ${CmdletName}
		}
		Remove-Folder -Path $Path 
		If ($ParentHeight -gt 0){
			$NewParentHeight = $ParentHeight - 1
			$ParentPath = Split-Path $Path
			If ($(Get-ChildItem -Path $ParentPath).Count -eq 0){
				Remove-FolderAndEmptyParents -Path $ParentPath -ParentHeight $NewParentHeight -InLoop
			}
			Else{
				Write-Log -Message "Parent folder $ParentPath is not empty. Stopping removal of parents." -Source ${CmdletName}
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Remove-EnvironmentVariable
Function Remove-EnvironmentVariable {
<#
.SYNOPSIS
	Remove an Environment variable.
.DESCRIPTION
	Remove an Environment variable.
.PARAMETER Name
	Name of the environment variable to Remove.
.PARAMETER Type
    User or Machine. Default is Machine
.EXAMPLE
	Remove system environment variable: Remove-EnvironmentVariable -Name "TEST"
    Remove user environment variable: Remove-EnvironmentVariable -Name "TEST" -Type User
.NOTES
    
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Name,
		[Parameter(Mandatory=$false)]
        [ValidateSet('User','Machine')]
		[String]$Type = 'Machine'
	)

    Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
        [Environment]::SetEnvironmentVariable($Name,$null,$Type)
        $Result= [Environment]::GetEnvironmentVariable($Name, $Type)
        If (!$Result) {
            Write-Log -Message "Succesfully Removed $Name"  -Source ${CmdletName}
        }
        Else {
            Write-Log -Message "Failed to Remove $Name"  -Source ${CmdletName}
            Write-Log -Message "$Name = $Result"  -Source ${CmdletName}
        }

    }
    	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}

#endregion

#region Function Set-EnvironmentVariable
Function Set-EnvironmentVariable {
<#
.SYNOPSIS
	Set an Environment variable.
.DESCRIPTION
	Set an Environment variable.
.PARAMETER Name
	Name of the environment variable to set.
.PARAMETER Value
	Value of the Environment variable to set
.PARAMETER Type
    User or Machine. Default is Machine
.PARAMETER Append
    First or Last. Default is Last. If the parameter is omitted then de current value of the variable will be replaced. Fs the variable does not exists is it will be created with the supplied value.
.PARAMETER Delimiter
    Delimiter used for appending Value to the current value of the variable. Default is ";". "" can also be applied.
.PARAMETER Subtract
    Switch parameter used to indicate that the supplied value has to be subtracted from the value of the supplied environment variable. If both the append and subtract parameters are supplied, the subtract parameter is ignored.
.EXAMPLE
	Set New variable of change existing variable: Set-EnvironmentVariable -Name "TEST" -Value "Test"
    Append String to end of existing variable: Set-EnvironmentVariable -Name "PATH" -Value "C:\Path" -Append LastIfNotExists
    Append String to beginning of existing variable: Set-EnvironmentVariable -Name "PATH" -Value "C:\Path" -Append FirstIfNotExists
.NOTES
    
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Name,
	    [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
	    [String]$Value,
		[Parameter(Mandatory=$false)]
        [ValidateSet('User','Machine')]
		[String]$Type = 'Machine',
        [Parameter(Mandatory=$false)]
        [ValidateSet('First','FirstIfNotExists','Last','LastIfNotExists')]
		[String]$Append = 'LastIfNotExists',
        [Parameter(Mandatory=$false)]
		[String]$Delimiter = ';',
        [Parameter(Mandatory=$false)]
		[switch]$Subtract = $false
	)

	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
        $CurrentEnvValue = [Environment]::GetEnvironmentVariable($Name, $Type)
        $DoAppend = $PSBoundParameters.ContainsKey('Append')
        If ((!$DoAppend -or !$CurrentEnvValue) -and !$Subtract) {
            If ($CurrentEnvValue){
                Write-Log "$Type Environment Variable $Name already exists with value $CurrentEnvValue."
            }
            Write-Log "Setting $Type Environment Variable $Name with value $Value."  -Source ${CmdletName}
            [Environment]::SetEnvironmentVariable($Name, $Value, $Type)
            $NewEnvValue = [Environment]::GetEnvironmentVariable($Name, $Type)
            If ("$NewEnvValue" -eq $Value) {
                            Write-Log -Message "Succesfully set $Name"  -Source ${CmdletName}
                        }
                        Else {
                            Write-Log -Message "Failed to update $Name"  -Source ${CmdletName}
                            Write-Log -Message "$Name = $NewEnvValue"  -Source ${CmdletName}
                        }
        }

        If ($DoAppend) {
            Switch ($Append) {
                "First"{
                    Write-Log -Message "Appending '$value' to beginning of $Name environment variable with delimiter '$Delimiter'." -Source ${CmdletName}
                    Write-Log -Message "Current value of $Name is:  $CurrentEnvValue" -Source ${CmdletName}
                    [Environment]::SetEnvironmentVariable($Name, "$Value$Delimiter$CurrentEnvValue", $Type)
                    $NewEnvValue = [Environment]::GetEnvironmentVariable($Name, $Type)
                    If ("$Value$Delimiter$CurrentEnvValue" -eq $NewEnvValue) {
                        Write-Log -Message "Succesfully Updated $Name"  -Source ${CmdletName}
                    }
                    Else {
                        Write-Log -Message "Failed to Update $Name"  -Source ${CmdletName}
                        Write-Log -Message "$Name = $NewEnvValue"  -Source ${CmdletName}
                    }
                }
                "FirstIfNotExists" {
                    Write-Log -Message "Current value of $Name is:  $CurrentEnvValue" -Source ${CmdletName}
                    If (($CurrentEnvValue -Like "$Value$Delimiter*") -Or ($CurrentEnvValue -Like "*$Delimiter$Value") -Or ($CurrentEnvValue -Like "*$Delimiter$Value$Delimiter*") -Or ($CurrentEnvValue -eq $Value)) {
                        Write-Log -Message "$Value already occurs in $Name. Skipping update." -Source ${CmdletName}
                    }
                    Else {
                        Write-Log -Message "Appending '$value' to beginning of $Name with delimiter '$Delimiter' if $value does not already exist in $Name." -Source ${CmdletName}
                        [Environment]::SetEnvironmentVariable($Name, "$Value$Delimiter$CurrentEnvValue", $Type)
                        $NewEnvValue = [Environment]::GetEnvironmentVariable($Name, $Type)
                        If ("$Value$Delimiter$CurrentEnvValue" -eq $NewEnvValue) {
                            Write-Log -Message "Succesfully Updated $Name"  -Source ${CmdletName}
                        }
                        Else {
                            Write-Log -Message "Failed to Update $Name"  -Source ${CmdletName}
                            Write-Log -Message "$Name = $NewEnvValue"  -Source ${CmdletName}
                        }
                    }
                }
                "Last"{
                    Write-Log -Message "Appending '$value' to end of $Name environment variable with delimiter '$Delimiter'." -Source ${CmdletName}
                    Write-Log -Message "Current value of $Name is:  $CurrentEnvValue" -Source ${CmdletName}
                    [Environment]::SetEnvironmentVariable($Name, "$CurrentEnvValue$Delimiter$Value", $Type)
                    $NewEnvValue = [Environment]::GetEnvironmentVariable($Name, $Type)
                    If ("$CurrentEnvValue$Delimiter$Value" -eq $NewEnvValue) {
                        Write-Log -Message "Succesfully Updated $Name"  -Source ${CmdletName}
                    }
                    Else {
                        Write-Log -Message "Failed to Update $Name"  -Source ${CmdletName}
                        Write-Log -Message "$Name = $NewEnvValue"  -Source ${CmdletName}
                    }
                }
                "LastIfNotExists" {
                    Write-Log -Message "Current value of $Name is:  $CurrentEnvValue" -Source ${CmdletName}
                    If (($CurrentEnvValue -Like "$Value$Delimiter*") -Or ($CurrentEnvValue -Like "*$Delimiter$Value") -Or ($CurrentEnvValue -Like "*$Delimiter$Value$Delimiter*") -Or ($CurrentEnvValue -eq $Value)) {
                        Write-Log -Message "$Value already occurs in $Name. Skipping update." -Source ${CmdletName}
                    }
                    Else {
                        Write-Log -Message "Appending '$value' to end of $Name with delimiter '$Delimiter' if $value does not already exist in $Name." -Source ${CmdletName}
                        [Environment]::SetEnvironmentVariable($Name, "$CurrentEnvValue$Delimiter$Value", $Type)
                        $NewEnvValue = [Environment]::GetEnvironmentVariable($Name, $Type)
                        If ("$CurrentEnvValue$Delimiter$Value" -eq $NewEnvValue) {
                            Write-Log -Message "Succesfully Updated $Name"  -Source ${CmdletName}
                        }
                        Else {
                            Write-Log -Message "Failed to Update $Name"  -Source ${CmdletName}
                            Write-Log -Message "$Name = $NewEnvValue"  -Source ${CmdletName}
                        }
                    }
                }
            }
        }
        ElseIf ($Subtract) {            
            If ($Delimiter -eq ""){
                Write-Log -Message "No delimiter supplied. Removing all occurences of the string '$value' from the value of $Name." -Source ${CmdletName}
                $ValueToSet = $CurrentEnvValue.replace($Value, "")
                [Environment]::SetEnvironmentVariable($Name, $ValueToSet, $Type)
            }
            Else {
                Write-Log -Message "Removing all ocurrences of '$value' from the value of $Name using delimiter '$Delimiter'." -Source ${CmdletName}
                $arrEnvParts = $CurrentEnvValue.Split($Delimiter)
                $arrEnvParts = $arrEnvParts -ne $Value
                $ValueToSet = $arrEnvParts -join $Delimiter
                [Environment]::SetEnvironmentVariable($Name, $ValueToSet, $Type)
            }
            $NewEnvValue = [Environment]::GetEnvironmentVariable($Name, $Type)
            If ($ValueToSet -eq $NewEnvValue) {
                Write-Log -Message "Succesfully Updated $Name"  -Source ${CmdletName}
            }
            Else {
                Write-Log -Message "Failed to Update $Name"  -Source ${CmdletName}
                Write-Log -Message "$Name = $NewEnvValue"  -Source ${CmdletName}
            }
        }
    }
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

Function Execute-InnoSetup {
<#
.SYNOPSIS
    Executes the supplied Inno Setup executable to perform the following actions for Inno Setup files: install, uninstall.
.DESCRIPTION
    Executes the supplied Inno Setup executable to perform the following actions for Inno Setup files: install, uninstall.
    Can also perform an uninstall based on the Inno Setup Uninstall Id. 
    The Inno Setup Uninstall Id is the name of the name of the key under HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall.
    The Inno Setup Uninstall Id always ends with '_is1'
    Sets default parameters to be passed to the Inno Setup executable. 
    Default silent install/uninstall is: '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART'. 
    Default non silent is: '/SILENT /NOCANCEL /SUPPRESSMSGBOXES /NORESTART'.
    Automatically generates a log file name and creates a log file for the Inno Setup, unless the '-Parameters' is used or the /LOG parameter is supplied in the '-AddParameters' parameter.
    Expects the Inno Setup executable file to be located in the "Files" sub directory of the App Deploy Toolkit. 
    Expects INF files to be in the same directory as the Inno Setup file.
.PARAMETER Action
    The action to perform. Options: Install, Uninstall.
    If the option is Uninstall and the Inno Setup Uninstall Id is used for the '-Path' parameter, a check is done the see if the application is installed before uninstalling.
    An Inno Setup Uninstall Id can only be used for an Uninstall action.
.PARAMETER Path
    The path to the Inno Setup file, Uninstall executable or the Inno Setup Uninstall Id. 
    If the '-Action' parameter is Uninstall and the Inno Setup Uninstall Id is used, a check is done the see if the application is installed before uninstalling. If it is not installed the Uninstall action is skipped without raising an error.
    No check is possible to see is the supplied exe is actualy an Inno Setup executable.
.PARAMETER InfFile
    The name of the .inf file(s) to be applied to the Inno Setup executable. The inf file is expected to be in the same directory as the Inno Setup executable.
.PARAMETER Parameters
    Overrides the default parameters. Default silent install/uninstall is: '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART'. Default non silent is: '/SILENT /SUPPRESSMSGBOXES /NORESTART'.
    The '-InfFile' parameter is not available, so the INF file should be set manualy using the Inno Setup parameter /LOADINF="<InfFile>" if needed.
    Logging is not automaticaly enabled and the '-LogName' parameter is not available, so logging should be manualy set with using the Inno Setup parameter /LOG="<logfile>" if needed.
    See https://jrsoftware.org/ishelp/index.php?topic=setupcmdline for all available Inno Setup parameters.
.PARAMETER AddParameters
    Allows for adding extra Inno Setup parameters to the default parameters. Default silent install/uninstall is: '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART'. Default non silent is: '/SILENT /SUPPRESSMSGBOXES /NORESTART'.
    See https://jrsoftware.org/ishelp/index.php?topic=setupcmdline for all available Inno Setup parameters.
.PARAMETER LogName
    Overrides the default log file name. The default log file name is generated from the Package Install name and the Inno Setup executable name. If LogName does not end in .log, it will be automatically appended.
    If the Inno Setup parameter /LOG had been used in the '-AddParameters' parameter the '-LogName' parameter is ignored. 
.PARAMETER WorkingDirectory
    Overrides the working directory. The working directory is set to the location of the Inno Setup file.
.PARAMETER NoWait
    Immediately continue after executing the process.
.PARAMETER PassThru
    Returns ExitCode, STDOut, and STDErr output from the process.
.PARAMETER IgnoreExitCodes
    List the exit codes to ignore or * to ignore all exit codes.
.PARAMETER PriorityClass	
    Specifies priority class for the process. Options: Idle, Normal, High, AboveNormal, BelowNormal, RealTime. Default: Normal
.PARAMETER ExitOnProcessFailure
    Specifies whether the function should call Exit-Script when the process returns an exit code that is considered an error/failure. Default: $true
.PARAMETER ContinueOnError
    Continue if an error occured while trying to start the process. Default: $false.
.EXAMPLE
    Execute-InnoSetup -Path 'Git-2.35.1.2-64-bit.exe'
    Installs an Inno Setup executable using the default installation parameters. 
.EXAMPLE
    Execute-InnoSetup -Action 'Install' -Path 'Git-2.35.1.2-64-bit.exe' -InfFile 'GitSetup.inf'
    Installs an Inno Setup executable, applying a installation settings file.
.EXAMPLE
    [psobject]$InnoSetupResult = Execute-InnoSetup -Action 'Install' -Path 'Git-2.35.1.2-64-bit.exe' -PassThru
    Installs an Inno Setup executable and stores the result of the execution into a variable by using the -PassThru option
.EXAMPLE
    Execute-InnoSetup -Action 'Uninstall' -Path 'Git_is1'
    Uninstalls an Inno Setup application using an Uninstall Id. This Id is the relevant key located in HKLM\SOFTWARE(\WOW6432Node)\Microsoft\Windows\CurrentVersion\Uninstall
.EXAMPLE
    Execute-InnoSetup -Path 'Git-2.35.1.2-64-bit.exe' -AddParameters '/DIR="C:\Program files\CustomGitDir"'
    Installs an Inno Setup executable using the default installation parameters and adding the parameter to install the application in the "C:\Program files\CustomGitDir" directory. 
.EXAMPLE
    Execute-InnoSetup -Path 'Git-2.35.1.2-64-bit.exe' -Parameters '/SILENT /NOICONS /DIR="C:\Program files\CustomGitDir" /LOG="C:\Temp\Setup.log"'
    Installs an Inno Setup executable using full custom command line parameters. 
.NOTES
.LINK
    http://psappdeploytoolkit.com
#>
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    Param (
        [Parameter(Mandatory=$false)]
        [ValidateSet('Install','Uninstall')]
        [string]$Action = 'Install',
        [Parameter(Mandatory=$true, HelpMessage='Please enter either the path to the Inno Setup file, Uninstall Exe or the InnoSetup Uninstall Id')]
        [ValidateScript({($_ -match ".+_is1$") -or ('.exe' -contains [IO.Path]::GetExtension($_))})]
        [Alias('FilePath')]
        [string]$Path,
        [Parameter(Mandatory=$false, ParameterSetName = "Default")]
        [ValidateNotNullorEmpty()]
        [string]$InfFile,
        [parameter(Mandatory = $false, ParameterSetName = "Custom")]
        [Alias('Arguments')]
        [ValidateNotNullorEmpty()]
        [string]$Parameters,
        [Parameter(Mandatory=$false, ParameterSetName = "Default")]
        [ValidateNotNullorEmpty()]
        [string]$AddParameters,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [switch]$SecureParameters = $false,
        [Parameter(Mandatory=$false, ParameterSetName = "Default")]
        [Alias('LogName')]
        [string]$private:LogName,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [string]$WorkingDirectory,
        [Parameter(Mandatory=$false)]
        [switch]$NoWait = $false,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [switch]$PassThru = $false,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [string]$IgnoreExitCodes,
        [Parameter(Mandatory=$false)]
        [ValidateSet('Idle', 'Normal', 'High', 'AboveNormal', 'BelowNormal', 'RealTime')]
        [Diagnostics.ProcessPriorityClass]$PriorityClass = 'Normal',
        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [boolean]$ExitOnProcessFailure = $true,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [boolean]$ContinueOnError = $false
    )

    Begin {
        ## Get the name of this function and write header
        [string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
    }
    Process {
        ## Define the default Parameters for Install and Uninstall, Log File paramter will be added later.
        If ($deployModeSilent) {
            $InnoInstallDefaultParams = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"
            $InnoUninstallDefaultParams = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"
        }
        Else {
            $InnoInstallDefaultParams = "/SILENT /NOCANCEL /SUPPRESSMSGBOXES /NORESTART"
            $InnoUninstallDefaultParams = "/SILENT /NOCANCEL /SUPPRESSMSGBOXES /NORESTART"
        }

        Switch ($Action) {
            "Install" {
                If ($Path -Match ".+_is1$") {
                    Write-Log -Message "Uninstall Id [$Path] passed for Install action. An Uninstall Id can only be supplied for an Uninstall actions." -Severity 3 -Source ${CmdletName}
                    If (-not $ContinueOnError) {
                        Throw "Failed to execute Inno Setup [$Path]."
                    }
                    Continue
                }
                $ExePath = $Path
                # Build the log file path
                If (!$LogName){
                    $LogName = "$($InstallName)_$(Split-Path -Path $Path -Leaf).log"
                }
                ElseIf ('.log','.txt' -notcontains [IO.Path]::GetExtension($logName)){
                    $LogName = "$LogName.log"
                }

                #Set default parameters
                $DefaultParameters = $InnoInstallDefaultParams
            }
            "Uninstall" {
                If ($Path -Match ".+_is1$"){
                    $ExePath = Get-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$Path" -Value "UninstallString"
                    If (!$ExePath) {
                        $ExePath = Get-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$Path" -Value "UninstallString"
                    }
                    If (!$ExePath) {
                        $AppInstalled = $False
                        Break
                    }
                    Else {
                        $AppInstalled = $True
                        $ExePath = $ExePath.Replace('"', '')
                    }
                }
                else {
                    #If the Inno Setup Uninstall Id had not been used for the '-Path' parameter the application is considered installed because it can not be checked.
                    $AppInstalled = $True
                    $ExePath = $Path
                }

                # Build the log file path
                If (!$LogName){
                    $LogName = "$($InstallName)_$(Split-Path -Path $ExePath -Leaf).log"
                }
                ElseIf ('.log','.txt' -notcontains [IO.Path]::GetExtension($logName)){
                    $LogName = "$LogName.log"
                }

                #Set default parameters
                $DefaultParameters = $InnoUninstallDefaultParams
            }
        }

        If (!($Action -eq "Uninstall") -or ($Action -eq "Uninstall" -and $AppInstalled)) { 
            ## If the Inno Setup Executable is in the Files directory, set the full path to the EXE.
            If (Test-Path -LiteralPath (Join-Path -Path $dirFiles -ChildPath $ExePath -ErrorAction 'SilentlyContinue') -PathType 'Leaf' -ErrorAction 'SilentlyContinue') {
                [string]$InnoFile = Join-Path -Path $dirFiles -ChildPath $ExePath
            }
            ElseIf (Test-Path -LiteralPath $ExePath -ErrorAction 'SilentlyContinue') {
                [string]$InnoFile = (Get-Item -LiteralPath $ExePath).FullName
            }
            Else {
                Write-Log -Message "Failed to find Inno Setup executable file [$ExePath]." -Severity 3 -Source ${CmdletName}
                If (-not $ContinueOnError) {
                    Throw "Failed to find Inno Setup executable file [$ExePath]."
                }
                Continue
            }

            If ($configToolkitCompressLogs) {
                ## Build the log file path
                [string]$logPath = Join-Path -Path $logTempFolder -ChildPath $logName
            }
            Else {
                ## Create the Log directory if it doesn't already exist
                If (-not (Test-Path -LiteralPath $configToolkitLogDir -PathType 'Container' -ErrorAction 'SilentlyContinue')) {
                    $null = New-Item -Path $configToolkitLogDir -ItemType 'Directory' -ErrorAction 'SilentlyContinue'
                }
                ## Build the log file path
                [string]$logPath = Join-Path -Path $configToolkitLogDir -ChildPath $logName
            }

            #Set final Parameters
            If (!$Parameters) {
                $InnoSetupParameters = $DefaultParameters
                If ($InfFile) {
                    $InnoSetupParameters = "$InnoSetupParameters /LOADINF=""$InfFile"""
                }
                If ($AddParameters) {
                    $InnoSetupParameters = "$InnoSetupParameters $AddParameters"
                }
                #Add logfile parameter if not already present (by the $AddParameters parameter).
                If ($InnoSetupParameters -notlike "*/LOG=*"){
                    $InnoSetupParameters = "$InnoSetupParameters /LOG=""$logPath""" 
                }
            }
            else {
                $InnoSetupParameters = $Parameters
            }
        
            Write-Log -Message "Executing Inno Setup action [$Action]..." -Source ${CmdletName}
            #  Build the hashtable with the options that will be passed to Execute-Process using splatting
            [hashtable]$ExecuteProcessSplat =  @{
                Path = $InnoFile
                Parameters = $InnoSetupParameters
                WindowStyle = 'Normal'
                ExitOnProcessFailure = $ExitOnProcessFailure
                ContinueOnError = $ContinueOnError
                PriorityClass = $PriorityClass
            }
            If ($WorkingDirectory) { $ExecuteProcessSplat.Add( 'WorkingDirectory', $WorkingDirectory) }
            If ($SecureParameters) { $ExecuteProcessSplat.Add( 'SecureParameters', $SecureParameters) }
            If ($PassThru) { $ExecuteProcessSplat.Add( 'PassThru', $PassThru) }
            If ($IgnoreExitCodes) {  $ExecuteProcessSplat.Add( 'IgnoreExitCodes', $IgnoreExitCodes) }
            If ($NoWait) { $ExecuteProcessSplat.Add( 'NoWait', $NoWait) }

            #  Call the Execute-Process function
            If ($PassThru) {
                [psobject]$ExecuteResults = Execute-Process @ExecuteProcessSplat
            }
            Else {
                Execute-Process @ExecuteProcessSplat
            }
        }
        Else {
            Write-Log -Message "The Inno Setup with Uninstall Id '$Path' is not installed on this system. Skipping action [$Action]..." -Source ${CmdletName}
        }
    }
    End {
        If ($PassThru) { Write-Output -InputObject $ExecuteResults }
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
    }
}
#endregion

#region Function RunInOSbitMode
Function RunInOSbitMode {
<#
.SYNOPSIS
	Check if Script is running in the same bit mode as the OS. If running in 32bit mode on a 64bit system the script will be relaunched in 64bit mode.
.DESCRIPTION
	Check if Script is running in the same bit mode as the OS. If running in 32bit mode on a 64bit system the script will be relaunched in 64bit mode.
    This is required when using the AppDeploy Toolkit to install from Intune.
    Various functions in the toolkit may not work if running in 32bit mode on a 64bit system because calls to the registry are then only done to the 32bit registry.
    This will for instance cause a failure to detect installed 64bit applications
.EXAMPLE
	RunInOSbitMode
.LINK
	http://psappdeploytoolkit.com

.NOTES
    Author:      Casper van der Kooij
    Created:     2020-07-28
    Updated:     2020-10-06

    Version history:
    1.0.0 - (2020-07-28) Function created
    1.0.1 - (2020-10-06) Improved logging
#>

    If ($ENV:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
        Write-Log -Message "Running in 32-bit mode on 64bit system. Switching to 64-bit mode." -Severity 2 -Source "RunInOSbitMode"
        Try {
            $Params = "-File ""$($InvocationInfo.MyCommand.Definition)"""
            foreach($key in $InvocationInfo.BoundParameters.keys) {
                If ($InvocationInfo.BoundParameters[$key].GetType().Name -eq "SwitchParameter") {
                    $Params = "$Params -$key"
                }
                Else {
                    $Params = "$Params -$key $($InvocationInfo.BoundParameters[$key])"
                }
            }
            $Process = Start-Process -FilePath "$ENV:WINDIR\SysNative\WindowsPowershell\v1.0\PowerShell.exe" -ArgumentList $Params -Wait -NoNewWindow -PassThru
        }
        Catch {
            Throw "Failed to start $($InvocationInfo.MyCommand.Definition)"
        }
        Write-Log -Message "Exiting 64-bit session and returning exitcode: $($Process.ExitCode)" -Source "RunInOSbitMode"
        Exit-Script -ExitCode $Process.ExitCode
    }
    ElseIf ($ENV:PROCESSOR_ARCHITECTURE -eq "AMD64") {
        Write-Log -Message "Running in 64-bit mode on 64-bit system. Let's continue." -Source "RunInOSbitMode"
    }
    Else {
        Write-Log -Message "Running in 32-bit mode on 32-bit system. Let's continue." -Source "RunInOSbitMode"
    }
}

#endregion Function RunInOSbitMode

#region Get-WGInstalledApp Function
Function Get-WinGetInstalledApp {
	<#
	.SYNOPSIS
		Gets information about a WinGet Installed App.
	.DESCRIPTION
		Gets information about a WinGet Installed App.
	.PARAMETER Id
		WinGet Id of the app (case sensitive).
	.PARAMETER Source
		Source of the App. Either 'winget' or 'msstore'. DeFault ''winget'.
	.EXAMPLE
		Get-WinGetInstalledApp -Id 'Zoom.Zoom'
			Gets information about the Zoom
	.NOTES
		Author:      Casper van der Kooij
		Created:     05-sep-2023
		Updated:     05-sep-2023

		Version history:
		0.5.0 - (05-sep-2023) Function created/updated 

	.LINK
		http://psappdeploytoolkit.com
	#>
	[Alias("Get-WGInstalledApp")]
	[cmdletbinding()]
    Param(
        [Parameter(Mandatory=$true, HelpMessage = 'Enter the WinGet Id of the application (case sensitive).')]
        [ValidateNotNullorEmpty()]
        [string]$Id,
		[Parameter(Mandatory=$false, HelpMessage = "Enter the installation source of the application, winget or msstore.")]
		[ValidateSet('winget','msstore')]
		$Source='winget'
    )
	Write-Verbose "Executing: Winget.exe list --id $id --exact --accept-source-agreements --source $Source"
	$WinGetResult = Execute-WinGet -Raw "list --id $id --exact --accept-source-agreements --source $Source" -PassThru -IgnoreExitCodes *
	Write-Verbose 'WinGet execution completed.'
	
    #create output object
	$WGAppObj = New-Object -TypeName psobject
	$WGAppObj | Add-Member -MemberType NoteProperty -Name 'WGExitCode' -Value $WinGetResult.ExitCode

	If ($WinGetResult.ExitCode -eq -1978335212){
		$WGAppObj | Add-Member -MemberType NoteProperty -Name 'Installed' -Value 'No'
	}
	ElseIf ($WinGetResult.ExitCode -eq 0) {
		Write-Verbose 'Converting WinGet output to powershell object.'
        #Get the StdOut from the WinGet execution, split the lines and remove unwanted lines, Should end up with 2 lines, a header and a data line.
		$ResultLines = $WinGetResult.StdOut.Split([System.Environment]::NewLine,[System.StringSplitOptions]::RemoveEmptyEntries) | Where-Object {($_ -notlike ' *') -and ($_ -notlike '-------*')}
		#Find the line containing the headers
        $HeaderIndex = 0..($ResultLines.Count-1) | Where-Object {$ResultLines[$_] -like 'Name*'}
		If ($HeaderIndex -eq $null) {
			$WGAppObj | Add-Member -MemberType NoteProperty -Name 'Installed' -Value 'Unknown'
		}
		Else {
			$WGAppObj | Add-Member -MemberType NoteProperty -Name 'Installed' -Value 'Yes'
            #Find the line containing the Data
            #Sometimes the StdOut of the WinGet execution gets scrambled causing the header line to be below the data line.
            #Check is this is the case, and if so accommodate.
			If ($HeaderIndex -eq $ResultLines.Count-1){
				$DataIndex = $HeaderIndex - 1
			}
			Else {
				$DataIndex = $HeaderIndex + 1
			}

			$HeaderLine = $ResultLines[$HeaderIndex]
			$DataLine = $ResultLines[$DataIndex]
            #Create array with individual headers
			$ArrHeaders = $HeaderLine.Split(' ',[System.StringSplitOptions]::RemoveEmptyEntries)
			$StartPos = 0
			#Get data belonging to header based on the starting position of the next header
            For ($i=1; $i -lt $ArrHeaders.Count; $i++){
				$EndPos = $HeaderLine.IndexOf($ArrHeaders[$i])
				$Name = $ArrHeaders[$i-1]
				$Data = $($DataLine.SubString($StartPos, $EndPos - $StartPos)).Trim()
				$WGAppObj | Add-Member -MemberType NoteProperty -Name $Name -Value $Data
				$StartPos = $HeaderLine.IndexOf($ArrHeaders[$i])
			}
            #Add item to output object
			$WGAppObj | Add-Member -MemberType NoteProperty -Name $ArrHeaders[$i-1] -Value $($DataLine.SubString($StartPos, $DataLine.Length - $StartPos)).Trim()
		}
	}
	Else {
		$WGAppObj | Add-Member -MemberType NoteProperty -Name 'Installed' -Value 'Unknown'
	}
    #Return Output object
	$WGAppObj
}
#endregion Get-WGInstalledApp Function

#region Execute-WinGet Function
Function Execute-WinGet {
	<#
	.SYNOPSIS
		Executes WinGet to Install or Uninstall an application from the WinGet repository.
	.DESCRIPTION
		Executes WinGet to Install or Uninstall an application from the WinGet repository.
		WinGet has to be installed on the system.
		If an older version of the application is already present when running this function with the 'Install' action, the application will be upgraded.
		For all application installed using this function Auto Upgrade will be enabled (The NoAutoUpgrade parameter is specified or the version parameter is used or the application is installed per-user).
		For the Auto Upgrade the application will be registered for upgrade in the registry and a scheduled task is created (if not already present) that wil upgrade
		the registered applications on a weekly basis (if an upgrade is available).
	.PARAMETER Action
		The action to perform. Options: Install, Uninstall.
	.PARAMETER Id
		The WinGet Id of the application (case sensitive) to Install or Uninstall.
	.PARAMETER Version
		The WinGet Version of the application to Install or Uninstall. If not specified, the highest installed version will be (un)installed.
	.PARAMETER Custom
		A string of parameters that will be passed directly to the installer and is added to the default parameters. For instance to add specific Properties or an Mst to the MSI installer. Only Valid for the install action.
	.PARAMETER Override
		A string of parameters that will be passed directly to the installer, replacing any default parameters. For instance to specify specific Properties or an Mst to the MSI installer. Only Valid for the install action.
	.PARAMETER Scope
		Allows you to specify if the installer should target user or machine scope. Default is machine. If running in system context machine scope is forced.
	.PARAMETER InstallDir
		Location to install to (if supported by the installer).
	.PARAMETER UninstallCurrentVersion
		Specify to first remove any current installation of the application before running the install. This will allow downgrading to a lower version of the application.
	.PARAMETER Force
		Forces the install to run when the application is already installed even when no newer version is available. Combine with UninstallCurrentVersion to perform a reinstall.
	# .PARAMETER NoAutoUpdate
	# 	Prevents Auto Upgrade from being enabled and disables an existing Auto Upgrade for the application with the specified id.
	.PARAMETER Source
		Forces WinGet to use a specific Source. Default is winget. Winget source is set as default because some applications cannot be installed because of an issue searching the msstore source.
	.PARAMETER LogName
		Overrides the default log file name. The default log file name is generated from the WinGet App Id, Version and Action. If LogName does not end in .log, it will be automatically appended.
	.PARAMETER NoWait
		Immediately continue after executing the process.
	.PARAMETER PassThru
		Returns ExitCode, STDOut, and STDErr output from the process.
	.PARAMETER IgnoreExitCodes
		List the exit codes to ignore or * to ignore all exit codes.
	.PARAMETER PriorityClass	
		Specifies priority class for the process. Options: Idle, Normal, High, AboveNormal, BelowNormal, RealTime. Default: Normal
	.PARAMETER ExitOnProcessFailure
		Specifies whether the function should call Exit-Script when the process returns an exit code that is considered an error/failure. Default: $true
	.PARAMETER ContinueOnError
		Continue if an error occured while trying to start the process. Default: $false.
	.EXAMPLE
		Execute-WinGet -Id 'Zoom.Zoom'
		Installs Zoom with default settings
	.EXAMPLE
		Execute-WinGet -Id 'Zoom.Zoom' -Action Uninstall
		Uninstalls Zoom
	.EXAMPLE
		Execute-WinGet -Id 'Zoom.Zoom' -InstallDir 'D:\ProgFiles\Zoom'
		Installs Zoom in D:\ProgFiles\Zoom
	.EXAMPLE
		Execute-WinGet -Id 'Zoom.Zoom' -Version '5.1.28656'
		Installs Zoom version 5.1.28656
	.LINK
		http://psappdeploytoolkit.com

	.NOTES
		Author:      Casper van der Kooij
		Created:     06-oct-2022
		Updated:     18-aug-2023

		Version history:
		0.9.0 - (06-oct-2022) Function created 
		0.9.5 - (16-aug-2023) Added Raw execution option
							  Added logging of Winget output
							  Improved winget.exe detection
							  Added self fix for Winget error -1978335221
	
	#>

	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$true, ParameterSetName = 'Raw')]
		[string]$Raw,
		[Parameter(Mandatory=$false, ParameterSetName = 'Default')]
		[ValidateSet('Install','Uninstall')]
		[string]$Action = 'Install',
		[Parameter(Mandatory=$true, ParameterSetName = 'Default', HelpMessage = "Enter the WinGet Id of the application (case sensitive).")]
		[ValidateNotNullorEmpty()]
		$Id,
		[Parameter(Mandatory=$false, ParameterSetName = 'Default', HelpMessage = "Enter the required version of the application.")]
		[ValidateNotNullorEmpty()]
		$Version,
		[Parameter(Mandatory=$false, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		$Custom,
		[Parameter(Mandatory=$false, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		$Override,
		[Parameter(Mandatory=$false, ParameterSetName = 'Default', HelpMessage = "Enter the installation scope of theapplication. Either user, machine or none (for applications not supporting the scope parameter).")]
		[ValidateSet('user','machine', 'none')]
		$Scope='machine',
		[Parameter(Mandatory=$false, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		$InstallDir,
		[Parameter(Mandatory=$false, ParameterSetName = 'Default')]
		[switch]$UninstallCurrentVersion = $false,
		[Parameter(Mandatory=$false, ParameterSetName = 'Default')]
		[switch]$Force,
		[Parameter(Mandatory=$false, ParameterSetName = 'Default', HelpMessage = "Enter the installation source of the application, winget or msstore.")]
		[ValidateSet('winget','msstore')]
		$Source='winget',
		[Parameter(Mandatory=$false, ParameterSetName = 'Default')]
		[Alias('LogName')]
		[string]$private:LogName,
		[Parameter(Mandatory=$false, ParameterSetName = 'Default')]
		[Parameter(Mandatory=$false, ParameterSetName = 'Raw')]
		[switch]$PassThru = $false,
		[Parameter(Mandatory=$false, ParameterSetName = 'Default')]
		[Parameter(Mandatory=$false, ParameterSetName = 'Raw')]
		[ValidateNotNullorEmpty()]
		[string]$IgnoreExitCodes,
		[Parameter(Mandatory=$false, ParameterSetName = 'Default')]
		[ValidateSet('Idle', 'Normal', 'High', 'AboveNormal', 'BelowNormal', 'RealTime')]
		[Diagnostics.ProcessPriorityClass]$PriorityClass = 'Normal',
		[Parameter(Mandatory=$false, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[boolean]$ExitOnProcessFailure = $true,
		[Parameter(Mandatory=$false, ParameterSetName = 'Default')]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $false
	)

	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {

		If (!$Script:WinGet) {
			If ($IsLocalSystemAccount) {
				Write-Log -Message 'Running as SYSTEM. Preparing Winget for use in system context.' -Source ${CmdletName}
				#WinGet is an Appx app. These are not available when running as System.
				#So we need to find the WinGet executable to that we can access it directly
				#Resolve the Path for the latest installed WinGet version
				$WinGetAppxPackages = Get-AppxPackage -Name "Microsoft.DesktopAppInstaller" -AllUsers
				ForEach($WinGetAppxPackage in $WinGetAppxPackages){
					If ([Version]$WinGetAppxPackage.Version -gt [Version]$FoundWinGetVersion){
						$FoundWinGetVersion = $WinGetAppxPackage.Version
						$WinGetPath = $WinGetAppxPackage.InstallLocation
						$Script:WinGet = $WinGetAppxPackage
					}
				}
				Write-Log -Message 'Adding WinGet path to PATH environment variable.' -Source ${CmdletName}
				$Env:Path = "$WinGetPath;$Env:Path"
				Write-Log -Message "PATH set to $Env:Path" -Source ${CmdletName}

				#WinGet requires Microsoft.VCLibs.140.00.UWPDesktop appx.
				#The path to the latest version of this Appx should be in the PATH environment varable for Winget to function properly
				#Resolve the Path for the latest installed WinGet version
				$VCLibsAppxPackages = Get-AppxPackage -Name "Microsoft.VCLibs.140.00.UWPDesktop" -AllUsers
				ForEach($VCLibsAppxPackage in $VCLibsAppxPackages){
					If ([Version]$VCLibsAppxPackage.Version -gt [Version]$FoundVCLibsVersion -and $VCLibsAppxPackage.Architecture -eq 'x64'){
						$FoundVCLibsVersion = $VCLibsAppxPackage.Version
						$VCLibsPath = $VCLibsAppxPackage.InstallLocation
					}
				}

				Write-Log -Message 'Adding Microsoft.VCLibs.140.00.UWPDesktop path to PATH environment variable (required for WinGet to function properly).' -Source ${CmdletName}
				$Env:Path = "$VCLibsPath;$Env:Path"
				Write-Log -Message "PATH set to $Env:Path" -Source ${CmdletName}

				If (!$Raw -and $Scope -eq 'user') {
					$Scope = 'machine'
				}
			}	
			Else {
				$AppxPackages = Get-AppxPackage -Name "Microsoft.DesktopAppInstaller"
				ForEach($AppxPackage in $AppxPackages){
					If ([Version]$AppxPackage.Version -gt [Version]$FoundWinGetVersion) {
						$FoundWinGetVersion = $AppxPackage.Version
						$WinGetPath = $AppxPackage.InstallLocation
						$Script:WinGet = $AppxPackage
					}
				}

				If (!$Script:WinGet) {
						#AppxPackage may not be registered for the current user. Try to register it now.
						Add-AppxPackage -RegisterByFamilyName -MainPackage "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe" -ErrorAction SilentlyContinue
						$Script:WinGet = Get-AppxPackage -Name "Microsoft.DesktopAppInstaller"
						$WinGetPath = $Script:WinGet.InstallLocation
				}
			}
			
			Write-Log -Message $($Script:WinGet | Out-String) -Source ${CmdletName}
			If (!(Test-Path -Path (Join-Path -Path $WinGetPath -ChildPath "winget.exe"))){
				Write-Log -Message "Winget.exe not not found in $WinGetPath. Unable to continue." -Severity 3 -Source ${CmdletName}
				Exit-Script -ExitCode 70012
			}
		}

		If (!$Raw){
			If (!$IsAdmin -and $Scope -eq 'machine' -and $Action -eq "Install"){
				Write-Log -Message $("Failed to install '$id'" + $(If($Version){" version '$Version'"}) + ". Admin privileges are required for a machine based installation.") -Severity 3 -Source ${CmdletName}
				Exit-Script -ExitCode 70013
			}

			Write-Log -Message $("Checking if '$Id' " + $(If($Version){"with version '$Version' "}) + "is installed.") -Source ${CmdletName}
			$WGInstalledApp = Get-WGInstalledApp -Id $Id -Source $Source
			
			If ($WGInstalledApp.Installed -eq "Yes" -and $Version){
				try {
					$DetectedVersion = ConvertTo-Version $WGInstalledApp.Version
				}
				catch {
					$DetectedVersion = $null
					Write-Log -Message "Application is installed but installed version cannot be determined." -Source ${CmdletName}
					If (-not $ContinueOnError) {
						Throw $("Failed to $action '$id'" + $(If($Version){" version '$Version'"}) + ".")
					}
					Else {
						Write-Log -Message "Continuing to try to $Action the application." -Source ${CmdletName}				
						If ($UninstallCurrentVersion){
							Write-Log -Message "Current application install will be uninstalled before installing new version." -Source ${CmdletName}				
						}
					}
				}
				If ($DetectedVersion) {
					If ($DetectedVersion -eq (ConvertTo-Version $Version)){
						If ($Action -eq "Install"){
							Write-Log -Message "Requested version '$Version' for app '$Id' is already installed. Skipping installation." -Source ${CmdletName}
							Return
						}
						else {
							Write-Log -Message "Requested version '$Version' for app '$Id' is installed." -Source ${CmdletName}
						}
					}
					ElseIf (($DetectedVersion -gt (ConvertTo-Version $Version)) -and $Action -eq "Install") {
						Write-Log -Message $("A newer version ($($WGInstalledApp.Version)) of the application is already installed." + $(If($UninstallCurrentVersion){' Preparing for downgrade.'}Else{' Skipping installation.'})) -Source ${CmdletName}
						If (!$UninstallCurrentVersion) {
							Return
						}
					}
					ElseIf (($DetectedVersion -lt (ConvertTo-Version $Version)) -and ($Action -eq "Install")) {
						Write-Log -Message "Older version ($($WGInstalledApp.Version)) of the application is already installed. Preparing to upgrade '$Id' to version '$Version'." -Source ${CmdletName}
						$WGUpgrade = $True
					}
					ElseIf (($DetectedVersion -ne (ConvertTo-Version $Version)) -and ($Action -eq "Uninstall")){
						Write-Log -Message "Requested version '$Version' for app '$Id' is not installed. Skipping uninstallation." -Source ${CmdletName}
						Return
					}	
				}
			}
			ElseIf ($WGInstalledApp.Installed -eq "Yes") {
				If ($Action -eq "Install" -And !($WGInstalledApp.Available)) {
					Write-Log -Message $("Requested app '$Id' is already installed and no newer version is available." + $(If($Force){' Force parameter specified, so continuing with install anyway.'}Else{' Skipping installation.'})) -Source ${CmdletName}
					If (!$Force) {
						Return
					}
				}
				ElseIf ($Action -eq "Install") {
					Write-Log -Message "Requested app '$Id' is already installed and a newer version is available. Preparing to upgrade '$Id' to version $($WGInstalledApp.Available)." -Source ${CmdletName}
					$WGUpgrade = $True
				}
				ElseIf ($Action -eq "Uninstall") {
					Write-Log -Message "Requested app is installed. Preparing to uninstall '$Id'." -Source ${CmdletName}
				}
			}
			ElseIf ($WGInstalledApp.Installed -eq "No") {
				If ($Action -eq "Install") {
					Write-Log -Message $("Requested app is not installed. Preparing to install '$Id'" + $(If($Version){" version '$Version'"}) + ".") -Source ${CmdletName}
					$WGUpgrade = $False
					$UninstallCurrentVersion = $False
				}
				ElseIf ($Action -eq "Uninstall") {
					Write-Log -Message "Requested app '$Id' is not installed. Skipping uninstallation." -Source ${CmdletName}
					Return
				}
			}
			Else {
				If ($Action -eq "Install") {
					Write-Log -Message $("Failed to determine if app is installed. Attempting to install '$Id' " + $(If($Version){" version '$Version' "}) + "anyway.") -Source ${CmdletName}
					$WGUpgrade = $False
				}
				ElseIf ($Action -eq "Uninstall") {
					Write-Log -Message $("Failed to determine if app is installed. Attempting to uninstall '$Id' " + $(If($Version){" version '$Version' "}) + "anyway.") -Source ${CmdletName}
					Write-Log -Message "Setting WinGet Uninstall Execution to ignore exit code -1978335212 (App not installed)." -Source ${CmdletName}
					If ($IgnoreExitCodes) { 
						If ($IgnoreExitCodes -notlike "*-1978335212*"){
							$IgnoreExitCodes = "$IgnoreExitCodes,-1978335212"
						}
					}
					Else {
						$IgnoreExitCodes = "-1978335212"
					}	
				}	
			}

			# Build the log filename
			If (!$LogName){
				$LogName = "WinGet_$($Id)" +$(If($Version){"_$Version"}) + "_$($Action).log"
			}
			ElseIf ('.log','.txt' -notcontains [IO.Path]::GetExtension($logName)){
				$LogName = "$LogName.log"
			}

			If ($configToolkitCompressLogs) {
				## Build the log file path
				[string]$logPath = Join-Path -Path $logTempFolder -ChildPath $logName
			}
			Else {
				## Create the Log directory if it doesn't already exist
				If (-not (Test-Path -LiteralPath $configToolkitLogDir -PathType 'Container' -ErrorAction 'SilentlyContinue')) {
					$null = New-Item -Path $configToolkitLogDir -ItemType 'Directory' -ErrorAction 'SilentlyContinue'
				}
				## Build the log file path
				[string]$logPath = Join-Path -Path $configToolkitLogDir -ChildPath $logName
			}

			If ($UninstallCurrentVersion -and $Action -eq "Install"){
				#Set $WGUpgrade to false because an upgrade cannot be performed once the current version has been uninstalled
				$WGUpgrade = $False
				#Start the uninstall proces for the currently installed version.
				Write-Log -Message "First uninstalling current installation of '$Id'."  -Source ${CmdletName}
				$DowngradeAppParameters = [ordered]@{
					Task     = "uninstall"
					Id       = $Id
				}
				$DowngradeAppParameters += [ordered]@{
					Log = "--log"
					LogValue  = $LogPath
					}
				If ($DeployMode -ne "Interactive") {
					$DowngradeAppParameters += [ordered]@{Silent = "--silent"}	
				}
				$DowngradeAppParameters += [ordered]@{SourceAgreements = "--accept-source-agreements"}
				$DowngradeAppParameters += [ordered]@{ExactId = "--exact"}
				$DowngradeAppParameters += [ordered]@{Source = "--source $Source"}

				[hashtable]$ExecuteProcessSplat =  @{
					Path = "WinGet.exe"
					Parameters = $DowngradeAppParameters.Values
					WindowStyle = 'Normal'
				}
				$ExecuteProcessSplat.Parameters = $DowngradeAppParameters.Values
				Execute-Process @ExecuteProcessSplat
				Write-Log -Message "Uninstall of existing installation of '$Id' successful."  -Source ${CmdletName}
			}

			Write-Log -Message "Preparing WinGet Command line for installation of '$Id' app."  -Source ${CmdletName}
			If ($WGUpgrade) {$WGAction = "upgrade"} Else {$WGAction=$Action}
			$InstallAppParameters = [ordered]@{
				Task     = $WGAction
				Id       = $Id
			}
			if ($Version) { 
				$InstallAppParameters += [ordered]@{
					Version = "--version"
					VersionValue  = $Version
				}
			}
			if ($Custom -and ($WGAction -eq "Install" -or $WGAction -eq "upgrade")) { 
				$InstallAppParameters += [ordered]@{
					Custom = "--custom"
					CustomValue  = $Custom
				}  
			}
			if ($Override -and $WGAction -eq "Install") { 
				$InstallAppParameters += [ordered]@{
					Override = "--override"
					OverrideValue  = $Override
				}  
			}  
			if ($InstallDir -and $WGAction -eq "Install") { 
				$InstallAppParameters += [ordered]@{
					Location = "--location"
					LocationValue  = $InstallDir
				}
			}
			if ($Scope -ne 'none' -and $WGAction -eq "Install") { 
				$InstallAppParameters += [ordered]@{
					Scope = "--scope"
					ScopeValue  = $Scope
				}
			}
			$InstallAppParameters += [ordered]@{
				Log = "--log"
				LogValue  = """$LogPath"""
			}
			If ($DeployMode -ne "Interactive") {
				$InstallAppParameters += [ordered]@{Silent = "--silent"}	
			}
			$InstallAppParameters += [ordered]@{SourceAgreements = "--accept-source-agreements"}
			If ($Action -eq "Install"){
				$InstallAppParameters += [ordered]@{PackageAgreements = "--accept-package-agreements"}
			}
			#Use the --exact paramter to make sure the no other app is installed than the app with the specified Id
			$InstallAppParameters += [ordered]@{ExactId = "--exact"}
			$InstallAppParameters += [ordered]@{Source = "--source $Source"}
					
			Write-Log -Message "Executing WinGet action [$WGAction]..." -Source ${CmdletName}
		}	
		
		#  Build the hashtable with the options that will be passed to Execute-Process using splatting
		[hashtable]$ExecuteProcessSplat =  @{
			Path = "WinGet.exe"
			#Parameters = $InstallAppParameters.Values
			WindowStyle = 'Normal'
			#Always use Passthru and not ExitOnProcessFailure for Execute-Process so that the full Output of Winget can be logged.
			PassThru = $True
			ExitOnProcessFailure = $False
			ContinueOnError = $ContinueOnError
			PriorityClass = $PriorityClass
		}
		If ($Raw) {
			$ExecuteProcessSplat.Add('Parameters', $Raw) 
			Write-Log -Message "Executing WinGet with raw parameters..." -Source ${CmdletName}
		}
		else { 
			$ExecuteProcessSplat.Add('Parameters', $InstallAppParameters.Values)
		}

		#  Call the Execute-Process function
		[psobject]$ExecuteResults = Execute-Process @ExecuteProcessSplat
		If ($ExecuteResults.ExitCode -eq -1978335221){
			Write-Log -Message "Winget execution failed with known exit code [$($ExecuteResults.ExitCode)]. Error: 'The configured source information is corrupt' " -Source ${CmdletName}
			Write-Log -Message "Winget execution Output:`r`n$($ExecuteResults.StdOut)" -Source ${CmdletName}
			If ($IsAdmin) {
				Write-Log -Message "Trying possible solution: Winget.exe source reset --force" -Source ${CmdletName}
				$Result = & winget.exe source reset --force
				Write-Log -Message "Winget execution Output:`r`n$Result" -Source ${CmdletName}
				Write-Log -Message "Retrying installation..." -Source ${CmdletName}
				[psobject]$ExecuteResults = Execute-Process @ExecuteProcessSplat
			}
			else {
				Write-Log -Message "This install is running without admin privileges. Please try running 'Winget.exe source reset --force' with admin privileges as a possible solution. Then retry install." -Source ${CmdletName}
			}

		}
		If ($ExecuteResults.ExitCode -ne 0){
			## Check to see whether we should ignore exit codes
			$ignoreExitCodeMatch = $false
			If ($ignoreExitCodes) {
				## Check whether * was specified, which would tell us to ignore all exit codes
				If ($ignoreExitCodes.Trim() -eq "*") {
					$ignoreExitCodeMatch = $true
				}
				Else {
					## Split the processes on a comma
					[int32[]]$ignoreExitCodesArray = $ignoreExitCodes -split ','
					ForEach ($ignoreCode in $ignoreExitCodesArray) {
						If ($ExecuteResults.ExitCode -eq $ignoreCode) { $ignoreExitCodeMatch = $true }
					}
				}
			}
			If ($ignoreExitCodeMatch) {
				Write-Log -Message "Winget execution completed and the exit code [$($ExecuteResults.ExitCode)] is being ignored." -Source ${CmdletName}
				Write-Log -Message "Winget execution Output:`r`n$($ExecuteResults.StdOut)" -Source ${CmdletName}
			}
			ElseIf ($ExecuteResults.ExitCode -eq -1978334967) {
				Write-Log -Message "Execution completed successfully with exit code [$($ExecuteResults.ExitCode)]. A reboot is required. Returning Exit Code 3010" -Severity 2 -Source ${CmdletName}
				Set-Variable -Name 'msiRebootDetected' -Value $true -Scope 'Script'
			}
			Else {
				Write-Log -Message "Winget execution failed with exit code [$($ExecuteResults.ExitCode)]." -Source ${CmdletName}
				Write-Log -Message "Winget execution Output:`r`n$($ExecuteResults.StdOut)" -Source ${CmdletName}
				If ($ExitOnProcessFailure) {
					Exit-Script -ExitCode $ExecuteResults.ExitCode
				}
			}
		}
		Else {
			Write-Log -Message "Winget execution completed succesfully with exit code [$($ExecuteResults.ExitCode)]." -Source ${CmdletName}
			Write-Log -Message "Winget execution Output:`r`n$($ExecuteResults.StdOut)" -Source ${CmdletName}
		}
	}
	End {
		If ($PassThru) { Write-Output -InputObject $ExecuteResults }
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion Execute-Winget Function

Function Set-QuietUninstallString {
	<#
	.SYNOPSIS
		Set or Create a QuietUninstall String in the Uninstall registry for a specific application.
	.DESCRIPTION
		Set or Create a QuietUninstall String in the Uninstall registry for a specific application.
	.PARAMETER AppName
		Name of the app as listed in Add/Remove programs.
	.PARAMETER UninstallString
		The Uninstallstring to be used for the QuietUninstallString. 
		If not specified the value of the QuietUninstallString in the Uninstall registry key for the specifed app is used. 
		If the QuietUninstallString does not exist in the registry the value of the UninstallString in the Uninstall registry key
		for the specified app is used.
	.PARAMETER Parameters
		Parameters to be set in the UninstallString. This replaces all existing parameters in the string.	
	.PARAMETER AddParameters
		Parameters to be added to the UninstallString
	.PARAMETER ReplaceParameters
		Parameters to be replaced in the UninstallString. This must be specified like "/SILENT=/VERYSILENT".
		Specify multiple replacements seprated by a comma like this: "/SILENT=/VERYSILENT,/NoReboot=/NoRestart"
	.PARAMETER IfNotExists
		Specify to only set the QuietUninstallString if it doesn't already exist for the specified application.
	.EXAMPLE
		Set-QuietUninstallString -AppName 'Logitech Unifying-software 2.52' -Parameters '/S' -IfNotExists
			Sets the QuietUnistallString for the app 'Logitech Unifying-software 2.52' using the UninstallString for this app, setting the parameters to '/S' and only if the QuietUninstallString doesn't already exist.
	.NOTES
		Author:      Casper van der Kooij
		Created:     05-sep-2023
		Updated:     05-sep-2023

		Version history:
		0.1.0 - (05-sep-2023) Function created 

	.LINK
		http://psappdeploytoolkit.com
	#>

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$AppName,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[String]$UninstallString,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[String]$Parameters,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[String]$AddParameters,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[String]$ReplaceParameters,
		[Parameter()]
		[switch]$IfNotExists
	)

	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Write-Log -Message "Setting QuietUninstallString for '$AppName'."
		$InstalledApps = Get-InstalledApplication -Name $AppName -Exact
        ForEach ($InstalledApp in $InstalledApps) {
			#This function can only work for non MSI installs.
            If (!$InstalledApp.UninstallString.ToLower().Contains('msiexec.exe')){
				
				#First get the correct Uninstall registrykey for the app.
		        $UninstallKey = "HKEY_LOCAL_MACHINE\SOFTWARE\$(If(!$InstalledApp.Is64BitApplication){'WOW6432Node\'})Microsoft\windows\CurrentVersion\Uninstall\$($InstalledApp.UninstallSubkey)"		
				#Get the current value of the QuietUninstalString in the registry (if it exists).
				If (!$UninstallString) {
					Write-Log -Message 'Trying to get Existing QuietUninstallString from the registry.' -Source ${CmdletName}
		        	$QuietUninstallString = Get-RegistryKey -Key $UninstallKey -Value 'QuietUninstallString'			
				
					#If no value for the QuietUninstallString was retieved from the registry, use the UninstallString for the app.
					If (!$QuietUninstallString ){
						Write-Log -Message 'Using UninstallString instead as base for the QuietUninstallString.' -Source ${CmdletName}
						$QuietUninstallString = $InstalledApp.UninstallString
					}
					ElseIf ($IfNotExists) {
						Write-Log -Message "QuietUninstallString already exists and -IfNotExists parameter passed. Skipping $($InstalledApp.UninstallSubkey)." -Source ${CmdletName}
						Continue
					}
				}
				Else {
					$QuietUninstallString = $UninstallString
				}
				#Now split the Uninstallstring in the exe and the parameters
				If (!($QuietUninstallString.toLower().EndsWith('.exe') -or $QuietUninstallString.toLower().EndsWith('.exe"'))){
					$Split = $QuietUninstallString -Split('.exe" ')
					If($Split.Count -eq 1){
						$Split = $QuietUninstallString -Split('.exe ')
					}
					If ($Split.Count -eq 2) {
						#Set the Uninstallexe without any quotes
						$UninstallExe = $($Split[0] + '.exe').Replace('"', '')
						$UninstallParameters = $Split[1]
					}
					Else {
						Write-Log -Message "Unable to set QuietUninstallString for $AppName. Failed to split existing UninstallString in exe and parameters." -Severity 3 -Source ${CmdletName}
						Exit-Script -ExitCode 70021
					}
				}
				Else {
					$UninstallExe = $QuietUninstallString.Replace('"','')
					$UninstallParameters = ''
				}
				#If -Parameters was set, replace all existing parameters by the value of -Parameters.
				If ($Parameters) {
					$UninstallParameters = $Parameters
				}
				#Add the parameters supplied by -Addparameters.
				If ($AddParameters) {
					If (!"$UninstallParameters ".ToLower().contains("$AddParameters ".ToLower())) {
						$UninstallParameters = $UninstallParameters + $(If($UninstallParameters){' '}) + $AddParameters
					}
				}
				#Replace the parameters as supplied by -Replaceparameters.
				If ($ReplaceParameters) {
					$ReplacementParts = $ReplaceParameters.Split(',')
					ForEach ($ReplacementPart in $ReplacementParts){
						$Replacement = $ReplacementPart.Split('=')
						If ($Replacement.Count -ne 2){
							Write-Log -Message "Unable to set QuietUninstallString for $AppName. Invalid string value for -ReplaceParameters." -Severity 3 -Source ${CmdletName}
							Exit-Script -ExitCode 70022
						}
						$UninstallParameters = $("$UninstallParameters ".Replace("$($Replacement[0]) ", "$($Replacement[1]) ")).TrimEnd(' ')
					}
				}
				$QuietUninstallString = """$UninstallExe""" + $(If($UninstallParameters){" $UninstallParameters"})
				Write-Log -Message "Setting QuietUinstallString for '$AppName' to '$QuietUninstallString'." -Source ${CmdletName}
				Set-RegistryKey -Key $UninstallKey -Name 'QuietUninstallString' -Value $QuietUninstallString
		    }
			else {
				Write-Log -Message "Skipping QuietUninstallString for $($InstalledApp.ProductCode) because it is an MSI uninstall entry." -Source ${CmdletName}
			}
        }
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}

Function Execute-LocalWinGet {
	<#
	.SYNOPSIS
		Executes WinGet to Install or Uninstall an application from the WinGet repository.
	.DESCRIPTION
		Executes WinGet to Install or Uninstall an application from the WinGet repository.
		WinGet has to be installed on the system.
		If an older version of the application is already present when running this function with the 'Install' action, the application will be upgraded.
		For all application installed using this function Auto Upgrade will be enabled (The NoAutoUpgrade parameter is specified or the version parameter is used or the application is installed per-user).
		For the Auto Upgrade the application will be registered for upgrade in the registry and a scheduled task is created (if not already present) that wil upgrade
		the registered applications on a weekly basis (if an upgrade is available).
	.PARAMETER Action
		The action to perform. Options: Install, Uninstall.
	.PARAMETER Id
		The WinGet Id of the application (case sensitive) to Install or Uninstall.
	.PARAMETER Parameters
		A string of parameters that will be passed directly to the (un)installer, replacing any default parameters. For instance to specify specific Properties or an Mst to the MSI installer.
		Valid for the Install action and for the Uninstall action if not an MSI uninstall. 
		When Action is Install the value for the parameter InstallDir is ignored.
		Is ignored if a QuietUninstallString is found in the App's Uninstall Information in the registry, unless the OverrideQuietUinstallString parameter is passed.
	.PARAMETER AddParameters
		A string of parameters that will be passed directly to the (un)installer and is added to the default parameters. For instance to add specific Properties or an Mst to the MSI installer.
		Valid for the Install action and for the Uninstall action if not an MSI uninstall. 
		Is ignored if a QuietUninstallString is found in the App's Uninstall Information in the registry, unless the OverrideQuietUinstallString parameter is passed.
	.PARAMETER ReplaceParameters
		Parameters to be replaced in the UninstallString. This must be specified like "/SILENT=/VERYSILENT".
		Specify multiple replacements seprated by a comma like this: "/SILENT=/VERYSILENT,/NoReboot=/NoRestart"
		Valid for the Uninstall action if not an MSI uninstall. 
		Is ignored if a QuietUninstallString is found in the App's Uninstall Information in the registry, unless the OverrideQuietUinstallString parameter is passed.
	.PARAMETER OverrideQuietUinstallString
		Switch parameter. Passing this parameter allows the Parameters, AddParameters en ReplaceParameters parameters to de applied when a QuietUninstallString is found in the App's Uninstall Information in the registry. 
	.PARAMETER InstallDir
		Location to install to (if supported by the installer). Is ignored if the Action is Uninstall
	.PARAMETER LogName
		Overrides the default log file name. The default log file name is generated from the WinGet App Id, Version and Action. If LogName does not end in .log, it will be automatically appended.
	.PARAMETER PassThru
		Returns ExitCode, STDOut, and STDErr output from the process.
	.PARAMETER IgnoreExitCodes
		List the exit codes to ignore or * to ignore all exit codes.
	.PARAMETER PriorityClass	
		Specifies priority class for the process. Options: Idle, Normal, High, AboveNormal, BelowNormal, RealTime. Default: Normal
	.PARAMETER ExitOnProcessFailure
		Specifies whether the function should call Exit-Script when the process returns an exit code that is considered an error/failure. Default: $true
	.PARAMETER ContinueOnError
		Continue if an error occured while trying to start the process. Default: $false.
	.EXAMPLE
		Execute-LocalWinGet -Id 'Zoom.Zoom'
		Installs Zoom with default settings
	.EXAMPLE
		Execute-LocalWinGet -Id 'Zoom.Zoom' -Action Uninstall
		Uninstalls Zoom
	.EXAMPLE
		Execute-LocalWinGet -Id 'Zoom.Zoom' -InstallDir 'D:\ProgFiles\Zoom'
		Installs Zoom in D:\ProgFiles\Zoom
	.EXAMPLE
		Execute-LocalWinGet -Id 'Zoom.Zoom' -Version '5.1.28656'
		Installs Zoom version 5.1.28656
	.LINK
		http://psappdeploytoolkit.com

	.NOTES
		Author:      Casper van der Kooij
		Created:     06-oct-2022
		Updated:     18-aug-2023

		Version history:
		0.1.0 - (04-apr-2024) Function created 
		0.8.0 - (11-jun-2024) Function updated

	#>

	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$false)]
		[ValidateSet('Install','Uninstall')]
		[string]$Action = 'Install',
		[Parameter(Mandatory=$true, HelpMessage = "Enter the WinGet Id of the application.")]
		[ValidateNotNullorEmpty()]
		$Id,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		$Path=$dirFiles,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		$Parameters,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		$AddParameters,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		$ReplaceParameters,
		[Parameter()]
		[switch]$OverrideQuietUinstallString,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		$InstallDir,
		[Parameter(Mandatory=$false)]
		[Alias('LogName')]
		[string]$private:LogName,
		[Parameter()]
		[switch]$PassThru,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$IgnoreExitCodes,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ExitOnProcessFailure = $true,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $false
	)

	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		#region Load Required Modules
		#Check if required Module psyml is Loaded.
    	Try {
			Write-Log "Importing module powershell-yaml for handling yaml files."  -Source ${CmdletName}
        	Import-Module "$scriptRoot\powershell-yaml\0.4.7\powershell-yaml.psd1"
        	Write-Log -Message "Succesfully loaded Module powershell-yaml." -Source ${CmdletName}
    	}
    	Catch {
        	Write-Log -Message "Failed to load Powershell Module powershell-yaml from $scriptRoot\AppDeployToolkit\powershell-yaml\0.4.7\powershell-yaml.psd1"  -Source ${CmdletName} -Severity 3
			Exit-Script -ExitCode 70001
    	}
		#endregion

		#Get the App's Local WinGet data.
		#find the application yml file
		$YmlFileFound = $False
		ForEach ($Yamlfile in (get-ChildItem -Path $Path -Filter '*.yaml')){
			$YamlContent = Get-Content -LiteralPath (Join-Path -Path $Path -ChildPath $Yamlfile.Name)
			#Now we remove the localization part from the manifest as it has been found to often contain incorrect Yaml syntax and we're not interested in the localization part anyway.
        	$YamlContent = (Remove-LocalizationFromManifest -YamlContent $YamlContent) -join "`r`n"
			$LocalWinGetData = ConvertFrom-Yaml $YamlContent
			#Check the WinGet Package Identifier
			If ($LocalWinGetData.PackageIdentifier -eq $Id){
				Write-Log -Message "Found $($Yamlfile.Name) matching winget id: $Id" -Source ${CmdletName}
				$YmlFileFound = $True
				Break
			}
		}
		If (!$YmlFileFound) {
			If (!$LocalWinGetData) {
				Write-Log -Message "No Yaml file found in $Path" -Source ${CmdletName} -Severity 3
				If (!$ContinueOnError) {
					$MainExitCode = 70024
					Throw "No Yaml file found in $Path" 
				}
				else {
					return
				}
			}
			Else {
				Write-Log -Message "No Yaml file found matching winget id: $Id" -Source ${CmdletName} -Severity 3
				If (!$ContinueOnError) {
					$MainExitCode = 70025
					Throw "No Yaml file found matching winget id: $Id" 
				}
				else {
					return
				}
			}
		}

		$AppProductCode = $LocalWinGetData.Installers.ProductCode
		$AppUpgradeCode = $LocalWinGetData.Installers.AppsAndFeaturesEntries.UpgradeCode
		$AppName = $LocalWinGetData.PackageName
		$AppPublisher = $LocalWinGetData.Publisher
		$AppVersion = [String]$LocalWinGetData.PackageVersion
		Switch ($LocalWinGetData.Installers.Scope) {
			'machine' {
				$PackageScope = 'AllUsers'
			}
			'user' {
				$PackageScope = 'CurrentUser'
			}
			Default {
				$PackageScope = $null
			}
		}
		

		#Check for installed existing package
		$AppInstalled = $false
		$InstalledApp = $null

		#Search based on ProductCode
		If ($AppProductCode) {
			$InstalledApps = Get-InstalledApplication -ProductCode $AppProductCode -IncludeCurrentUser
			
			If ($InstalledApps) {
				$InstalledApp = $InstalledApps[0]
				$AppInstalled = $true
			}
		}

		#If not found by ProductCode search based on UpgradeCode (if available).
		If (!$InstalledApp -and $AppUpgradeCode) {
			$InstalledApps = Get-InstalledApplication -UpgradeCode $AppUpgradeCode
			If ($InstalledApps) {
				$InstalledApp = $InstalledApps[0]
				$AppInstalled = $true
			}
		}

		#If not found based on ProductCode or UpgradeCode, search based on name, publisher and architecture
		If (!$InstalledApp) {
			#Search based on name, publisher and architecture, 
			If ($AppArchitecture -eq 'x64') {$AppIs64bit = $true} else {$AppIs64bit = $false}
			#Search by name. Name has the begin with the AppName (PackageName) stated in the manifest
			$InstalledApps = Get-InstalledApplication -name "$AppName*" -WildCard -IncludeCurrentUser
			ForEach ($InstalledApp in $InstalledApps) {
				#Also check Publisher, Architecture and Scope
				If ($AppPublisher -eq $InstalledApp.Publisher -and $AppIs64bit -eq $InstalledApp.Is64BitApplication) {
					If (($PackageScope -eq $InstalledApp.InstallScope) -or !$PackageScope) {
						If ($InstalledApp.IsSystemComponent -and $InstalledApp -ne $InstalledApps[-1]){
							#Store this app and check the next one, because this one is set as a SystemComponent another app is found in the uninstall info.
							$SavedInstalledApp = $InstalledApp
						}
						Else {
							Write-Log -Message "Application detected by Name (starting with $AppName), Publisher ($AppPublisher) and Architecture ($AppArchitecture). Installed version: $($InstalledApp.DisplayVersion))"
							$AppInstalled = $true
							#No need to check further
							Break
						}
					}
					Else {
						If (!$SavedInstalledApp -and $InstalledApp -eq $InstalledApps[-1]) {
							Write-Log -Message "Application $AppPublisher $AppName $AppArchitecure is installed for a different scope. Installed Scope $($InstalledApp.InstallScope), Package Scope $PackageScope."
							If (!$ContinueOnError) {
								$MainExitCode = 70023
								Throw 'Scope mismatch'
							}
							else {
								return
							}
						}
					}
				}
			}
		}
		If (!$AppInstalled -and $SavedInstalledApp) {
			$AppInstalled = $True
			$InstalledApp = $SavedInstalledApp
		}

		If ($AppInstalled) {
			If ((ConvertTo-Version $InstalledApp.DisplayVersion ) -ge (ConvertTo-Version $AppVersion)) {
				Write-Log -Message "Installed version $($InstalledApp.DisplayVersion) is equal to or greater than $AppVersion." -Source ${CmdletName}
				If ($Action -eq 'Install') {
					Write-Log -Message "App can't be upgraded to version $AppVersion. Skipping action [Install]" -Source ${CmdletName}
					Return
				}
			}
			Else {
				Write-Log -Message "Installed version $($InstalledApp.DisplayVersion) is less than $AppVersion." -Source ${CmdletName}
				If ($Action -eq 'Install') {
					If ($LocalWinGetData.Installers.UpgradeBehavior -ne 'install') {
						#Uninstall any previous version of the app.
						$DoUninstall = $True
					}
				}
			}
		}

		If ($Action -eq 'Uninstall' -or $DoUninstall) {
			#Uninstall application
			$UninstallExecuteSplat =  @{
				ContinueOnError = $ContinueOnError
			}
			If ($IgnoreExitCodes) {$UninstallExecuteSplat['IgnoreExitCodes'] = $IgnoreExitCodes}
			If ($PassThru) {$UninstallExecuteSplat['PassThru'] = $PassThru}
			If ($InstalledApp) {
				If ($InstalledApp.IsWindowsInstaller) {
					$UninstallExecuteSplat['Action'] = 'Uninstall'
					$UninstallExecuteSplat['Path'] = $InstalledApp.ProductCode
					
					If ($PassThru) {
						[psobject[]]$ExecuteResults += Execute-MSI @UninstallExecuteSplat
					}
					Else {
						Execute-MSI @UninstallExecuteSplat
					}
				}
				Else {
					If ($deployModeNonInteractive -or $deployModeSilent) {
						Write-Log -Message "Running in $DeployMode mode, using QuietUninstallString to uninstall $AppPublisher $AppName $AppArchitecure." -Source ${CmdletName}
						$UninstallString = $InstalledApp.QuietUninstallString
						If (!$UninstallString) {
							Write-Log -Message "No QuietUinstallString configured, will use UninstallString instead.'" -Source ${CmdletName} -Severity 2
							$UninstallString = $InstalledApp.UninstallString
						}
					}
					else {
						Write-Log -Message "Running in $DeployMode mode, using UninstallString to uninstall $AppPublisher $AppName $AppArchitecure." -Source ${CmdletName}
						$UninstallString = $InstalledApp.UninstallString
					}
					#Now split the Uninstallstring in the exe and the parameters
					If (!($UninstallString.toLower().EndsWith('.exe') -or $UninstallString.toLower().EndsWith('.exe"'))){
						$Split = $UninstallString -Split('.exe" ')
						If($Split.Count -eq 1){
							$Split = $UninstallString -Split('.exe ')
						}
						If ($Split.Count -eq 2) {
							#Set the Uninstallexe without any quotes
							$UninstallExe = $($Split[0] + '.exe').Replace('"', '')
							$UninstallParameters = $Split[1]
						}
						Else {
							Write-Log -Message "Failed to split existing UninstallString ($UninstallString) in exe and parameters." -Severity 3 -Source ${CmdletName}
							If (!$ContinueOnError) {
								$MainExitCode = 70022
								Throw 'Error preparing uninstall.'
							}
							else {
								return
							}
						}
					}
					Else {
						$UninstallExe = $UninstallString.Replace('"','')
						$UninstallParameters = ''
					}
					If ($Action -eq 'Uninstall'){
						#Only modify the uninstall parameters if Action is Uninstall, otherwise the modification is for the install command
						If (!$InstalledApp.QuietUninstallString -or $OverrideQuietUinstallString) {
							If ($Parameters) {$UninstallParameters = $Parameters}
							If ($AddParameters) {
								If (!"$UninstallParameters ".ToLower().contains("$AddParameters ".ToLower())) {
									$UninstallParameters = $UninstallParameters + $(If($UninstallParameters){' '}) + $AddParameters
								}
							}

							#Replace the parameters as supplied by -Replaceparameters.
							If ($ReplaceParameters) {
								$ReplacementParts = $ReplaceParameters.Split(',')
								ForEach ($ReplacementPart in $ReplacementParts){
									$Replacement = $ReplacementPart.Split('=')
									If ($Replacement.Count -ne 2){
										Write-Log -Message "Invalid string value for -ReplaceParameters." -Severity 3 -Source ${CmdletName}
										If (!$ContinueOnError) {
											$MainExitCode = 70022
											Throw 'Invalid string value for -ReplaceParameters.'
										}
										else {
											return
										}
									}
									$UninstallParameters = $("$UninstallParameters ".Replace("$($Replacement[0]) ", "$($Replacement[1]) ")).TrimEnd(' ')
								}
							}
						}
					}
					$UninstallExecuteSplat.Add('Path', $UninstallExe)
					If ($UninstallParameters){
						$UninstallExecuteSplat.Add('Parameters', $UninstallParameters)
					}
					If (!$InstalledApp.QuietUninstallString -and $Action -eq 'Install' -and ($deployModeNonInteractive -or $deployModeSilent)){
						Write-Log -Message "Unable to uninstall existing application because of missing QuietUninstallString in the Apps Uninstall information. Please uninstall existing app prior to installing $AppName $AppPublisher $AppVersion."
					}
					ElseIf ($PassThru) {
						[psobject[]]$ExecuteResults += Execute-Process @UninstallExecuteSplat
					}
					Else {
						Execute-Process @UninstallExecuteSplat
					}
				}
			}
			Else {
				Write-Log "Skipping uninstall because application $AppPublisher $AppName is not installed."
			}
		}

		If ($Action -eq 'Install') {
			#Handle Dependencies
			ForEach ($Dependency in $LocalWinGetData.Installers.Dependencies.PackageDependencies) {
				Write-Log "$AppPublisher $AppName requires dependency $($Dependency.PackageIdentifier). Trying to install. "
				Execute-LocalWinGet -Action Install -Id $Dependency.PackageIdentifier -Path (Join-Path -Path $Path -ChildPath 'Dependencies')
			}
			#Start Install
			If ($deployModeSilent -or $deployModeNonInteractive) {
				$DefaultParameters = $LocalWinGetData.Installers.InstallerSwitches.Silent
			}
			Else {
				If ($LocalWinGetData.Installers.InstallerSwitches.SilentWithProgress) {
					$DefaultParameters = $LocalWinGetData.Installers.InstallerSwitches.SilentWithProgress
				}
				else {
					$DefaultParameters = $LocalWinGetData.Installers.InstallerSwitches.Silent
				}
			}

			$CustomParameters = $LocalWinGetData.Installers.InstallerSwitches.Custom

			If (!$Parameters) {
				$Parameters = "$DefaultParameters $CustomParameters $AddParameters"
			
				If ($InstallDir){
					If ($LocalWinGetData.Installers.InstallerSwitches.InstallLocation) {
						$Parameters = "$Parameters $($LocalWinGetData.Installers.InstallerSwitches.InstallLocation.Replace('<INSTALLPATH>',$InstallDir))"	
					}
					Else
					{
						Write-Log -Message 'Setting the install location is not supported by this installer. Skipping.' -Source ${CmdletName}
					}
				}
			}
			#Cleanup $parameters to remove spaces at beginning and end and double spaces.
			$Parameters = $Parameters.Trim(" ").Replace("  ", " ")

			If ($LocalWinGetData.Installers.InstallerSwitches.Log) {
				# Build the log filename
				If (!$LogName){
					$LogName = "LocalWinGet_$($Id)_$($LocalWinGetData.PackageVersion)_$Action.log"
				}
				ElseIf ('.log','.txt' -notcontains [IO.Path]::GetExtension($logName)){
					$LogName = "$LogName.log"
				}
				
				If ($configToolkitCompressLogs) {
					## Build the log file path
					[string]$logPath = Join-Path -Path $logTempFolder -ChildPath $logName
				}
				Else {
					## Create the Log directory if it doesn't already exist
					If (-not (Test-Path -LiteralPath $configToolkitLogDir -PathType 'Container' -ErrorAction 'SilentlyContinue')) {
						$null = New-Item -Path $configToolkitLogDir -ItemType 'Directory' -ErrorAction 'SilentlyContinue'
					}
					## Build the log file path
					[string]$logPath = Join-Path -Path $configToolkitLogDir -ChildPath $logName
				}

				$LogParameter = $LocalWinGetData.Installers.InstallerSwitches.Log.Replace('<LOGPATH>',$LogPath)
				$Parameters = "$Parameters $LogParameter"
			}
			else {
				Write-Log 'This installer does not support a log file. No installer log file will be created.' -Source ${CmdletName}
			}

			#Install App
			[hashtable]$InstallExecuteSplat =  @{
				ContinueOnError = $ContinueOnError
			}
			If ($IgnoreExitCodes) {$UninstallExecuteSplat.Add('IgnoreExitCodes', $IgnoreExitCodes)}
			If ($PassThru) {$InstallExecuteSplat.Add('PassThru', $PassThru)}
			If ($Parameters) {$InstallExecuteSplat.Add('Parameters', $Parameters)}

			If ($LocalWinGetData.Installers.InstallerType -eq 'msi' -or $LocalWinGetData.Installers.InstallerType -eq 'wix') {
				$InstallExecuteSplat.Add( 'Action', 'Install')
				$InstallerFileName = $Yamlfile.Name -Replace 'yaml$','msi'
				$InstallExecuteSplat.Add( 'Path', (Join-Path -Path $Path -ChildPath $InstallerFileName))

				If ($PassThru) {
					[psobject[]]$ExecuteResults += Execute-MSI @InstallExecuteSplat
				}
				Else {
					Execute-MSI @InstallExecuteSplat
				}
			}
			Else {
				$InstallerFileName = $Yamlfile.Name -Replace 'yaml$','exe'
				$InstallExecuteSplat.Add( 'Path', (Join-Path -Path $Path -ChildPath $InstallerFileName))
				If ($PassThru) {
					[psobject[]]$ExecuteResults += Execute-Process @InstallExecuteSplat
				}
				Else {
					Execute-Process @InstallExecuteSplat
				}
			}
		}
	}
	End {
		If ($PassThru) { Write-Output -InputObject $ExecuteResults }
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}

Function ConvertTo-Version {
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$True)]
		[string]$Version
	)

	#try to convert a non standard version to a comparable version.
	#If the version number contains text or any other string containing anything other then a . or a number, those characters will be replace by a .
	#i.e: 1.2beta3 or 1.2-3 becomes 1.2.3, 1.2a or 1.2b becomes 1.2, meaning that 1.2b will not be seen as different to 1.2a.
	#This may not always be perfect but allows for many more versions to be comparable and thus usable
	
	#First replace all characters not a dot(.) or a digit by a dot(.)
	$Version = [regex]::Replace($Version, "[^.0-9\s]", ".")
	#Now replace all duplicate dots by a single dot.
	$Version = [regex]::Replace($Version, "(?m)[.](?=[.]|$)", "")

	#Split the version by dots.
	$SplitVersion = $Version.Split('.')
	#Only join the first four version parts together and if less than 4 parts add zero's
	For ($i=0;$i -le 3;$i++){
		If (!$SplitVersion[$i]) {$VersionPart = '0'} else {$VersionPart = $SplitVersion[$i]}
		If ($i -eq 0){$Version = $VersionPart} else {$Version += ".$VersionPart"}
	}
	Return [Version]$Version
}

Function Remove-LocalizationFromManifest {
    param(
        [parameter(Mandatory = $true, HelpMessage =  'Specify the script to update.')]
        $YamlContent
    )
    [System.Collections.ArrayList]$Output = @()
    ForEach ($line in $YamlContent) {
        
        If ($Line -eq 'Localization:'){
            $InLocalization = $true
            Continue
        }
        If ($InLocalization) {
            If (!$line.StartsWith('- ') -and !$line.StartsWith('  ')){
                $InLocalization = $false
                $null = $Output.Add($Line)
            }
        }
        Else {
            $null = $Output.Add($Line)
        }

    }
    Return [Array]$Output
}

Function ConvertTo-FormattedInstallerGuid {
	Param (
		[Parameter(Mandatory=$true)]
		[ValidatePattern('^(\{{0,1}([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}\}{0,1})$')]
		[string]$Guid
	)

	$RevertPattern = (8,4,4,2,2,2,2,2,2,2,2)
	$Index = 0

	#Remove hyphens and brackets
	$String = $Guid.Replace('-','').Replace('{','').Replace('}','')

	ForEach ($length in $RevertPattern) {
		# Get the substring to reverse
		$Substring = $String.Substring($index,$Length)
		#Reverse the Substring and store it in an array
		[String]$FormattedInstallerGuid += -join (($Substring.length-1)..0 | Foreach-Object { $Substring[$_] })
		# Increment our posistion in the string
		$index += $length
	}

	Return $FormattedInstallerGuid
}

Function ConvertFrom-FormattedInstallerGuid {
	Param (
		[Parameter(Mandatory=$true)]
		[ValidatePattern('[0-9a-fA-f]{32}')]
		[string]$FormattedGuid
	)
	$RevertPattern = (8,4,4,2,2,2,2,2,2,2,2)
	$Index = 0
	
	ForEach ($length in $RevertPattern) {
		# Get the substring to reverse
		$Substring = $FormattedGuid.Substring($index,$Length)
		#Reverse the Substring and store it in an array
		If ($Index -in (8,12,16,20)) {
			$RevertedGuid += '-'
		}
		[String]$RevertedGuid += -join (($Substring.length-1)..0 | Foreach-Object { $Substring[$_] })
		# Increment our posistion in the string
		$index += $length
	}
	Return "{$RevertedGuid}"
}

#region Function Get-InstalledApplication
Function Get-InstalledApplication {
	<#
	.SYNOPSIS
		Retrieves information about installed applications.
	.DESCRIPTION
		Retrieves information about installed applications by querying the registry. You can specify an application name, a product code, or both.
		Returns information about application publisher, name & version, product code, uninstall string, install source, location, date, and application architecture.
	.PARAMETER Name
		The name of the application to retrieve information for. Performs a contains match on the application display name by default.
	.PARAMETER Exact
		Specifies that the named application must be matched using the exact name.
	.PARAMETER WildCard
		Specifies that the named application must be matched using a wildcard search.
	.PARAMETER RegEx
		Specifies that the named application must be matched using a regular expression search.
	.PARAMETER ProductCode
		The product code of the application to retrieve information for.
	.PARAMETER UpgradeCode
		The upgrade code of the application to retrieve information for.
	.PARAMETER IncludeUpdatesAndHotfixes
		Include matches against updates and hotfixes in results.
	.PARAMETER IncludeCurrentUser
		Include searching for installed applications in the CurrentUser registry hive.
	.EXAMPLE
		Get-InstalledApplication -Name 'Adobe Flash'
	.EXAMPLE
		Get-InstalledApplication -ProductCode '{1AD147D0-BE0E-3D6C-AC11-64F6DC4163F1}'
	.NOTES
	.LINK
		http://psappdeploytoolkit.com
	#>
		[CmdletBinding()]
		Param (
			[Parameter(Mandatory=$false)]
			[ValidateNotNullorEmpty()]
			[string[]]$Name,
			[Parameter(Mandatory=$false)]
			[switch]$Exact = $false,
			[Parameter(Mandatory=$false)]
			[switch]$WildCard = $false,
			[Parameter(Mandatory=$false)]
			[switch]$RegEx = $false,
			[Parameter(Mandatory=$false)]
			[ValidateNotNullorEmpty()]
			[array]$ProductCode,
			[Parameter(Mandatory=$false)]
			[ValidateNotNullorEmpty()]
			[string]$UpgradeCode,
			[Parameter(Mandatory=$false)]
			[switch]$IncludeUpdatesAndHotfixes,
			[Parameter(Mandatory=$false)]
			[switch]$IncludeCurrentUser
		)
	
		Begin {
			## Get the name of this function and write header
			[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
			Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		}
		Process {
			$HKCUProductsKey = Get-Item -Path 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Installer\Products' -ErrorAction Ignore
			If ($HKCUProductsKey){[array]$CurrentUserMSIInstalledProducts = $HKCUProductsKey.GetSubKeyNames()}
			$HKLMProductsKey = Get-Item -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products' -ErrorAction Ignore
			If ($HKLMProductsKey){[array]$AllUsersMSIInstalledProducts = $HKLMProductsKey.GetSubKeyNames()}

			$SearchRegKeys = $regKeyApplications
			If ($IncludeCurrentUser) {
				$SearchRegKeys += 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall'
			}
			
			If ($name) {
				Write-Log -Message "Get information for installed Application Name(s) [$($name -join ', ')]..." -Source ${CmdletName}
			}
			If ($UpgradeCode) {
				Try {
					$FormattedInstallerUpgradeCode = ConvertTo-FormattedInstallerGuid -Guid $UpgradeCode
					$FormattedInstallerProductCodes = ((Get-Item -Path "Registry::HKEY_CLASSES_ROOT\Installer\UpgradeCodes\$FormattedInstallerUpgradeCode" -ErrorAction Stop).GetValueNames() -replace "^$", "(default)") | Where-Object {$_ -ne "(default)"}
					ForEach ($FormattedInstallerProductCode in $FormattedInstallerProductCodes){
						$ProductCode += ConvertFrom-FormattedInstallerGuid -FormattedGuid $FormattedInstallerProductCode
					}
				}
				Catch{
					Write-Log -Message "No installed product found based on the UpgradeCode $UpgradeCode" -Source ${CmdletName}
				}

			}
			If ($productCode) {
				Write-Log -Message "Get information for installed Product Code(s) [$($ProductCode -join ', ')]..." -Source ${CmdletName}
			}
	
			## Enumerate the installed applications from the registry for applications that have the "DisplayName" property
			[psobject[]]$regKeyApplication = @()
			ForEach ($regKey in $SearchRegKeys) {
				If (Test-Path -LiteralPath $regKey -ErrorAction 'SilentlyContinue' -ErrorVariable '+ErrorUninstallKeyPath') {
					[psobject[]]$UninstallKeyApps = Get-ChildItem -LiteralPath $regKey -ErrorAction 'SilentlyContinue' -ErrorVariable '+ErrorUninstallKeyPath'
					ForEach ($UninstallKeyApp in $UninstallKeyApps) {
						Try {
							[psobject]$regKeyApplicationProps = Get-ItemProperty -LiteralPath $UninstallKeyApp.PSPath -ErrorAction 'Stop'
							If ($regKeyApplicationProps.DisplayName) { [psobject[]]$regKeyApplication += $regKeyApplicationProps }
						}
						Catch{
							Write-Log -Message "Unable to enumerate properties from registry key path [$($UninstallKeyApp.PSPath)]. `n$(Resolve-Error)" -Severity 2 -Source ${CmdletName}
							Continue
						}
					}
				}
			}
			If ($ErrorUninstallKeyPath) {
				Write-Log -Message "The following error(s) took place while enumerating installed applications from the registry. `n$(Resolve-Error -ErrorRecord $ErrorUninstallKeyPath)" -Severity 2 -Source ${CmdletName}
			}
	
			$UpdatesSkippedCounter = 0
			## Create a custom object with the desired properties for the installed applications and sanitize property details
			[psobject[]]$installedApplication = @()
			ForEach ($regKeyApp in $regKeyApplication) {
				Try {
					[string]$appDisplayName = ''
					[string]$appDisplayVersion = ''
					[string]$appPublisher = ''
	
					## Bypass any updates or hotfixes
					If ((-not $IncludeUpdatesAndHotfixes) -and (($regKeyApp.DisplayName -match '(?i)kb\d+') -or ($regKeyApp.DisplayName -match 'Cumulative Update') -or ($regKeyApp.DisplayName -match 'Security Update') -or ($regKeyApp.DisplayName -match 'Hotfix'))) {
						$UpdatesSkippedCounter += 1
						Continue
					}
	
					## Remove any control characters which may interfere with logging and creating file path names from these variables
					$appDisplayName = $regKeyApp.DisplayName -replace '[^\u001F-\u007F]',''
					$appDisplayVersion = $regKeyApp.DisplayVersion -replace '[^\u001F-\u007F]',''
					$appPublisher = $regKeyApp.Publisher -replace '[^\u001F-\u007F]',''
	
	
					## Determine if application is a 64-bit application
					[boolean]$Is64BitApp = If (($is64Bit) -and ($regKeyApp.PSPath -notmatch '^Microsoft\.PowerShell\.Core\\Registry::HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node')) { $true } Else { $false }
					
					## Determine if application is a Windows Installer installed application
					[boolean]$IsMSI = If ($regKeyApp.WindowsInstaller -eq '1') {$True} Else {$False}

					## Determine the scope of the Install
					If ($regKeyApp.PSPath -match '^Microsoft\.PowerShell\.Core\\Registry::HKEY_CURRENT_USER') {
						$appScope = 'CurrentUser'
					}
					Else {
						If (!$IsMSI) {
							$appScope = 'AllUsers'
						}
						Else {
							$FormattedInstallerProductCode = ConvertTo-FormattedInstallerGuid -Guid $regKeyApp.PSChildName
							If ($FormattedInstallerProductCode -in $AllUsersMSIInstalledProducts) {
								$appScope = 'AllUsers'
							}
							ElseIf ($FormattedInstallerProductCode -in $CurrentUserMSIInstalledProducts) {
								$appScope = 'CurrentUser'
							}
							Else {
								#App is installed for a user on the machine but not for the current user. This can only be detected for MSI installs
								$appScope = 'OtherUser'
							}
						}
					}
	
					If ($ProductCode) {
						ForEach ($ProdCode in $ProductCode) {
						## Verify if there is a match with the product code passed to the script
							If ($regKeyApp.PSChildName -match [regex]::Escape($ProdCode)) {
								Write-Log -Message "Found installed application [$appDisplayName] version [$appDisplayVersion] matching product code [$ProdCode]." -Source ${CmdletName}
								$installedApplication += [PSCustomObject]@{
									UninstallSubkey = $regKeyApp.PSChildName
									ProductCode = If ($regKeyApp.PSChildName -match $MSIProductCodeRegExPattern) { $regKeyApp.PSChildName } Else { [string]::Empty }
									DisplayName = $appDisplayName
									DisplayVersion = $appDisplayVersion
									UninstallString = $regKeyApp.UninstallString
									QuietUninstallString = $regKeyApp.QuietUninstallString
									InstallSource = $regKeyApp.InstallSource
									InstallLocation = $regKeyApp.InstallLocation
									InstallDate = $regKeyApp.InstallDate
									InstallScope = $appScope
									Publisher = $appPublisher
									Is64BitApplication = $Is64BitApp
									IsWindowsInstaller = $IsMSI
									IsSystemComponent = If ($regKeyApp.SystemComponent -eq 1) {$True} Else {$False}
								}
							}
						}
					}
	
					If ($name) {
						## Verify if there is a match with the application name(s) passed to the script
						ForEach ($application in $Name) {
							$applicationMatched = $false
							If ($exact) {
								#  Check for an exact application name match (and that the application has not already been found by productcode)
								If ($regKeyApp.DisplayName -eq $application -and $regKeyApp.PSChildName -ne ($installedApplication | Where-Object {$_.UninstallSubkey -eq $regKeyApp.PSChildName -and $_.Is64BitApplication -eq $Is64BitApp}).UninstallSubKey) {
									$applicationMatched = $true
									Write-Log -Message "Found installed application [$appDisplayName] version [$appDisplayVersion] using exact name matching for search term [$application]." -Source ${CmdletName}
								}
							}
							ElseIf ($WildCard) {
								#  Check for wildcard application name match (and that the application has not already been found by productcode)
								If ($regKeyApp.DisplayName -like $application -and $regKeyApp.PSChildName -ne ($installedApplication | Where-Object {$_.UninstallSubkey -eq $regKeyApp.PSChildName -and $_.Is64BitApplication -eq $Is64BitApp}).UninstallSubKey) {
									$applicationMatched = $true
									Write-Log -Message "Found installed application [$appDisplayName] version [$appDisplayVersion] using wildcard matching for search term [$application]." -Source ${CmdletName}
								}
							}
							ElseIf ($RegEx) {
								#  Check for a regex application name match (and that the application has not already been found by productcode)
								If ($regKeyApp.DisplayName -match $application -and $regKeyApp.PSChildName -ne ($installedApplication | Where-Object {$_.UninstallSubkey -eq $regKeyApp.PSChildName -and $_.Is64BitApplication -eq $Is64BitApp}).UninstallSubKey) {
									$applicationMatched = $true
									Write-Log -Message "Found installed application [$appDisplayName] version [$appDisplayVersion] using regex matching for search term [$application]." -Source ${CmdletName}
								}
							}
							#  Check for a contains application name match (and that the application has not already been found by productcode)
							ElseIf ($regKeyApp.DisplayName -match [regex]::Escape($application) -and $regKeyApp.PSChildName -ne ($installedApplication | Where-Object {$_.UninstallSubkey -eq $regKeyApp.PSChildName -and $_.Is64BitApplication -eq $Is64BitApp}).UninstallSubKey) {
								$applicationMatched = $true
								Write-Log -Message "Found installed application [$appDisplayName] version [$appDisplayVersion] using contains matching for search term [$application]." -Source ${CmdletName}
							}
	
							If ($applicationMatched) {
								$installedApplication += [PSCustomObject]@{
									UninstallSubkey = $regKeyApp.PSChildName
									ProductCode = If ($regKeyApp.PSChildName -match $MSIProductCodeRegExPattern) { $regKeyApp.PSChildName } Else { [string]::Empty }
									DisplayName = $appDisplayName
									DisplayVersion = $appDisplayVersion
									UninstallString = $regKeyApp.UninstallString
									QuietUninstallString = $regKeyApp.QuietUninstallString
									InstallSource = $regKeyApp.InstallSource
									InstallLocation = $regKeyApp.InstallLocation
									InstallDate = $regKeyApp.InstallDate
									InstallScope = $appScope
									Publisher = $appPublisher
									Is64BitApplication = $Is64BitApp
									IsWindowsInstaller = $IsMSI
									IsSystemComponent = If ($regKeyApp.SystemComponent -eq 1) {$True} Else {$False}
								}
							}
						}
					}
				}
				Catch {
					Write-Log -Message "Failed to resolve application details from registry for [$appDisplayName]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
					Continue
				}
			}
	
			If (-not $IncludeUpdatesAndHotfixes) {
				## Write to log the number of entries skipped due to them being considered updates
				If ($UpdatesSkippedCounter -eq 1) {
					Write-Log -Message "Skipped 1 entry while searching, because it was considered a Microsoft update." -Source ${CmdletName}
				} else {
					Write-Log -Message "Skipped $UpdatesSkippedCounter entries while searching, because they were considered Microsoft updates." -Source ${CmdletName}
				}
			}
	
			If (-not $installedApplication) {
				Write-Log -Message "Found no application based on the supplied parameters." -Source ${CmdletName}
			}
	
			Write-Output -InputObject $installedApplication
		}
		End {
			Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
		}
	}
	#endregion

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
