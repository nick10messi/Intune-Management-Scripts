function Get-OfficeArchitecture {
    $office32Path = "${env:ProgramFiles(x86)}\Microsoft Office\root\Office16\WINWORD.EXE"
    $office64Path = "${env:ProgramFiles}\Microsoft Office\root\Office16\WINWORD.EXE"

    if (Test-Path $office64Path) {
        Write-Output "Office x64 is installed"
    } elseif (Test-Path $office32Path) {
        Write-Output "Office x86 is installed"
    } else {
        Write-Output "No Office installation detected"
    }
}

# Run the function
Get-OfficeArchitecture