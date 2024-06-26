# Define the computer name to connect to
$computerName = Read-Host -Prompt "Type Computername"

# Function to ping the computer
function Test-ComputerPing {
    param (
        [string]$computerName
    )
    
    try {
        $pingResult = Test-Connection -ComputerName $computerName -Count 1 -Quiet
        return $pingResult
    } catch {
        return $false
    }
}

# Ping the computer
if (Test-ComputerPing -computerName $computerName) {
    Write-Host "$computerName is reachable, proceeding with LAPS credential retrieval and RDP setup."

    # Import the LAPS module if not already imported
    if (-not (Get-Module -Name AdmPwd.PS)) {
        Import-Module AdmPwd.PS
    }

    # Retrieve the LAPS password for the specified computer
    $lapsPassword = (Get-AdmPwdPassword -ComputerName $computerName).Password

    # Define the username for RDP (usually the local administrator)
    $rdpUsername = "laps_admin"

    # Use cmdkey to store the credentials
    cmdkey /generic:"$computerName" /user:"$computerName\$rdpUsername" /pass:"$lapsPassword"

    # Create an RDP file
    $rdpFilePath = "$env:temp\rdpfile.rdp"
    @"
full address:s:$computerName
username:s:$computerName\$rdpUsername
"@ | Out-File -FilePath $rdpFilePath -Encoding Unicode

    # Log the actions
    Write-Host "Stored credentials using cmdkey for $computerName"
    Write-Host "RDP file created at $rdpFilePath"

    # Launch the RDP session
    try {
        Start-Process "mstsc.exe" -ArgumentList $rdpFilePath
        Write-Host "RDP session started for $computerName"
    } catch {
        Write-Host "Failed to start RDP session: $_"
    }

    # Clean up the stored credentials after a delay
    Start-Sleep -Seconds 10
    cmdkey /delete:"$computerName"
    Write-Host "Deleted stored credentials for $computerName"
} else {
    Write-Host "$computerName is not reachable. Please check the computer name or network connection."
}
