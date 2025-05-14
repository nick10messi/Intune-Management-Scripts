function Get-OfficeArchitecture {
    $officePaths = @(
        "HKLM:\SOFTWARE\Microsoft\Office",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office"
    )

    foreach ($path in $officePaths) {
        if (Test-Path $path) {
            $versions = Get-ChildItem -Path $path -Name | Where-Object { $_ -match "^\d+\.\d+$" }
            foreach ($version in $versions) {
                $bitnessKey = Join-Path -Path $path -ChildPath "$version\Outlook"
                if (Test-Path $bitnessKey) {
                    $bitness = Get-ItemProperty -Path $bitnessKey -Name "Bitness" -ErrorAction SilentlyContinue
                    if ($bitness.Bitness -eq "x86") {
                        Write-Output "Office x86 is installed"
                        return
                    } elseif ($bitness.Bitness -eq "x64") {
                        Write-Output "Office x64 is installed"
                        return
                    }
                }
            }
        }
    }

    Write-Output "No Office installation detected"
}

# Run the function
Get-OfficeArchitecture