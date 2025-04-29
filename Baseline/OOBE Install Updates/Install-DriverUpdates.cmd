pushd %~dp0
powershell.exe -ExecutionPolicy Bypass -File ".\Install-Drivers.ps1"
pause