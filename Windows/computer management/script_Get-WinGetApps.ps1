<#

Executive Summary:

The provided script automates the process of checking the availability of a list of applications using the Windows Package Manager (Winget). The script begins by defining an array of applications to be checked for availability. It then initializes two arrays to categorize available and unavailable applications. Using a loop, the script iterates through each application in the list and queries its availability using the 'winget show' command. If the application is not found, it is added to the list of unavailable applications; otherwise, it is added to the list of available applications. Finally, the script outputs the available and unavailable applications separately, providing a clear overview of which applications can be installed using the Windows Package Manager. The script is designed to streamline the process of checking application availability, offering convenience and efficiency for system administrators or users managing software installations on Windows systems.

#>

# BEGIN SCRIPT

# List of applications
$apps = @(
    "Google.Chrome"
    "Mozilla.Firefox"
    "Zoom.ZoomLauncher"
    "Python.Python.3"
    "Microsoft.Teams"
    "7zip.7zip"
    "VideoLAN.VLCMediaPlayer"
    "NotepadPlusPlus.NotepadPlusPlus"
    "Git.Git"
    "GoogleLLC.GoogleDrive"
    "Microsoft.Sysinternals"
    "Microsoft.VisualStudioCode"
    "JamSoftware.TreeSizeFree"
    "GNU.Wget"
    "Microsoft.WindowsTerminal"
    "Curl.Curl"
    "GIMP.GIMP"
    "MartinPikl.WinSCP"
    "SimonTatham.PuTTY"
    "KeePass.KeePass"
    "Wireshark.Wireshark"
    "OpenSource.PSWindowsUpdate"
    "JamSoftware.WinDirStat"
    "Greenshot.Greenshot"
    "Microsoft.WSL2"
    "Microsoft.WindowsAppSDK"
    "Facebook.Osquery"
)

# Initialize arrays for available and unavailable apps
$availableApps = @()
$unavailableApps = @()

# Loop through each app and check availability
foreach ($app in $apps) {
    Write-Host "Checking availability of $app..."
    $result = winget show --id $app 2>&1
    if ($result -like "*No package found*") {
        $unavailableApps += $app
    } else {
        $availableApps += $app
    }
}

# Output available apps
Write-Host "`nAvailable Applications:" -ForegroundColor Green
foreach ($app in $availableApps) {
    Write-Host $app
}

# Output unavailable apps
Write-Host "`nUnavailable Applications:" -ForegroundColor Red
foreach ($app in $unavailableApps) {
    Write-Host $app
}
