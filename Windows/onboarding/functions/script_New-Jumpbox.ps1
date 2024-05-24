# Record the start time
$startTime = Get-Date

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "`nInstall NuGet`n" -BackgroundColor White -ForegroundColor Black

# Check if NuGet module is installed
if (-not (Get-Module -Name NuGet -ListAvailable)) {
    # NuGet module not installed, install it
    Install-Module -Name NuGet -Force -Confirm:$false
}
else {
    # NuGet module installed, update to the latest version
    Update-Module -Name NuGet -Force -Confirm:$false
}

$logDirectory = "C:\Logs"

# Check if the log directory exists
if (-not (Test-Path -Path $logDirectory)) {
    # If it doesn't exist, create it
    New-Item -Path $logDirectory -ItemType Directory | Out-Null
}

# Check if LAPS is installed, if not, install it
if (-not (Get-Module -ListAvailable -Name AdmPwd.PS)) {
    Write-Host "`nInstalling LAPS`n" -BackgroundColor White -ForegroundColor Black

    $logFilePath = "$logDirectory\LAPS.log"

    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"https://download.microsoft.com/download/C/7/A/C7AAD914-A8A6-4904-88A1-29E657445D03/LAPS.x64.msi`" ADDLOCAL=Management,Management.UI,Management.PS ALLUSERS=1 /passive /l*v `"$logFilePath`"" -Wait

    if (Get-Module -ListAvailable -Name AdmPwd.PS) {
        Write-Host "LAPS is installed." -ForegroundColor Green
    }
    else {
        Write-Host "LAPS installation failed. Please check the logs." -ForegroundColor Red
    }
}
else {
    Write-Host "LAPS is already installed." -ForegroundColor Green
}

# Check if Windows Admin Center is installed, if not, install it
if (-not (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -eq "Windows Admin Center"})) {
    Write-Host "`nInstalling Windows Admin Center`n" -BackgroundColor White -ForegroundColor Black

    $logFilePath = "$logDirectory\WindowsAdminCenter.log"

    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"https://download.microsoft.com/download/1/0/5/1059800B-F375-451C-B37E-758FFC7C8C8B/WindowsAdminCenter2311.msi`" SME_PORT=443 SSL_CERTIFICATE_OPTION=generate /passive /l*v `"$logFilePath`"" -Wait

    if (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -eq "Windows Admin Center"}) {
        Write-Host "Windows Admin Center is installed." -ForegroundColor Green
    }
    else {
        Write-Host "Windows Admin Center installation failed. Please check the logs." -ForegroundColor Red
    }
}
else {
    Write-Host "Windows Admin Center is already installed." -ForegroundColor Green
}

# Function to check if module is installed
function Test-ModuleInstalled {
    param (
        [string]$ModuleName
    )
    return $null -ne (Get-Module -Name $ModuleName -ListAvailable)
}

function Install-ModuleIfNotInstalled {
    param (
        [string]$ModuleName
    )
    Write-Host "Checking if $ModuleName is installed..." -ForegroundColor Yellow
    Write-Host "`n"
    if (-not (Test-ModuleInstalled $ModuleName)) {
        Write-Host "Module $ModuleName is not installed. Installing..." -ForegroundColor Green
        Write-Host "`n"

        try {
            Install-Module -Name $ModuleName -Force -Confirm:$false -ErrorAction Stop
        }
        catch {
            Write-Host "Failed to install $ModuleName $_" -ForegroundColor Red
            return
        }
    }
    else {
        Write-Host "`n$ModuleName is already installed. Moving on...`n" -ForegroundColor Green
    }
}

# Adding the PSGallery repo to the trusted repo list.
try {
    Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
}
catch {
    Write-Host "Failed to set PSGallery repository as trusted: $_" -ForegroundColor Red
}

# Check and install PowerShellGet module
Write-Host "`nInstall PowerShellGet Module`n" -BackgroundColor White -ForegroundColor Black
Install-ModuleIfNotInstalled -ModuleName "PowerShellGet"

# Check and install Azure PowerShell module
Write-Host "`nInstall Azure PowerShell Module`n" -BackgroundColor White -ForegroundColor Black
Install-ModuleIfNotInstalled -ModuleName "Az"

