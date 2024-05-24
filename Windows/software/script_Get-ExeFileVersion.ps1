<#

Executive Summary:

The script is designed to remotely check for the version of a specific EXE file (`CSFalconService.exe`) on multiple machines. It provides flexibility by allowing the user to choose between querying Active Directory or providing a text file with the list of machines. After obtaining the list of machines, it tests connectivity, establishes a WinRM connection, checks for the EXE file version, and creates a report containing the computer name, file path, and version. Optionally, the results can be exported to a CSV file or displayed in the console. This script streamlines the process of monitoring the version of a critical EXE file across multiple machines in a network environment.

Details:

Defines a function `Get-RemoteExeFileVersion` to check for the existence of an EXE file and report its version on a remote machine.
Defines a function `Get-ADComputers` to retrieve a list of enabled computers from Active Directory.
Defines a function `Get-TextFileComputers` to retrieve a list of machines from a text file.
Defines the main function `Get-ExeFileVersion` to query machines, test connectivity, and check for the EXE file version.
Prompts the user to choose between querying Active Directory or providing a text file for the list of machines.
Retrieves the list of machines based on the user's choice.
Tests connectivity to each machine and establishes a WinRM connection.
Checks for the existence and version of a specific EXE file (`C:\Program Files\Crowdstrike\CSFalconService.exe`) on each remote machine.
Creates a custom object with the computer name, modified file path, and file version.
Optionally exports the results to a CSV file or displays them in the console.

#>

# BEGIN SCRIPT

# Function to check for existence of an EXE file and report its version on a remote machine
function Get-RemoteExeFileVersion {
    param (
        [string]$ComputerName,
        [string]$ExePath
    )
    try {
        $versionOutput = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            param ($ExePath)
            $version = $null
            if (Test-Path $ExePath) {
                $version = (Get-Item $ExePath).VersionInfo.FileVersion
            }
            return $version
        } -ArgumentList $ExePath
        return $versionOutput
    }
    catch {
        Write-Host "Failed to access or find the EXE file at $ExePath on $ComputerName."
    }
}
 
# Function to get list of machines from Active Directory
function Get-ADComputers {
    # Your Active Directory query to get enabled computers
    return Get-ADComputer -Filter {Enabled -eq $true} | Select-Object -ExpandProperty Name
}
 
# Function to get list of machines from a text file
function Get-TextFileComputers {
    param (
        [string]$FilePath
    )
    try {
        return Get-Content $FilePath
    }
    catch {
        Write-Host "Failed to read the text file at $FilePath."
        return @()
    }
}
 
# Main function to query machines, test connectivity, and check for the EXE file
function Get-ExeFileVersion {
    # Prompt user for list type (Active Directory or text file)
    $listType = Read-Host "To get list of computers: `n`n1 Query Active Directory `n2 Query text file `n`n Choose 1 or 2"
 
    # Get list of machines based on user input
    switch ($listType) {
        '1' {
            $computers = Get-ADComputers
        }
        '2' {
            $filePath = Read-Host "Enter the path to the text file containing the list of machines"
            $computers = Get-TextFileComputers -FilePath $filePath
        }
        default {
            Write-Host "Invalid input. Using Active Directory by default."
            $computers = Get-ADComputers
        }
    }
 
    # Check for the EXE file version on each machine
    $results = @()
    foreach ($computer in $computers) {
        # Test connectivity
        if (Test-Connection -ComputerName $computer -Count 1 -Quiet) {
            # Try to establish WinRM connection
            try {
                $session = New-PSSession -ComputerName $computer -ErrorAction Stop
                # Check for the EXE file version on the remote machine
                $exePath = Read-Host -Prompt "Add Path and Filename"
                $exeVersion = Invoke-Command -Session $session -ScriptBlock {
                    param ($ExePath)
                    if (Test-Path $ExePath) {
                        (Get-Item $ExePath).VersionInfo.FileVersion
                    }
                } -ArgumentList $exePath
                # Modify the ExePath to strip everything up to the last backslash
                $strippedExePath = $exePath -replace '.+\\', ''
                $result = [PSCustomObject]@{
                    ComputerName = $computer
                    Path = $strippedExePath  # Use the modified path
                    Version = $exeVersion
                }
                $results += $result
                Remove-PSSession $session
            } catch {
                Write-Host "Failed to connect to $computer via WinRM." -ForegroundColor Red
            }
        } else {
            Write-Host "Unable to ping $computer." -ForegroundColor Red
        }
    }
 
    # Export to CSV if user chooses
    $export = Read-Host "Do you want to save the results to CSV? (Y/N)"
    if ($export -eq "Y") {
        $outputPath = "C:\$strippedExePath" + "_Report-$((Get-Date).ToString('yyyy_MM_dd-HHmmss')).csv"
        $results | Export-Csv -Path $outputPath -NoTypeInformation
        Write-Host "Results exported to $outputPath"
    } else {
        # If not exporting to CSV, display the results in the console
        $results
    }
}
 
# Call the main function
Get-ExeFileVersion