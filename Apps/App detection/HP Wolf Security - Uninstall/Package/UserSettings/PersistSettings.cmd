@Echo Off
pushd .
cd %~dp0..
for %%I in ("%CD%") do set PkgName=%%~nxI
popd

Title Importing User Settings for %PkgName%
Set LogFile="%TEMP%\PersistUserSettings-%PkgName%.log"

Echo ************************************************************************** >> %LogFile%
Echo %Time% %Date%: Running %0 for %PkgName% >> %logFile%

REM *** Execute actions for persisting usersettings below.




Echo %Time% %Date%: Finished executing %0 >> %LogFile%
Echo ************************************************************************** >> %LogFile%