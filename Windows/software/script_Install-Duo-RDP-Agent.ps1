<#

https://help.duo.com/s/article/1090?language=en_US

#>

# BEGIN SCRIPT

# Variables
$folderPath = "C:\Downloads"
$hostname = Read-Host -Prompt "API hostname"
$ikey = Read-Host -Prompt "Integration key"
$skey = Read-Host -Prompt "Secret key"

# Create C:\Downloads if directory doesn't exist.
if (!(Test-Path $folderPath -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $folderPath
}

# Download latest Duo RDP agent.
Invoke-WebRequest "https://dl.duosecurity.com/DuoWinLogon_MSIs_Policies_and_Documentation-latest.zip" -OutFile "$folderPath\DuoWinLogon_MSIs_Policies_and_Documentation-latest.zip"

# After donwload, extract the contents to C:\Downloads\.
Expand-Archive "$folderPath\DuoWinLogon_MSIs_Policies_and_Documentation-latest.zip" -DestinationPath $folderPath

# After extracting ZIP, delete it.
Remove-Item -Path "$folderPath\DuoWinLogon_MSIs_Policies_and_Documentation-latest.zip"

# Install the agent.
# Check if Duo service is installed
$duoInstalled = Get-Service -Name DuoAuthService -ErrorAction SilentlyContinue

if ($duoInstalled) {
    # Duo is installed, update it
    msiexec.exe /i "$folderPath\DuoWindowsLogon64.msi" /qn
} else {
    # Duo is not installed, install it
    msiexec.exe /i "$folderPath\DuoWindowsLogon64.msi" /qn IKEY=$ikey SKEY=$skey HOST=$hostname FAILOPEN="#1"
}


