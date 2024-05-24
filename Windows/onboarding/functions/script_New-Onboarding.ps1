# Prompt for admin privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    # Relaunch as admin
    Start-Process powershell -Verb RunAs -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"")
    exit
}

Function Show-Menu {
    Write-Host "Select an option:"
    Write-Host "1. New Computer"
    Write-Host "2. New User"
}

Function New-Onboarding {

    # Record the start time
    $startTime = Get-Date

    $logDirectory = "C:\Logs"

    # Check if the log directory exists
    if (-not (Test-Path -Path $logDirectory)) {
        # If it doesn't exist, create it
        New-Item -Path $logDirectory -ItemType Directory | Out-Null
    }

    Show-Menu
    $choice = Read-Host "Enter your choice"

    $scriptFolder = $PSScriptRoot

    switch ($choice) {
        "1" {
            $scriptPath = Get-ChildItem -Path $scriptFolder -Filter "function_New-Computer.ps1" -Recurse | Select-Object -ExpandProperty FullName -First 1
            if ($scriptPath) {
                . $scriptPath
                New-Computer
            } else {
                Write-Host "Script file not found."
            }
        }
        "2" {
            $scriptPath = Get-ChildItem -Path $scriptFolder -Filter "function_New-User.ps1" -Recurse | Select-Object -ExpandProperty FullName -First 1
            if ($scriptPath) {
                . $scriptPath
                New-User
            } else {
                Write-Host "Script file not found."
            }
        }
        
        Default { Write-Host "Invalid choice" }
    }

    # Record the end time
    $endTime = Get-Date

    # Calculate the duration
    $duration = New-TimeSpan -Start $startTime -End $endTime

    # Write the total runtime to a text file
    $logFilePath = "$logDirectory\New-Onboarding.log"  # Modify this path as needed
    "Total runtime: $($duration.Hours) hours, $($duration.Minutes) minutes, $($duration.Seconds) seconds" | Out-File -FilePath $logFilePath
}

New-Onboarding
