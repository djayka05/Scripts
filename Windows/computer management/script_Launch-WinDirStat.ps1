<#

The PowerShell script prompts the user to input a computer name and a UNC path. It checks if WinDirStat is installed and, if not, installs it using Winget. After installation, it launches WinDirStat with the provided UNC path to analyze disk usage on the specified computer.

#>

# BEGIN SCRIPT

$Computer = Read-Host -Prompt "Paste or type Computername"
$Unc = Read-Host -Prompt "Paste or type UNC path"
$WinDirStatPath = "C:\Program Files (x86)\WinDirStat\WinDirStat.exe"

# Check if WinDirStat is installed
$windirstatInstalled = (winget list --id WinDirStat | Select-String 'WinDirStat')

if (-not $windirstatInstalled) {
    # Install WinDirStat using Winget
    Write-Host "WinDirStat is not installed. Installing..."
    winget install -e --id WinDirStat
}

Start-Process -FilePath "$WinDirStatPath" -ArgumentList "\\$Computer\$Unc"