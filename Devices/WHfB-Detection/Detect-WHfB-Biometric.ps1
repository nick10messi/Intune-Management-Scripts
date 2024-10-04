function WHfB-Enabled-Logged-In-User {
# Getting the logged on user's SID
$loggedOnUserSID = ([System.Security.Principal.WindowsIdentity]::GetCurrent()).User.Value

# Registry path for the PIN credential provider
$credentialProvider = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Providers\{D6886603-9D2F-4EB2-B667-1971041FA96B}"
if (Test-Path -Path $credentialProvider) {
    $userSIDs = Get-ChildItem -Path $credentialProvider
    $items = $userSIDs | Foreach-Object { Get-ItemProperty $_.PsPath }
}
else {
    Write-Output "Registry path for PIN credential provider not found."
}
if(-NOT[string]::IsNullOrEmpty($loggedOnUserSID)) {

    # If multiple SID's are found in registry, look for the SID belonging to the logged on user
    if ($items.GetType().IsArray) {

        # LogonCredsAvailable needs to be set to 1, indicating that the credential provider is in use
        if ($items.Where({$_.PSChildName -eq $loggedOnUserSID}).LogonCredsAvailable -eq 1) {
            Write-Output "WHfB enabled"                
        }

        # If LogonCredsAvailable is not set to 1, this will indicate that the PIN credential provider is not in use
        elseif ($items.Where({$_.PSChildName -eq $loggedOnUserSID}).LogonCredsAvailable -ne 1) {
            Write-Output "[Multiple SIDs]: Not good. PIN credential provider NOT found for LoggedOnUserSID. This indicates that the user is not enrolled into WHfB."
        }
        else {
            Write-Output "[Multiple SIDs]: Something is not right about the LoggedOnUserSID and the PIN credential provider. Needs investigation."
        }
    }

    # Looking for the SID belonging to the logged on user is slightly different if there's not mulitple SIDs found in registry
    else {
        if (($items.PSChildName -eq $loggedOnUserSID) -AND ($items.LogonCredsAvailable -eq 1)) {
            Write-Output "WHfB enabled"                 
        }
        elseif (($items.PSChildName -eq $loggedOnUserSID) -AND ($items.LogonCredsAvailable -ne 1)) {
            Write-Output "[Single SID]: Not good. PIN credential provider NOT found for LoggedOnUserSID. This indicates that the user is not enrolled into WHfB."
        }
        else {
            Write-Output "[Single SID]: Something is not right about the LoggedOnUserSID and the PIN credential provider. Needs investigation."
        }
    }
}
else {
    Write-Output "Could not retrieve SID for the logged on user."
}    
}

function WHfB-FaceLogon-Capable {
    $facelogonKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\FaceLogon"
    $facelogonName = "DeviceCapable"
    
    # First, check if the key exists
    if (Test-Path $facelogonKey) {

        # Try to retrieve the value of 'Capable' if it exists
        $capableValue = Get-ItemProperty -Path $facelogonKey -ErrorAction SilentlyContinue
    
        # Check if the 'Capable' property exists
        if ($capableValue.PSObject.Properties[$facelogonName]) {
            if ($capableValue.$facelogonName -eq 1) {
                Write-Output "Face logon capable"
            } else {
                Write-Output "Device is NOT capable for Face logon"
            }
        } else {
            Write-Output "'Capable' property does not exist. Device does not support Face logon."
        }
    } else {
        Write-Output "Face logon registry key not found."
    }
    
}

function WHfB-FingerprintLogon-Capable {
    $fingerprintlogonDetection = Get-PnpDevice -class "biometric" -ErrorAction SilentlyContinue6 | Select-Object FriendlyName -ExpandProperty FriendlyName

    # Check if Fingerprint device has Fingerprint sensor
    if (($fingerprintlogonDetection) -like "*Fingerprint*") {
        Write-Output "Fingerprint logon capable"
    }
    else {
        Write-Output "Device is NOT capable for Fingerprint logon"
    }
}

