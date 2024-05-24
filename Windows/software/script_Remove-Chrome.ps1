<# 

This script provides a comprehensive approach to uninstalling Google Chrome, utilizing multiple methods to ensure the best chance of success while handling errors gracefully.

#>

# BEGIN SCRIPT

# Function to display error message
function Show-ErrorMessage {
    param (
        [string]$ErrorMessage
    )
    Write-Host "Error: $ErrorMessage" -ForegroundColor Red
}

# Check if Chrome is installed using WMI
function UninstallChromeUsingWMI {
    try {
        $chrome = Get-WmiObject -Class Win32_Product -ErrorAction Stop | Where-Object { $_.Name -like "Google Chrome*" }
        if ($chrome) {
            $chrome.Uninstall()
        } else {
            Show-ErrorMessage "Google Chrome not found using WMI."
            # Try using Get-CimInstance method if WMI fails
            UninstallChromeUsingCimInstance
        }
    } catch {
        Show-ErrorMessage "Failed to uninstall Chrome using WMI: $_"
        # Try using Get-CimInstance method if WMI fails
        UninstallChromeUsingCimInstance
    }
}

# Check if Chrome is installed using CIM instance
function UninstallChromeUsingCimInstance {
    try {
        $chrome = Get-CimInstance -ClassName Win32_Product -ErrorAction Stop | Where-Object { $_.Name -like "Google Chrome*" }
        if ($chrome) {
            $chrome.Uninstall()
        } else {
            Show-ErrorMessage "Google Chrome not found using CIM instance."
        }
    } catch {
        Show-ErrorMessage "Failed to uninstall Chrome using CIM instance: $_"
    }
}

# Check if Chrome is installed using Registry
function UninstallChromeUsingRegistry {
    try {
        $chromeUninstallKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"
        $chromeKey = Get-ChildItem $chromeUninstallKey -ErrorAction Stop | Where-Object { $_.GetValue("DisplayName") -like "Google Chrome*" }

        if ($chromeKey) {
            $uninstallString = $chromeKey.GetValue("UninstallString")
            if ($uninstallString) {
                $uninstallString = $uninstallString -replace "/I", "/S"  # Replace /I with /S for silent uninstallation
                Start-Process "cmd.exe" -ArgumentList "/c $uninstallString" -Wait
            } else {
                Show-ErrorMessage "Uninstall string not found in Registry."
            }
        } else {
            Show-ErrorMessage "Google Chrome not found in Registry."
        }
    } catch {
        Show-ErrorMessage "Failed to uninstall Chrome using Registry: $_"
    }
}

# Check if Chrome is installed using direct executable
function UninstallChromeUsingExecutable {
    try {
        $chromeUninstallPath32 = "${env:ProgramFiles(x86)}\Google\Chrome\Application\uninstall.exe"
        $chromeUninstallPath64 = "${env:ProgramFiles}\Google\Chrome\Application\uninstall.exe"
        
        if (Test-Path $chromeUninstallPath32) {
            Start-Process $chromeUninstallPath32 -ArgumentList "/S" -Wait
        } elseif (Test-Path $chromeUninstallPath64) {
            Start-Process $chromeUninstallPath64 -ArgumentList "/S" -Wait
        } else {
            Show-ErrorMessage "Google Chrome uninstallation executable not found."
        }
    } catch {
        Show-ErrorMessage "Failed to uninstall Chrome using direct executable: $_"
    }
}

# Check the environment and use appropriate method to uninstall Chrome
if (Test-Path "$env:ProgramFiles(x86)\Google\Chrome\Application\chrome.exe" -or Test-Path "$env:ProgramFiles\Google\Chrome\Application\chrome.exe") {
    UninstallChromeUsingExecutable
} elseif (Get-WmiObject -Class Win32_Product -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "Google Chrome*" }) {
    UninstallChromeUsingWMI
} else {
    UninstallChromeUsingRegistry
}
