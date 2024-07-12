function Invoke-Speedtest {
    param (
        [string]$Mode
    )

    $downloadUrl = "https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-win64.zip"
    $destinationDirectory = "C:\Temp"
    $resultsDirectory = "C:\Temp"

    $currentDateTime = Get-Date -Format "yyyyMMdd_HHmmss"

    if ($Mode -eq "local") {
        $computerName = $env:COMPUTERNAME
    } elseif ($Mode -eq "remote") {
        $computerName = Read-Host "Enter the computer name where you want to run the Speedtest"
        $cred = Get-Credential
    } else {
        Write-Host "Invalid mode. Please specify 'local' or 'remote'."
        exit 1
    }

    $resultsFileName = "speedtest_results_${computerName}_${currentDateTime}.txt"
    $resultsFile = Join-Path -Path $resultsDirectory -ChildPath $resultsFileName

    # Download Speedtest CLI
    Write-Host "Downloading Speedtest CLI..."
    Invoke-WebRequest -Uri $downloadUrl -OutFile "$destinationDirectory\speedtest.zip" -ErrorAction Stop

    # Extract Speedtest CLI
    Write-Host "Extracting Speedtest CLI..."
    Expand-Archive -Path "$destinationDirectory\speedtest.zip" -DestinationPath $destinationDirectory -Force -ErrorAction Stop

    # Run Speedtest
    Write-Host "Running Speedtest..."
    $speedtestExe = "$destinationDirectory\speedtest.exe"
    $confirmation = "YES"
    $speedtestArgs = "--accept-license=$confirmation"

    if ($Mode -eq "remote") {
        Write-Host "Copying Speedtest executable to $computerName..."
        $remoteExePath = "\\$computerName\C$\Temp\speedtest.exe"
        New-PSDrive -Name RemoteTemp -PSProvider FileSystem -Root "\\$computerName\C$\Temp" -Credential $cred | Out-Null
        Copy-Item -Path $speedtestExe -Destination $remoteExePath -Force -ErrorAction Stop
        Remove-PSDrive -Name RemoteTemp

        $scriptBlock = {
            param($exePath, $confirm, $resFile)
            Start-Process -FilePath $exePath -ArgumentList $confirm -Wait -RedirectStandardOutput $resFile -ErrorAction Stop
        }
        Invoke-Command -ComputerName $computerName -ScriptBlock $scriptBlock -ArgumentList $remoteExePath, $speedtestArgs, $resultsFile

        # Remove Speedtest executable from remote machine
        Invoke-Command -ComputerName $computerName -ScriptBlock {
            param($file)
            Remove-Item -Path $file -Force -ErrorAction Stop
        } -ArgumentList $remoteExePath -Credential $cred
    } else {
        Start-Process -FilePath $speedtestExe -ArgumentList $speedtestArgs -NoNewWindow -Wait -RedirectStandardOutput $resultsFile -ErrorAction Stop
    }

    if ($Mode -eq "remote") {
        Write-Host "Speedtest results saved to: $resultsFile on $computerName"
    } else {
        Write-Host "Speedtest results saved to: $resultsFile"
    }

    # Clean up
    Remove-Item -Path "$destinationDirectory\speedtest.zip" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$destinationDirectory\speedtest.md" -Force -ErrorAction SilentlyContinue

    # Remove Speedtest executable from local machine
    Remove-Item -Path $speedtestExe -Force -ErrorAction SilentlyContinue

    # Open Notepad to display the results
    Start-Process notepad.exe -ArgumentList $resultsFile
}

# Prompt the user to select an option
$option = Read-Host @"
Select an option:
1. Run Speedtest against local machine
2. Run Speedtest against remote machine
"@

# Execute the corresponding function based on the user's selection
switch ($option) {
    1 { Invoke-Speedtest -Mode "local" }
    2 { Invoke-Speedtest -Mode "remote" }
    default { Write-Host "Invalid option. Please select 1 or 2." }
}
