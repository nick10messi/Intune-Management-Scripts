# Define the registry path and value name
$RegPath = "HKCU:\Control Panel\Desktop"
$ValueName = "DelayLockInterval"

# Try to read the registry value
try {
    $RegValue = Get-ItemProperty -Path $RegPath -Name $ValueName -ErrorAction Stop
    
    # Check if the value is '0'
    if ($RegValue.$ValueName -eq 0) {
        Write-Output "$ValueName has the right value: 0"
        exit 0
    } else {
        Write-Output "$ValueName has not the right value, going to remediate"
        exit 1
    }
}
catch {
    # If an error occurs (e.g., registry key or value does not exist), handle it here
    Write-Output "Registry property: $ValueName does not exist, going to remediate"
    exit 1
}
