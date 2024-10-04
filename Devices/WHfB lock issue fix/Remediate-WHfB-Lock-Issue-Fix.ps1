# Define the registry path and value name
$RegPath = "HKCU:\Control Panel\Desktop"
$ValueName = "DelayLockInterval"

# Set the registry value to '0'
Set-ItemProperty -Path $RegPath -Name $ValueName -Value 0