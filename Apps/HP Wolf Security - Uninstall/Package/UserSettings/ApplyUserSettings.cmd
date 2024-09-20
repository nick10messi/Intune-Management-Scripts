@Echo Off
REM *** Version 1.1
REM *** Change log
REM *** 1.1
REM ***	   Improved file copying using RoboCopy.
REM ***    Files are now by default only copied is they don't exist.
REM ***    Solved issue with copying files to the documents folder.
 
pushd .
cd %~dp0..
for %%I in ("%CD%") do set PkgName=%%~nxI
popd

Title Importing User Settings for %PkgName%
Set LogFile="%TEMP%\UserSettings-%PkgName%.log"

Echo ************************************************************************** >> %LogFile%
Echo %Time% %Date%: Importing User Settings for %PkgName% >> %logFile%

REM *** Import Reg Files
FOR %%i IN ("%~dp0Registry\*.reg") DO (
Echo %Time% %Date%: Importing registry File %%i >> %LogFile%
reg import "%%i" 2>> %LogFile%
)
IF ERRORLEVEL 1 GOTO ERROR

REM *** Copy files to %APPDATA%
If EXIST "%~dp0AppDataRoaming\" (
Echo %Time% %Date%: Copying Files from %~dp0AppDataRoaming to %APPDATA% >> %LogFile%
RoboCopy "%~dp0AppDataRoaming" "%APPDATA%" /E /R:0 /Z /XO /XN 1>> %LogFile% 2>&1
REM If you want to always copy files replacing existing files remove the /XO and /XN parameters in the above command.
)
IF %ERRORLEVEL% GTR 7 GOTO ERROR 

REM *** Copy files to %LOCALAPPDATA%
If EXIST "%~dp0AppDataLocal\" (
Echo %Time% %Date%: Copying Files from %~dp0AppDataLocal to %LOCALAPPDATA% >> %LogFile%
RoboCopy "%~dp0AppDataLocal" "%LOCALAPPDATA%" /E /R:0 /Z /XO /XN 1>> %LogFile% 2>&1
REM If you want to always copy files replacing existing files remove the /XO and /XN parameters in the above command.
)
IF %ERRORLEVEL% GTR 7 GOTO ERROR 

REM *** Copy files to %LOCALAPPDATA%Low
If EXIST "%~dp0AppDataLocalLow\" (
Echo %Time% %Date%: Copying Files from %~dp0AppDataLocalLow to %LOCALAPPDATA%Low >> %LogFile%
RoboCopy "%~dp0AppDataLocalLow" "%LOCALAPPDATA%Low" /E /R:0 /Z /XO /XN 1>> %LogFile% 2>&1
REM If you want to always copy files replacing existing files remove the /XO and /XN parameters in the above command.
)
IF %ERRORLEVEL% GTR 7 GOTO ERROR  

REM *** Copy files to %USERPROFILE%
If EXIST "%~dp0Profile\" (
Echo %Time% %Date%: Copying Files from %~dp0Profile to %USERPROFILE% >> %LogFile%
RoboCopy "%~dp0Profile" "%USERPROFILE%" /E /R:0 /Z /XO /XN 1>> %LogFile% 2>&1
REM If you want to always copy files replacing existing files remove the /XO and /XN parameters in the above command.
)
IF %ERRORLEVEL% GTR 7 GOTO ERROR 

REM *** Copy files to User Documents Folder (Users documents location is determined by PS scriptlet).
for /f "delims=" %%a in ('powershell.exe -command "& {write-host $([Environment]::GetFolderPath('MyDocuments'))}"') do Set "DOCUMENTSFOLDER=%%a"
REM The line above only works correctly when not in the If statement below.
If EXIST "%~dp0Documents\" (
Echo %Time% %Date%: Copying Files from %~dp0Documents to %DOCUMENTSFOLDER% >> %LogFile%
RoboCopy "%~dp0Documents" "%DOCUMENTSFOLDER%" /E /R:0 /Z /XO /XN 1>> %LogFile% 2>&1
REM If you want to always copy files replacing existing files remove the /XO and /XN parameters in the above command.
)
IF %ERRORLEVEL% GTR 7 GOTO ERROR 

REM *** Copy files to User Desktop Folder (Users desktop location is determined by PS scriptlet).
for /f "delims=" %%a in ('powershell.exe -command "& {write-host $([Environment]::GetFolderPath('Desktop'))}"') do Set "DESKTOPFOLDER=%%a"
REM The line above only works correctly when not in the If statement below.
If EXIST "%~dp0Desktop\" (
Echo %Time% %Date%: Copying Files from %~dp0Desktop to %DESKTOPFOLDER% >> %LogFile%
RoboCopy "%~dp0Desktop" "%DESKTOPFOLDER%" /E /R:0 /Z /XO /XN 1>> %LogFile% 2>&1
REM If you want to always copy files replacing existing files remove the /XO and /XN parameters in the above command.
)
IF %ERRORLEVEL% GTR 7 GOTO ERROR

REM *** Copy files to %HOMEDRIVE%%HOMEPATH%
If EXIST "%~dp0HomePath\" (
Echo %Time% %Date%: Copying Files from %~dp0HomePath to %HOMEDRIVE%%HOMEPATH% >> %LogFile%
RoboCopy "%~dp0HomePath" "%HOMEDRIVE%%HOMEPATH%" /E /R:0 /Z /XO /XN 1>> %LogFile% 2>&1
REM If you want to always copy files replacing existing files remove the /XO and /XN parameters in the above command.
)
IF %ERRORLEVEL% GTR 7 GOTO ERROR  

REM *** Execute Command Files
FOR %%i IN ("%~dp0Scripts\*.cmd") DO (
Echo %Time% %Date%: Starting execution of Command File %%i >> %LogFile%
call "%%i" "%LogFile%"
)
IF ERRORLEVEL 1 GOTO ERROR

Echo ExitCode: %ERRORLEVEL% >> %logFile%
:END
Echo %Time% %Date%: Finished executing %0 >> %LogFile%
Echo ************************************************************************** >> %LogFile%

Exit /B %ERRORLEVEL%

:ERROR
Echo Error: %ERRORLEVEL% >> %logFile%
GOTO END