function WHfB-FaceLogon-Active {
    # Getting the logged on user's SID
    $loggedOnUserSID = ([System.Security.Principal.WindowsIdentity]::GetCurrent()).User.Value

    $facelogonActiveKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\FaceLogonEnrolledUsers"
    $facelogonActiveName = $loggedOnUserSID

    # First, check if the key exists
    if (Test-Path $facelogonActiveKey) {

        # Try to retrieve the regproperty of the 'SID' property if it exists
        $facevalue = Get-ItemProperty -Path $facelogonActiveKey -ErrorAction SilentlyContinue
    
        # Check if the 'SID' property exists
        if ($facevalue.PSObject.Properties[$facelogonActiveName]) {
            if ($facevalue.$facelogonActiveName -eq 0) {
                Write-Output "Face Logon active"
            } else {
                Write-Output "Face Logon NOT active"
            }
        } else {
            Write-Output "'SID' property does not exist. Face logon NOT active."
        }
    } else {
        Write-Output "Face Logon registry key not found. Face logon NOT active."
    }
}

function WHfB-Fingerprint-Active {
    # Getting the logged on user's SID
    $loggedOnUserSID = ([System.Security.Principal.WindowsIdentity]::GetCurrent()).User.Value

    $fingerprintlogonActiveKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\FingerprintLogonEnrolledUsers"
    $fingerprintActiveName = $loggedOnUserSID

    # First, check if the key exists
    if (Test-Path $fingerprintlogonActiveKey) {

        # Try to retrieve the regproperty of the 'SID' property if it exists
        $fingerprintvalue = Get-ItemProperty -Path $fingerprintlogonActiveKey -ErrorAction SilentlyContinue
    
        # Check if the 'SID' property exists
        if ($fingerprintvalue.PSObject.Properties[$fingerprintActiveName]) {
            if ($fingerprintvalue.$fingerprintActiveName -eq 0) {
                Write-Output "Fingerprint Logon active"
            } else {
                Write-Output "Fingerprint Logon NOT active"
            }
        } else {
            Write-Output "'SID' property does not exist. Fingerprint logon NOT active."
        }
    } else {
        Write-Output "Fingerprint logon registry key not found. Fingerprint logon NOT active"
    } 
}

# Check if WHfB is enabled
if ((WHfB-Enabled-Logged-In-User) -eq "WHfB enabled") {
    Write-Output "WHfB is enabled."
} else {
    Write-Output "WHfB is not enabled."
    exit 0
}

# If neither face nor fingerprint are capable
if ((WHfB-FaceLogon-Capable) -ne "Face logon capable" -and (WHfB-FingerprintLogon-Capable) -ne "Fingerprint logon capable") {
    Write-Output "WHfB is enabled, but the device is not capable of either face logon nor fingerprint"
    exit 0
}

# If face is capable but not configured
if ((WHfB-FaceLogon-Capable) -eq "Face logon capable" -and (WHfB-FaceLogon-Active) -ne "Face logon active") {
    Write-Output "WHfB is enabled, the device is capable for face logon, but hasn't face logon configured"
    exit 1
}

# If face is capable and configured
if ((WHfB-FaceLogon-Capable) -eq "Face logon capable" -and (WHfB-FaceLogon-Active) -eq "Face logon active") {
    Write-Output "WHfB is enabled, the device is capable for face logon, and has face logon configured"
    exit 0
}

# If fingerprint is capable but not configured
if ((WHfB-FingerprintLogon-Capable) -eq "Fingerprint logon capable" -and (WHfB-Fingerprint-Active) -ne "Fingerprint logon active") {
    Write-Output "WHfB is enabled, the device is capable for fingerprint logon, but hasn't fingerprint logon configured."
    exit 1
}

# If fingerprint is capable and configured
if ((WHfB-FingerprintLogon-Capable) -eq "Fingerprint logon capable" -and (WHfB-Fingerprint-Active) -eq "Fingerprint logon active") {
    Write-Output "WHfB is enabled, the device is capable for fingerprint logon, and has fingerprint logon configured."
    exit 0
}