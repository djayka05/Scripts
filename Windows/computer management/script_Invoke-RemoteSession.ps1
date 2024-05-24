<#

Executive Summary:

This PowerShell script facilitates the remote retrieval of Local Administrator Password Solution (LAPS) passwords for specified computers. The LAPS password is used to ensure efficient and secure access to administrative accounts across multiple machines running LAPS.

Key features include:

Installation of Required Modules and Tools: 
The script checks and installs the LAPS PowerShell module and RSAT Active Directory Tools if they are not already installed.

Remote Session Initiation: 
It defines the Invoke-LapsRemoteSession function to initiate remote PowerShell sessions using LAPS passwords. It prompts the user for the LAPS admin username and offers options to:

Get all enabled computers from Active Directory.
Retrieve machine names from a text file.
Input a specific computer name.

Session Management: 
The script maintains a list of active sessions ($sessionList) and provides option #4 to terminate all active sessions when administrator is done administering the machines.

Functionality for Each Option:

For option 1 and 2, it pings each specified machine, initiates a remote session if reachable, and retrieves the LAPS password.
For option 3, it prompts the user for a computer name, pings it, and initiates a remote session if reachable.
For option 4, it terminates all active sessions.

User Interaction: 
The script prompts the user to select an option and provides feedback on the status of each operation, including successful or failed pings and session initiation.

Post-Execution Guidance: 
After completion, it provides instructions for viewing the list of active sessions and interacting with them.

This script offers a comprehensive solution for managing LAPS passwords remotely, 

#>

function Install-LAPS {
    # Check if LAPS PowerShell module is installed
    if (-not (Get-Module -Name AdmPwd.PS -ListAvailable)) {
        # If not installed, install LAPS Management tools
        Write-Host "LAPS PowerShell module not found. Installing..." -ForegroundColor Yellow
        msiexec.exe /i "https://download.microsoft.com/download/C/7/A/C7AAD914-A8A6-4904-88A1-29E657445D03/LAPS.x64.msi" ADDLOCAL=Management,Management.UI,Management.PS,Management.ADMX ALLUSERS=1 /qn
    } 
    else {
        Write-Host "LAPS PowerShell module is already installed." -ForegroundColor Green
    }
}

function Install-RSAT {
    # Check if RSAT Active Directory Tools are installed
    $rsatInstalled = Get-WindowsCapability -Online | Where-Object { $_.Name -like 'Rsat.ActiveDirectory*' } | Select-Object -ExpandProperty State

    if ($rsatInstalled -ne 'Installed') {
        # Check the operating system version
        $osVersion = (Get-WmiObject -Class Win32_OperatingSystem).Caption

        if ($osVersion -like '*Server*') {
            # Install server version of RSAT Active Directory Tools
            Add-WindowsFeature RSAT-AD-PowerShell
        }
        else {
            # Install workstation version of RSAT Active Directory Tools
            Add-WindowsCapability -Online -Name Rsat.ActiveDirectory*
        }
    }
}

function Invoke-LapsRemoteSession {
    param (
        [string]$ComputerName,
        [string]$AdminUsername,
        [ref]$sessionList
    )

    # Check and install RSAT Active Directory Tools
    Install-RSAT

    # Check and install LAPS modules
    Install-LAPS

    try {
        # Query LAPS password in Active Directory
        $LapsPassword = Get-AdmPwdPassword -ComputerName $ComputerName -ErrorAction Stop

        if ($LapsPassword -and $LapsPassword.Password) {
            # Convert the LAPS password to SecureString
            $SecurePassword = ConvertTo-SecureString $LapsPassword.Password -AsPlainText -Force

            # Create PSCredential object
            $credential = New-Object System.Management.Automation.PSCredential ($AdminUsername, $SecurePassword)

            # Open remote session
            $session = New-PSSession -ComputerName $ComputerName -Credential $credential
            $sessionList.Value += $session
            Write-Host "Remote session to $ComputerName initiated." -ForegroundColor Green
        }
        else {
            Write-Host "Failed to retrieve LAPS password for $ComputerName." -ForegroundColor Red
        }
    }
    catch {
        Write-Host "Error: $_"
    }
}

# Function to ping a computer
function Test-ConnectionStatus {
    param (
        [string]$ComputerName
    )
    $ping = Test-Connection -ComputerName $ComputerName -Count 1 -Quiet
    return $ping
}

# Prompt for LAPS admin username
$AdminUsername = Read-Host -Prompt 'Enter the LAPS admin username'
$AdminUsername = ".\$AdminUsername"  # Prepend .\ to the provided username

# List to store active sessions
$sessionList = @()

# Invoke-RemoteSession function
function Invoke-RemoteSession {
    $choice = Read-Host -Prompt @"
Please select an option:

1. Get all enabled machines in Active Directory, ping them, and run the script against reachable machines.
2. Get machines from a text file, ping them, and run the script against reachable machines.
3. Input a computer name, ping it, and run the script against the reachable machine.
4. Terminate all active sessions.

Option
"@

    switch ($choice) {
        1 {
            # Get all enabled machines in Active Directory
            $computers = Get-ADComputer -Filter {Enabled -eq $true} | Select-Object -ExpandProperty Name
            foreach ($computer in $computers) {
                $pingStatus = Test-ConnectionStatus -ComputerName $computer
                if ($pingStatus) {
                    Write-Host ""
                    Write-Host "Ping successful for $computer. Initiating remote session..." -ForegroundColor Green
                    Invoke-LapsRemoteSession -ComputerName $computer -AdminUsername $AdminUsername -sessionList ([ref]$sessionList)
                }
                else {
                    Write-Host "Ping failed for $computer. Skipping..." -ForegroundColor Red
                }
            }
        }
        2 {
            # Get machines from a text file
            $filePath = Read-Host "Enter the path to the text file containing machine names"
            $computers = Get-Content $filePath
            foreach ($computer in $computers) {
                $pingStatus = Test-ConnectionStatus -ComputerName $computer
                if ($pingStatus) {
                    Write-Host ""
                    Write-Host "Ping successful for $computer. Initiating remote session..." -ForegroundColor Green
                    Invoke-LapsRemoteSession -ComputerName $computer -AdminUsername $AdminUsername -sessionList ([ref]$sessionList)
                }
                else {
                    Write-Host "Ping failed for $computer. Skipping..." -ForegroundColor Red
                }
            }
        }
        3 {
            # Input a computer name
            $computerName = Read-Host "Enter the computer name"
            $pingStatus = Test-ConnectionStatus -ComputerName $computerName
            if ($pingStatus) {
                Write-Host ""
                Write-Host "Ping successful for $computerName. Initiating remote session..." -ForegroundColor Green
                Invoke-LapsRemoteSession -ComputerName $computerName -AdminUsername $AdminUsername -sessionList ([ref]$sessionList)
            }
            else {
                Write-Host "Ping failed for $computerName. Exiting..." -ForegroundColor Red
            }
        }
        4 {
            # Terminate all active sessions
            foreach ($session in $sessionList) {
            Write-Host "Terminating session $($session.ComputerName)..." -ForegroundColor Yellow
            Remove-PSSession -Session $session
    }
                Write-Host ""
                Write-Host "All sessions terminated." -ForegroundColor Green
            break  # Add this line to exit the loop after terminating sessions
}
            default {
                Write-Host "Invalid option selected. Exiting..." -ForegroundColor Red
        }
    }
}

Invoke-RemoteSession

Write-Host ""
Write-Host 'Get list of active sessions, type $sessionList.' -ForegroundColor Green
Write-Host 'To interact with the session, type Enter-PSSession -Id #' -ForegroundColor Green
