# Define the registry path and value name
$RegPath = "HKCU:\ or HKLM:\"
$ValueName = "PROPERTY_NAME"

# Check if the registry value exists
if (Test-Path "$RegPath\$ValueName") {
    # Get the current value
    $RegValue = Get-ItemProperty -Path $RegPath -Name $ValueName

    # Check if the value is '0'
    if ($RegValue.$ValueName -eq 0) {
        Write-Output "$ValueName has the right value: 0"
        exit 0
    } else {
        Write-Output "$ValueName has not the right value, going to remediate"
        exit 1
    }
} else {
    Write-Output "Registry property: $ValueName does not exist, going to remediate"
    exit 1
}