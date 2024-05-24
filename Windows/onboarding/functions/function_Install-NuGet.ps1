[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
function Install-NuGet {

    Write-Host "`nNuGet`n"  -BackgroundColor White -ForegroundColor Black
    $minimumVersion = [version]'2.8.5.201'
    $nuGetProviderName = "NuGet"
    
    try {
        # Check if NuGet provider is already installed and meets the minimum version
        $installedProvider = Get-PackageProvider -Name $nuGetProviderName -ErrorAction Stop
        if ($null -eq $installedProvider -or $installedProvider.Version -lt $minimumVersion) {
            # If not installed or does not meet the minimum version, install or update
            Install-PackageProvider -Name $nuGetProviderName -MinimumVersion $minimumVersion -Force -ErrorAction Stop
        }
        else {
            Write-Host "NuGet provider is already installed and meets the minimum version requirement." -ForegroundColor Green
        }
    }
    catch {
        Write-Error "Error occurred: $_"
    }
}
