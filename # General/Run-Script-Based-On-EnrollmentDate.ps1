###################################################################################################################
### Check if device is enrolled after a specific date. Only then this script will be executed on a device. 
### You can specify this date in the $Desired_Date variable
###################################################################################################################

# Get the enrollment date of the device
Function GetRegDate ($path, $key){
    function GVl ($ar){
        return [uint32]('0x'+(($ar|ForEach-Object ToString X2) -join ''))
    }
    $ar=Get-ItemPropertyValue $path $key
    [array]::reverse($ar)
    $time = New-Object DateTime (GVl $ar[14..15]),(GVl $ar[12..13]),(GVl $ar[8..9]),(GVl $ar[6..7]),(GVl $ar[4..5]),(GVl $ar[2..3]),(GVl $ar[0..1])
    return $time
}
$RegKey = (@(Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Enrollments" -recurse | Where-Object {$_.PSChildName -like 'DeviceEnroller'}))
$RegPath = $($RegKey.name).TrimStart("HKEY_LOCAL_MACHINE")
$RegDate = GetRegDate HKLM:\$RegPath "FirstScheduleTimestamp"
$DeviceEnrolmentDate = Get-Date $RegDate -Format "yyyy/MM/dd"

# Specify the desired date of device enrollment to scope on which devices the script is executed
$Desired_Date = "2023-11-28"

# If the device enrollment date is greater than or equal to the desired date, then the script will be executed. 
# Device enrollments older than the desired date will be ignored
if ($DeviceEnrolmentDate -ge $Desired_Date) {
    Write-Host "Dit apparaat is vanaf 28-11-2023 ingespoeld. Script wordt uitgevoerd."
    $Remediate = $true
}
else {
    Write-Host "Dit apparaat is al eerder dan 28-11-2023 ingespoeld. Script wordt niet uitgevoerd"
    $Remediate =  $false
}