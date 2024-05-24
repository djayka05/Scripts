# Function to check if a computer is enabled in Active Directory
function Get-ComputerEnabled {
    param (
        [string]$computerName
    )
    $adComputer = Get-ADComputer -Identity $computerName -Properties Enabled
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

# Function to get computers from Active Directory
function Get-ADComputers {
    $computers = Get-ADComputer -Filter {Enabled -eq $true} | Select-Object -ExpandProperty Name
    return $computers
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

# Function to prompt for a single computer name
function Get-SingleComputer {
    $computer = Read-Host -Prompt "Enter the computer name"
    return $computer
}

# Main script
$choice = Read-Host -Prompt "Choose option:`n1. Single computer`n2. List of computers in a text file`n3. All enabled computers in Active Directory"

switch ($choice) {
    1 {
        $computers = Get-SingleComputer
    }
    2 {
        $computers = Get-ComputersFromFile
    }
    3 {
        $computers = Get-ADComputers
    }
    default {
        Write-Host "Invalid choice! Exiting."
        exit
    }
}

# Filter enabled computers and check if pingable before running the command
$computers | ForEach-Object -Parallel {
    $computer = $_
    if (Is-ComputerEnabled -computerName $computer -and Test-ComputerConnection -computerName $computer) {
        Invoke-Command -ComputerName $computer -ScriptBlock {
            Write-Host "Running auditpol.exe on $using:computer"
            auditpol.exe /get /category:*
        }
    } else {
        Write-Host "$computer is not enabled in Active Directory or not pingable. Skipping..."
    }
} -ThrottleLimit 5 # Set the throttle limit as required
