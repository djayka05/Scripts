<#

Here's a brief overview of each function and the main script:

Is-ComputerEnabled: This function takes a computer name as input and checks if the computer is enabled in Active Directory by querying AD with the Get-ADComputer cmdlet.

Test-ComputerConnection: This function checks if a computer is pingable using the Test-Connection cmdlet.

Get-SingleComputer: This function prompts the user to enter a single computer name.

Get-ComputersFromFile: This function prompts the user to enter the path to a text file containing computer names and reads the contents of the file. It checks if the file exists and returns the list of computer names.

Main Script: The main script prompts the user to choose between entering a single computer name or providing a text file containing a list of computer names. Depending on the choice, it either calls Get-SingleComputer or Get-ComputersFromFile to obtain the list of computers. Then, it iterates over each computer, checks if it's enabled in Active Directory and pingable, and if so, retrieves the last boot-up time using Invoke-Command and Get-CimInstance.
#>

# Function to check if a computer is enabled in Active Directory
function Get-ComputerEnabled {
    param (
        [string]$computerName
    )
    $adComputer = Get-ADComputer -Filter {Name -eq $computerName}
    if ($null -ne $adComputer) {
        return $adComputer.Enabled
    } else {
        return $false
    }
}

# Function to check if a computer is pingable
function Test-ComputerConnection {
    param (
        [string]$computerName
    )
    $ping = Test-Connection -ComputerName $computerName -Count 1 -Quiet
    return $ping
}

# Function to prompt for a single computer name
function Get-SingleComputer {
    $computer = Read-Host -Prompt "Enter the computer name"
    return $computer
}

# Function to get computers from a text file
function Get-ComputersFromFile {
    $filePath = Read-Host -Prompt "Enter the path to the text file containing computer names"
    if (Test-Path $filePath) {
        $computers = Get-Content $filePath
        return $computers
    } else {
        Write-Host "File not found!"
        exit
    }
}

# Main script
$choice = Read-Host -Prompt "Choose option:`n1. Single computer`n2. List of computers in a text file"

switch ($choice) {
    1 {
        $computers = Get-SingleComputer
    }
    2 {
        $computers = Get-ComputersFromFile
    }
    default {
        Write-Host "Invalid choice! Exiting."
        exit
    }
}

# Filter enabled computers and check if pingable before running the command
foreach ($computer in $computers) {
    if (Is-ComputerEnabled -computerName $computer) {
        if (Test-ComputerConnection -computerName $computer) {
            Invoke-Command -ComputerName $computer -ScriptBlock {
                Get-CimInstance -Class Win32_OperatingSystem | Select-Object LastBootUpTime
            }
        } else {
            Write-Host "$computer is not pingable. Skipping..."
        }
    } else {
        Write-Host "$computer is not enabled in Active Directory. Skipping..."
    }
}
