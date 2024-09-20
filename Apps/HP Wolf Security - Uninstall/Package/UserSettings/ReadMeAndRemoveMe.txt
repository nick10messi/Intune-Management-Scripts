!! Remove this folder if no usersettings have to be done for this package.
Remove this file if you don't want is to be placed at the client.

UserSettings.cmd will be executed by the Deploy-Application.ps1 powershell script for the currently logged on user (if applicable). Even when the powershell script is running in SYSTEM context.
The Deploy-Application.ps1 powershell script will also create an Active Setup action that will execute UserSettings.cmd once for every user that logs on to the client pc.

PersistSettings.cmd will be executed by the Deploy-Application.ps1 powershell script for the currently logged on user (if applicable). Even when the powershell script is running in SYSTEM context.
The Deploy-Application.ps1 powershell script will also create a Local Machine Run entry that will execute PersistSettings.cmd for every user each time that user logs on to the client pc.
Remove PersistSettings.cmd if you don't have have any settings that need to be set persistently. If PersistSettings.cmd does not exist no Local Machine Run entry will be made.

