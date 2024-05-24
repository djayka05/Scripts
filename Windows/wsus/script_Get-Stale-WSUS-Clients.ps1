<#

Get Stale Computers from WSUS Server:
The script connects to the WSUS server and retrieves a list of computers that haven't reported to the WSUS server in over 30 days. This is achieved using the `Get-WsusComputer` cmdlet and filtering based on the `LastReportedTime` property.

Initialize Results Array:
An empty array called `$results` is initialized. This array will be used to store information about computers that are not found in Active Directory or are not pingable.

Iterate Through Stale Computers:
The script iterates through each stale computer retrieved from the WSUS server.

Check Active Directory:
For each stale computer, the script checks if the computer exists in Active Directory using the `Get-ADComputer` cmdlet. If the computer is found, it proceeds to the next step. If not, it adds information about the computer to the `$results` array for later reporting.

Pingability Check:
For computers found in Active Directory, the script checks if they are pingable using the `Test-Connection` cmdlet. If the computer is pingable, the script proceeds to execute the provided script block/function using `Invoke-Command`. If not, it outputs a message to the screen indicating that the computer is not pingable, along with the last logon date retrieved from Active Directory.

Execute Script (if Pingable):
If a computer is both found in Active Directory and pingable, the script executes the provided script block/function using `Invoke-Command`. The provided script block/function performs actions such as stopping and starting services, renaming folders, running `gpupdate`, and initiating Windows Update actions.

Output to Screen (if Not Pingable):
If a computer is found in Active Directory but not pingable, the script outputs a message to the screen indicating that the computer is not pingable, along with the last logon date retrieved from Active Directory.

Export Results to CSV:
After processing all stale computers, the script exports the information about computers not found in Active Directory or not pingable to a CSV file named "StaleComputersReport.csv" using the `Export-Csv` cmdlet.

This script automates the process of identifying stale computers from the WSUS server, checking their existence in Active Directory, verifying their pingability, and executing a script against them if they meet the criteria. It provides detailed reporting on computers that are not found in Active Directory. It also resolves WSUS client issues reporting into WSUS server.

#>

# BEGIN SCRIPT

# Connect to WSUS server and get stale computers over 30 days
$staleComputers = Get-WsusComputer | Where-Object { $_.LastReportedTime -lt (Get-Date).AddDays(-30) }

# Initialize an array to store results
$results = @()

# Iterate through each stale computer
foreach ($computer in $staleComputers) {
    # Check if computer exists in Active Directory
    $adComputer = Get-ADComputer -Filter { Name -eq $computer.FullDomainName }
    if ($adComputer) {
        # Check if computer is pingable
        if (Test-Connection -ComputerName $computer.FullDomainName -Count 1 -Quiet) {
            # Run script against pingable computers
            Invoke-Command -ComputerName $computer.FullDomainName -ScriptBlock {
                param($computerName)
                Write-Host "Running script against $computerName" -ForegroundColor Green
                # Your script/function here
                # Example script:
                Write-Host "Stopping bits and wuauserv services on $computerName." -ForegroundColor Green
                Stop-Service bits
                Stop-Service wuauserv
                Start-Sleep -Seconds 10
                # ...rest of your script/function
            } -ArgumentList $computer.FullDomainName
        } else {
            # Output last logon date and message to screen if computer is not pingable
            $lastLogonDate = [datetime]::FromFileTime($adComputer.LastLogonDate)
            Write-Host "$($computer.FullDomainName) is not pingable. Last Logon Date: $lastLogonDate" -ForegroundColor Yellow
            # Add information to results array
            $results += [PSCustomObject]@{
                ComputerName = $computer.FullDomainName
                LastLogonDate = $lastLogonDate
                Status = "Not pingable"
            }
        }
    } else {
        # Output to CSV report if computer is not found in Active Directory
        $results += [PSCustomObject]@{
            ComputerName = $computer.FullDomainName
            Status = "Not found in Active Directory"
        }
    }
}

# Export results to CSV
$results | Export-Csv -Path "StaleComputersReport.csv" -NoTypeInformation