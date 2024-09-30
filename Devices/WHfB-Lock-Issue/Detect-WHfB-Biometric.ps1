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
    Write-Output "Registry path for PIN credential provider not found. Exiting script with status 1"
    exit 1
}
if(-NOT[string]::IsNullOrEmpty($loggedOnUserSID)) {

    # If multiple SID's are found in registry, look for the SID belonging to the logged on user
    if ($items.GetType().IsArray) {

        # LogonCredsAvailable needs to be set to 1, indicating that the credential provider is in use
        if ($items.Where({$_.PSChildName -eq $loggedOnUserSID}).LogonCredsAvailable -eq 1) {
            Write-Output "WHfB enabled"
            exit 0                    
        }

        # If LogonCredsAvailable is not set to 1, this will indicate that the PIN credential provider is not in use
        elseif ($items.Where({$_.PSChildName -eq $loggedOnUserSID}).LogonCredsAvailable -ne 1) {
            Write-Output "[Multiple SIDs]: Not good. PIN credential provider NOT found for LoggedOnUserSID. This indicates that the user is not enrolled into WHfB."
            exit 1
        }
        else {
            Write-Output "[Multiple SIDs]: Something is not right about the LoggedOnUserSID and the PIN credential provider. Needs investigation."
            exit 1
        }
    }

    # Looking for the SID belonging to the logged on user is slightly different if there's not mulitple SIDs found in registry
    else {
        if (($items.PSChildName -eq $loggedOnUserSID) -AND ($items.LogonCredsAvailable -eq 1)) {
            Write-Output "WHfB enabled"
            exit 0                    
        }
        elseif (($items.PSChildName -eq $loggedOnUserSID) -AND ($items.LogonCredsAvailable -ne 1)) {
            Write-Output "[Single SID]: Not good. PIN credential provider NOT found for LoggedOnUserSID. This indicates that the user is not enrolled into WHfB."
            exit 1
        }
        else {
            Write-Output "[Single SID]: Something is not right about the LoggedOnUserSID and the PIN credential provider. Needs investigation."
            exit 1
        }
    }
}
else {
    Write-Output "Could not retrieve SID for the logged on user. Exiting script with status 1"
    exit 1
}    
}

function WHfB-FaceLogon-Capable {
    $facelogonKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\FaceLogon"
    $facelogonName = "Capable"
    
    # First, check if the key exists
    if (Test-Path $facelogonKey) {

        # Try to retrieve the value of 'Capable' if it exists
        $capableValue = Get-ItemProperty -Path $facelogonKey -ErrorAction SilentlyContinue
    
        # Check if the 'Capable' property exists
        if ($capableValue.PSObject.Properties[$facelogonName]) {
            if ($capableValue.$facelogonName -eq 1) {
                Write-Output "Device is capable for Face logon"
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
    $fingerprintlogonKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\FingerprintLogon"
    $fingerprintlogonName = "Capable"
    
    # First, check if the key exists
    if (Test-Path $fingerprintlogonKey) {

        # Try to retrieve the value of 'Capable' if it exists
        $capableValue = Get-ItemProperty -Path $fingerprintlogonKey -ErrorAction SilentlyContinue
    
        # Check if the 'Capable' property exists
        if ($capableValue.PSObject.Properties[$fingerprintlogonName]) {
            if ($capableValue.$fingerprintlogonName -eq 1) {
                Write-Output "Device is capable for Fingerprint logon"
            } else {
                Write-Output "Device is NOT capable for Fingerprint logon"
            }
        } else {
            Write-Output "'Capable' property does not exist. Device does not support Fingerprint logon."
        }
    } else {
        Write-Output "Fingerprint logon registry key not found."
    } 
}

function WHfB-FaceLogon-Active {
    $facelogonActiveKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\FaceLogonEnrolledUsers"
    $facelogonActiveName = "Capable"
}

# Determine Windows Hello for Business status
if ((((WHfB-Enabled-Logged-In-User) -eq "WHfB enabled") -AND ((WHfB-FaceLogon-Capable) -eq "Device is capable for Face logon")) -AND (WHfB-FingerprintLogon-Capable) -eq "Device is capable for Fingerprint logon") {
    Write-Output "WHfB Enabled + face and finger capable"
}
elseif (<#condition#>) {
    <# Action when this condition is true #>
}