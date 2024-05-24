function Install-Updates {

    # Record the start time
    $startTime = Get-Date

    Write-Host "`nWindows Updates`n"  -BackgroundColor White -ForegroundColor Black

    # Check if PSWindowsUpdate module is installed
    if (-not (Get-Module -Name PSWindowsUpdate -ListAvailable)) {
        # PSWindowsUpdate module is not installed, so download and install it
        Write-Host "Downloading and installing PSWindowsUpdate module..."
        Install-Module -Name PSWindowsUpdate -Force -Confirm:$false
    } else {
        Write-Host "PSWindowsUpdate module is already installed."
    }

    # Import PSWindowsUpdate module
    Import-Module PSWindowsUpdate

    # Loop until updates are successfully installed
    $retryCount = 0
    $maxRetries = 5
    while ($retryCount -lt $maxRetries) {
        try {
            $updates = Get-WindowsUpdate -Install -AcceptAll -Confirm:$false -IgnoreReboot -Verbose
            if ($null -eq $updates) {
                Write-Host "No updates found."
                break
            } else {
                Write-Host "Updates installed successfully."
                break
            }
        } catch {
            if ($_ -match "0x80240016") {
                Write-Host "Another installation is in progress or system restart is pending. Retrying..."
                Start-Sleep -Seconds 300  # Wait for 5 minutes before retrying
                $retryCount++
            } else {
                Write-Host "An error occurred while installing updates: $_"
                break
            }
        }
    }

    if ($retryCount -ge $maxRetries) {
        Write-Host "Failed to install updates after $maxRetries retries."
    }

    # Record the end time
    $endTime = Get-Date

    # Calculate the duration
    $duration = New-TimeSpan -Start $startTime -End $endTime

    # Write the total runtime to a text file
    $logFilePath = "C:\Logs\Install-Updates.log"  # Modify this path as needed
    "Total runtime: $($duration.Hours) hours, $($duration.Minutes) minutes, $($duration.Seconds) seconds" | Out-File -FilePath $logFilePath

}
