# Devices only registered in Azure AD but not enrolled in Intune do NOT count toward the limit.

# Install the required modules if not already installed
# Install-Module -Name Microsoft.Graph -Scope CurrentUser

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All User.Read.All"

# Function to get the number of devices per user
function Get-IntuneDeviceCounts {
    Write-Host "Fetching users and their enrolled devices..." -ForegroundColor Cyan

    # Get all users
    $users = Get-MgUser -All

    $deviceCounts = @()

    foreach ($user in $users) {
        try {
            # Get the devices for the user
            $devices = Get-MgDeviceManagementManagedDevice -Filter "userPrincipalName eq '$($user.UserPrincipalName)'"

            # Add the user and device count to the result array
            $deviceCounts += [PSCustomObject]@{
                UserPrincipalName = $user.UserPrincipalName
                DisplayName       = $user.DisplayName
                DeviceCount       = $devices.Count
            }
        } catch {
            Write-Host "Error retrieving devices for user: $($user.UserPrincipalName)" -ForegroundColor Red
        }
    }

    # Return the result
    return $deviceCounts
}

# Run the function and store results
$results = Get-IntuneDeviceCounts

# Output results to console
$results | Sort-Object -Property DeviceCount -Descending | Format-Table -AutoSize

# Optionally export to a CSV file
$results | Export-Csv -Path "IntuneDeviceCounts.csv" -NoTypeInformation -Encoding UTF8

Write-Host "Device count report exported to 'IntuneDeviceCounts.csv'" -ForegroundColor Green