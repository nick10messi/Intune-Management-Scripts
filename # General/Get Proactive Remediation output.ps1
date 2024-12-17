$3 = Get-MgBetaDeviceManagementDeviceHealthScriptDeviceRunState -DeviceHealthScriptId '9414c234-775d-4377-826c-07fa4d81b5ca' -ExpandProperty "managedDevice" -Filter "(detectionState eq 'success')" 

$6 = $3 | Where-Object { -not [string]::IsNullOrEmpty($_.PreRemediationDetectionScriptOutput) }

$6.PreRemediationDetectionScriptOutput | Group-Object | Select-Object Name, @{Name="Count";Expression={$_.Count}}