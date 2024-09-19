Import-Module Microsoft.Graph.DeviceManagement.Actions

Connect-Mggraph -scopes DeviceManagementManagedDevices.ReadWrite.All, DeviceManagementManagedDevices.PrivilegedOperations.All

$alldevices = get-MgDeviceManagementManagedDevice -All | Where-Object {$_.OperatingSystem -eq "Windows"}

Foreach ($device in $alldevices) {
    Sync-MgDeviceManagementManagedDevice -ManagedDeviceId $device.id
    write-host "Sending device sync request to" $device.DeviceName -ForegroundColor yellow
}