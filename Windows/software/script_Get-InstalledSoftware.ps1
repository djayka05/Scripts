<# 

This script provides a convenient way to retrieve installed software information from either the local machine or remote machines, taking into account different PowerShell versions and handling errors appropriately. 

#>

# BEGIN SCRIPT

# Function to check PowerShell version
function Get-PowerShellVersion {
    $PSVersionTable.PSVersion
}

# Function to query installed software using compatible commands
function Get-InstalledSoftware {
    param (
        [string]$ComputerName
    )

    $psVersion = Get-PowerShellVersion
    $packages = @()

    if ($psVersion.Major -ge 5) {
        # Using Get-Package cmdlet available in PowerShell 5.0+
        try {
            $packages = Get-Package | Select-Object Name, Version
        }
        catch {
            Write-Host "Error occurred while retrieving software information: $_"
        }
    }
    else {
        # Using registry query for older PowerShell versions
        $softwareRegistryPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
        try {
            if ($ComputerName) {
                $registryKey = Get-ItemProperty -Path $softwareRegistryPath -ComputerName $ComputerName -ErrorAction Stop
            } else {
                $registryKey = Get-ItemProperty -Path $softwareRegistryPath -ErrorAction Stop
            }
            
            $packages = $registryKey | Where-Object { $_.DisplayName } | Select-Object DisplayName, DisplayVersion
        }
        catch {
            Write-Host "Error occurred while retrieving software information: $_"
        }

        if (-not $packages) {
            # Fallback to WMI query if registry query returns no results
            try {
                $wmiPackages = Get-WmiObject -Class Win32_Product -ComputerName $ComputerName -ErrorAction Stop | Select-Object Name, Version
                $packages = $wmiPackages | Where-Object { $null -ne $_.Name } | Select-Object @{Name='Name'; Expression={$_.Name}}, Name, Version
            }
            catch {
                Write-Host "Error occurred while retrieving software information using WMI: $_"
            }
        }
    }

    return $packages | Sort-Object Name | Select-Object Name, Version -Unique
}

# Prompt user to choose where to run the script
$choice = Read-Host "Do you want to query software on the local machine (L) or on remote machines (R)? [L/R]"

if ($choice -eq "L") {
    # Run script on local machine
    Write-Host "Installed software on local machine:"
    Get-InstalledSoftware -ComputerName $env:COMPUTERNAME
}
elseif ($choice -eq "R") {
    # Prompt user for list of remote machines
    $remoteMachines = @()
    $inputComplete = $false

    while (-not $inputComplete) {
        $machine = Read-Host "Enter the name of a remote machine (leave blank when done):"
        if ($machine -ne "") {
            $remoteMachines += $machine
        }
        else {
            $inputComplete = $true
        }
    }

    # Loop through each remote machine
    foreach ($machine in $remoteMachines) {
        Write-Host "Installed software on $($machine):"
        Get-InstalledSoftware -ComputerName $machine
        Write-Host ""
    }
}
else {
    Write-Host "Invalid choice. Please choose 'L' for local machine or 'R' for remote machines."
}