# Check and install Azure AD PowerShell module
Write-Host "`nInstall Azure AD PowerShell Module`n" -BackgroundColor White -ForegroundColor Black
Install-ModuleIfNotInstalled -ModuleName "AzureAD"

# Check and install Exchange Online PowerShell module
Write-Host "`nInstall Exchange Online PowerShell Module`n" -BackgroundColor White -ForegroundColor Black
Install-ModuleIfNotInstalled -ModuleName "ExchangeOnlineManagement"

Write-Host "`nInstall Chocolately`n" -BackgroundColor White -ForegroundColor Black

# Set execution policy, download and execute Chocolatey installation script
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install software packages using Chocolatey
$chocoPackages = @(
    "dotnetfx",
    "pwsh",
    "microsoft-windows-terminal",
    "sql-server-management-studio",
    "sysinternals",
    "vscode.install",
    "git.install",
    "7zip.install",
    "notepadplusplus.install",
    "python3",
    "googlechrome",
    "putty.install",
    "winscp.install",
    "wireshark",
    "treesizefree",
    "curl",
    "iperf3",
    "fiddler",
    "gpg4win",
    "mremoteng",
    "meld"
)

foreach ($package in $chocoPackages) {
    choco install $package -y
}

Write-Host "`nInstall RSAT`n" -BackgroundColor White -ForegroundColor Black

# Function to display job status
function Show-JobStatus {
    # Define ArrayList
    $jobTable = [System.Collections.ArrayList]::new()
    
    Get-Job | ForEach-Object {
        $job = $_
        $jobStatus = $job.State
        $jobName = $job.Name
        $jobId = $job.Id

        # Add job information to ArrayList
        [Void]$jobTable.Add([PSCustomObject]@{
            "JobName" = $jobName
            "Status" = $jobStatus
            "ID" = $jobId
        })
    }

    # Sort the ArrayList
    $sortedJobTable = $jobTable | Sort-Object Status

    # Output the sorted table
    $sortedJobTable | Format-Table -AutoSize
}

# Check if the computer is a server or workstation.
$os = Get-CimInstance -ClassName Win32_OperatingSystem

if ($os.ProductType -eq 3) {
    # For Windows Server operating systems, install RSAT features
    $RSATFeatures = Get-WindowsFeature | Where-Object {$_.Name -like "RSAT*"}
    $RSATFeatures | ForEach-Object {
        $RSATFeature = $_
        $RSATFeatureName = $RSATFeature.Name
        $JobName = "$($RSATFeature.DisplayName)"
        Start-Job -Name $JobName -ScriptBlock {
            param($FeatureName)
            Install-WindowsFeature -Name $FeatureName -IncludeAllSubFeature
        } -ArgumentList $RSATFeatureName
    }
}
else {
    # For Windows Client operating systems, install RSAT capabilities
    $RSATCapabilities = Get-WindowsCapability -Name RSAT* -Online
    $RSATCapabilities | ForEach-Object {
        $RSATCapability = $_
        $RSATCapabilityName = $RSATCapability.Name
        $JobName = "$($RSATCapability.DisplayName)"
        Start-Job -Name $JobName -ScriptBlock {
            param($CapabilityName)
            Add-WindowsCapability -Name $CapabilityName -Online
        } -ArgumentList $RSATCapabilityName
    }
}

# Monitor job status
while (Get-Job -State "Running") {
    Clear-Host
    Show-JobStatus
    Start-Sleep -Seconds 5
}

# Display final job status
Clear-Host
Show-JobStatus

# Record the end time
$endTime = Get-Date

# Calculate the duration
$duration = New-TimeSpan -Start $startTime -End $endTime

# Display the total runtime to the host
Write-Host "Total runtime: $($duration.Hours) hours, $($duration.Minutes) minutes, $($duration.Seconds) seconds"

# Write the total runtime to a text file
$logFilePath = "$logDirectory\New-Jumpbox.log"  # Modify this path as needed
"Total runtime: $($duration.Hours) hours, $($duration.Minutes) minutes, $($duration.Seconds) seconds" | Out-File -FilePath $logFilePath
