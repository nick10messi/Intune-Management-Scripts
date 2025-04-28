$hasPackageManager = Get-AppPackage -name 'Microsoft.DesktopAppInstaller'
if (!$hasPackageManager -or [version]$hasPackageManager.Version -lt [version]"1.10.0.0") {
    "Installing winget Dependencies"
    Add-AppxPackage -Path 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx'
    $releases_url = 'https://api.github.com/repos/microsoft/winget-cli/releases/latest'

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $releases = Invoke-RestMethod -uri $releases_url
    $latestRelease = $releases.assets | Where { $_.browser_download_url.EndsWith('msixbundle') } | Select -First 1

    "Installing winget from $($latestRelease.browser_download_url)"
    Add-AppxPackage -Path $latestRelease.browser_download_url
}
else {
    "winget already installed"
}
#### Creating settings.json #####

if ([System.Security.Principal.WindowsIdentity]::GetCurrent().IsSystem) {
        $SettingsPath = "$Env:windir\system32\config\systemprofile\AppData\Local\Microsoft\WinGet\Settings\settings.json"
    }else{
        $SettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json"
    }
    if (Test-Path $SettingsPath){
        $ConfigFile = Get-Content -Path $SettingsPath | Where-Object {$_ -notmatch '//'} | ConvertFrom-Json
    }
    if (!$ConfigFile){
        $ConfigFile = @{}
    }
    if ($ConfigFile.installBehavior.preferences.scope){
        $ConfigFile.installBehavior.preferences.scope = "Machine"
    }else {
        Add-Member -InputObject $ConfigFile -MemberType NoteProperty -Name 'installBehavior' -Value $(
            New-Object PSObject -Property $(@{preferences = $(
                    New-Object PSObject -Property $(@{scope = "Machine"}))
            })
        ) -Force
    }
    $ConfigFile | ConvertTo-Json | Out-File $SettingsPath -Encoding utf8 -Force

# Install Company Portal
winget install --id 9WZDNCRFJ3PZ --source msstore -e --silent --accept-package-agreements --accept-source-agreements