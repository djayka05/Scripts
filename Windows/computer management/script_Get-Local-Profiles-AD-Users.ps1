<#

This script provides a comprehensive solution for managing user profiles either locally or across machines in an Active Directory environment. It does not delete. It strictly reports. The information produced by this report can help with decision making in determining which accounts should get purged. This works similarly to the popular tool DelProf2, but this script goes one step further in determining user last logon in AD or if account is enabled/disabled in AD. You also have the option of connecting to multiple machines and with DelProf2, you would need to deploy DelProf2 to multiple machines, then run its command to produce the info and enact a plan to delete.

User Choice Prompt:

Option 1: Running the script locally.
Option 2: Running the script against machines from Active Directory.

Option 1:

The script collects user profiles from the local machine (excluding common system profiles like Administrator, Public, Guest, etc.).
It retrieves additional user information from Active Directory (AD), such as the last logon date and account status.
It calculates and displays profile folder details like last modified date and size.

Option 2:

It prompts the user to provide a text file containing computer names or uses Active Directory for machine names.
The script attempts to establish a PowerShell session with each remote machine using provided credentials.
For each remote machine, it collects user profiles (excluding common system profiles) and retrieves user information from AD.
It calculates and displays profile folder details (last modified date and size) similar to the local run.
It handles errors like failed connections or access denied situations.

Error Handling:

The script includes error handling for various scenarios like connection failures, access denied errors, or invalid choices made by the user.

#>

# BEGIN SCRIPT

# Prompt the user to choose whether to run the script locally or against machines from Active Directory

$choice = Read-Host -Prompt "Choose an option:`n1. Run script locally`n2. Run script against machines from Active Directory `nOption"

if ($choice -eq "1") {

    # Run the script locally

    $excludedProfiles = @("Administrator", "Public", "Guest", "IEUser")
    $localMachine = $env:COMPUTERNAME
    $staleProfiles = Get-ChildItem -Path "C:\Users" -Directory | Where-Object { $_.Name -notin $excludedProfiles}

    foreach ($profile in $staleProfiles) {

        $username = $profile.Name  # Get the username from the folder name

        $user = Get-ADUser -Filter {SamAccountName -eq $username} -Properties LastLogonDate,Enabled -ErrorAction Stop

        if ($null -ne $user) {

            $status = if ($user.Enabled) { "Enabled" } else { "Disabled" }          
            $profilePath = Join-Path -Path "C:\Users" -ChildPath $profile.Name
            $profileSize = Get-ChildItem -Path $profilePath -Recurse | Measure-Object -Property Length -Sum | Select-Object -ExpandProperty Sum

            Write-Host  "Profile: $($user.SamAccountName) on $localMachine, AD Last Logon Date: $($user.LastLogonDate), AD Account Status: $status, Profile Folder Last Modified: $($profile.LastWriteTime), Profile Folder Size: $($profileSize / 1GB) GB" -ForegroundColor Green

        } else {

            Write-Host "Profile: $username on $localMachine, AD Last Logon Date: (not found in Active Directory), Profile Folder Last Modified: $($profile.LastWriteTime), Profile Folder Size: $($profileSize / 1GB) GB" -ForegroundColor Yellow

        }

    }

}

elseif ($choice -eq "2") {

    # Prompt user to provide a text file with computer names or use Active Directory

    $fileChoice = Read-Host -Prompt "Enter the path to a text file containing computer names"

    if (-not [string]::IsNullOrWhiteSpace($fileChoice)) {

        # Run the script using computer names from the text file

        try {

            $computers = Get-Content $fileChoice

        }

        catch {

            Write-Host "Error reading the file: $_" -ForegroundColor Red

            exit

        }

    } else {

        Write-Host "You must provide a path to a text file containing computer names. Exiting script." -ForegroundColor Red

        exit

    }

    $username = Read-Host -Prompt "Enter Username"
    $password = Read-Host -Prompt "Enter Password" -AsSecureString

    # Common profiles to exclude

    $excludedProfiles = @("Administrator", "Public", "Guest", "IEUser")

    foreach ($machine in $computers) {

        # Skip the local machine

        if ($machine -eq $env:COMPUTERNAME) {

            continue

        }

        $pingResult = Test-Connection -ComputerName $machine -Count 1 -Quiet

        if ($pingResult) {

            try {

                $session = New-PSSession -ComputerName $machine -Credential (New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $password) -ErrorAction Stop
                $staleProfiles = Invoke-Command -Session $session -ScriptBlock {

                    Get-ChildItem -Path "C:\Users" -Directory | Where-Object { $_.Name -notin $using:excludedProfiles } | Select-Object Name, LastWriteTime

                }

                Remove-PSSession -Session $session

                foreach ($profile in $staleProfiles) {
                    $username = ($profile.Name -split '\\')[-1]  # Extract username from folder path
                    $user = Get-ADUser -Filter {SamAccountName -eq $username} -Properties LastLogonDate,Enabled -ErrorAction SilentlyContinue
                        if ($null -ne $user) {
                        $status = if ($user.Enabled) { "Enabled" } else { "Disabled" }
                           $profilePath = Join-Path -Path "C:\Users" -ChildPath $profile.Name
                           $profileSize = Invoke-Command -ComputerName $machine -ScriptBlock {
                           $profilePath = Join-Path -Path "C:\Users" -ChildPath $using:profile.Name
                (Get-ChildItem -Path $profilePath -Recurse -File | Measure-Object -Property Length -Sum).Sum
        }

        Write-Host "Profile: $username on $machine, AD Last Logon Date: $($user.LastLogonDate), AD Account Status: $status, Profile Folder Last Modified: $($profile.LastWriteTime), Profile Folder Size: $($profileSize / 1GB) GB" -ForegroundColor Green
    }
    else {

        Write-Host "Profile: $username on $machine, AD Last Logon Date: (not found in Active Directory), Profile Folder Last Modified: $($profile.LastWriteTime)" -ForegroundColor Yellow
    }
}

            }

            catch [System.Management.Automation.Remoting.PSRemotingTransportException] {

                Write-Host "Failed to connect to $machine Access denied. Ensure the provided credentials have sufficient permissions." -ForegroundColor Red

            }

            catch {

                Write-Host "Failed to connect to $machine $_" -ForegroundColor Red

            }

        }

        else {

            Write-Host "Failed to ping $machine. It might be unreachable." -ForegroundColor Red

        }

    }

}

else {

    Write-Host "Invalid choice. Please select either option 1 or 2." -ForegroundColor Red

}