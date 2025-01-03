try {
	if(-NOT (Test-Path -LiteralPath "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power")){ 
        Write-Output "Regpath does not exsist"
        Exit 1
    };
if((Get-ItemPropertyValue -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name 'HiberbootEnabled' -ea SilentlyContinue) -eq 0) {  

} else { 
    Write-Output "Registry key or value is not compliant."
    Exit 2
    };
}
catch { 
    Write-Output "Registry key or value is not compliant."
    Exit 3
}
Exit 0