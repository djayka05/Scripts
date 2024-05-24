# Function to ping Google and append results to the Wi-Fi troubleshooting text file
function Test-PingGoogle {
    $pingResult = Test-Connection -ComputerName "www.google.com" -Count 1
    $pingStatus = if ($pingResult.StatusCode -eq 0) { "Ping successful" } else { "Ping failed" }
    $txtFilePath = "C:\temp\Wi-Fi_Troubleshooting_$env:COMPUTERNAME" + "_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + ".txt"
    @"
$pingStatus

"@ | Out-File -FilePath $txtFilePath -Append -Encoding utf8
}


# Function to perform DNS resolution test
function Test-DnsResolution {
    $dnsTest = $null
    $dnsServers = (Get-DnsClientServerAddress).ServerAddresses
    foreach ($dnsServer in $dnsServers) {
        $result = Resolve-DnsName -Name "www.google.com" -Server $dnsServer -ErrorAction SilentlyContinue
        if ($result) {
            $dnsTest = "DNS resolution test passed using server: $dnsServer"
            break
        }
    }
    if (-not $dnsTest) {
        $dnsTest = "DNS resolution test failed. Check DNS server configuration."
    }
    $dnsTest
}

# Function to generate wireless network report
function New-WifiReport {
    $reportPath = "C:\ProgramData\Microsoft\Windows\WlanReport\wlan-report-latest.html"
    if (-not (Test-Path $reportPath)) {
        Write-Host "WLAN report not found at the default location: $reportPath"
        exit
    }
    $destination = "C:\temp\WirelessNetworkReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    Copy-Item -Path $reportPath -Destination $destination
    Rename-Item -Path $destination -NewName ("Wi-Fi_Troubleshooting_$env:COMPUTERNAME" + "_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + ".html")
    $destination
}

# Main script
$choice = Read-Host "Do you want to troubleshoot the local computer (L) or a remote computer (R)? [L/R]"

if ($choice -eq "L") {
    $ComputerName = $env:COMPUTERNAME
}
elseif ($choice -eq "R") {
    $ComputerName = Read-Host "Enter the name of the remote computer:"
}
else {
    Write-Host "Invalid choice. Please select 'L' for local or 'R' for remote."
    exit
}

# Create temp directory if it doesn't exist
$tempDir = "C:\temp"
if (-not (Test-Path $tempDir)) {
    try {
        New-Item -Path $tempDir -ItemType Directory -ErrorAction Stop | Out-Null
    } catch {
        Write-Host "Failed to create temp directory: $_"
        exit
    }
}

if ($choice -eq "R") {
    # Ping the remote computer to check if it's online
    $pingResult = Test-Connection -ComputerName $ComputerName -Count 1 -Quiet
    if (-not $pingResult) {
        Write-Host "Failed to ping $ComputerName. Make sure it's online and try again."
        exit
    }

    # Prompt user for username and password to connect remotely
    $username = Read-Host "Enter the username for remote connection"
    $password = Read-Host -AsSecureString "Enter the password for $username"

    # Attempt to establish a remote session
    try {
        $session = New-PSSession -ComputerName $ComputerName -Credential (New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $password)
        Invoke-Command -Session $session -ScriptBlock {
            param ()
            # Recommended troubleshooting steps (you can modify these as needed)
            # Example: netsh wlan show interfaces, ipconfig /all, etc.
            # Perform Wi-Fi troubleshooting steps here
            Write-Output "Wi-Fi troubleshooting steps completed."
            Test-PingGoogle
        }
    } catch {
        Write-Host "Failed to establish a remote session to $ComputerName $($_.Exception.Message)"
        exit
    }

    # Generate wireless network report remotely
    try {
        $reportPath = Invoke-Command -Session $session -ScriptBlock { New-WifiReport }
        Write-Host "Wireless network report generated successfully on $ComputerName. It is saved at: $reportPath"
    } catch {
        Write-Host "Failed to generate the wireless network report on $ComputerName $($_.Exception.Message)"
    }
} else {
    # Local troubleshooting steps
    # Recommended troubleshooting steps (you can modify these as needed)
    # Example: netsh wlan show interfaces, ipconfig /all, etc.
    # Perform Wi-Fi troubleshooting steps here
    Write-Output "Wi-Fi troubleshooting steps completed."

    # Perform DNS resolution test
    $dnsResult = Test-DnsResolution

    # Write troubleshooting details to a text file
    $txtFilePath = "C:\temp\Wi-Fi_Troubleshooting_$env:COMPUTERNAME" + "_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + ".txt"
    @"
Wi-Fi Troubleshooting Details for $env:COMPUTERNAME
----------------------------------------------------
$dnsResult

"@ | Out-File -FilePath $txtFilePath -Encoding utf8

    # Ping Google and append results to the text file
    Test-PingGoogle

    # Generate local wireless network report
    try {
        $reportPath = New-WifiReport
        Write-Host "Wireless network report generated successfully on $ComputerName. It is saved at: $reportPath"
    } catch {
        Write-Host "Failed to generate the wireless network report on $ComputerName $($_.Exception.Message)"
    }
}

Write-Host "Wi-Fi troubleshooting completed."
