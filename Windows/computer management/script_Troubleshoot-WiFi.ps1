# Function to ping Google and return ping status
function Test-PingGoogle {
    $pingResult = Test-Connection -ComputerName "www.google.com" -Count 1
    $pingStatus = if ($pingResult.StatusCode -eq 0) { "Ping failed" } else { "Ping successful" }
    return $pingStatus
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
    return $dnsTest
}

# Function to generate wireless network report and append troubleshooting details
function New-WifiReport {
    
    $duration = Read-Host -Prompt "Enter Duration"

    # Generate a new WLAN report
    netsh wlan show wlanreport duration="$duration"

    $reportPath = "C:\ProgramData\Microsoft\Windows\WlanReport\wlan-report-latest.html"
    if (-not (Test-Path $reportPath)) {
        Write-Host "WLAN report not found at the default location: $reportPath"
        exit
    }
    $destination = "C:\temp\WirelessNetworkReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    Copy-Item -Path $reportPath -Destination $destination
    $newReportPath = "C:\temp\Wi-Fi_Troubleshooting_$env:COMPUTERNAME" + "_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + ".html"
    Rename-Item -Path $destination -NewName $newReportPath

    # Append ping status and DNS resolution test result to the HTML report
    $pingStatus = $args[0]
    $dnsTest = $args[1]
    $htmlContent = Get-Content -Path $newReportPath -Raw
    $updatedHtmlContent = $htmlContent -replace "</body>", @"
    <div style='text-align: center;'>
        <h2 style='margin-top: 20px;'>Additional Details</h2>
        <pre style='text-align: left; display: inline-block;'>$pingStatus`n$dnsTest</pre>
    </div>
</body>
"@
    $updatedHtmlContent | Out-File -FilePath $newReportPath -Encoding utf8

    return $newReportPath
}

# Main script
$choice = Read-Host "Do you want to troubleshoot the local computer (1) or a remote computer (2)?"

if ($choice -eq "1") {
    $ComputerName = $env:COMPUTERNAME
}
elseif ($choice -eq "2") {
    $ComputerName = Read-Host "Enter the name of the remote computer:"
}
else {
    Write-Host "Invalid choice. Please select '1' for local or '2' for remote."
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

if ($choice -eq "2") {
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
            Write-Output "Wi-Fi troubleshooting steps completed."
            $pingStatus = Test-PingGoogle
            $dnsTest = Test-DnsResolution
            $pingStatus, $dnsTest
        }
    } catch {
        Write-Host "Failed to establish a remote session to $ComputerName $($_.Exception.Message)"
        exit
    }

    # Generate wireless network report remotely
    try {
        $reportPath = Invoke-Command -Session $session -ScriptBlock { param($pingStatus, $dnsTest) New-WifiReport $pingStatus $dnsTest } -ArgumentList $pingStatus, $dnsTest
        Write-Host "Wireless network report generated successfully on $ComputerName. It is saved at: $reportPath"
    } catch {
        Write-Host "Failed to generate the wireless network report on $ComputerName $($_.Exception.Message)"
    }
} else {
    # Local troubleshooting steps

    Write-Output "Wi-Fi troubleshooting steps completed."

    # Perform DNS resolution test
    $dnsResult = Test-DnsResolution

    # Ping Google and get status
    $pingStatus = Test-PingGoogle

    # Generate local wireless network report and append troubleshooting details
    try {
        $reportPath = New-WifiReport $pingStatus $dnsResult
        Write-Host "Wireless network report generated successfully on $ComputerName. It is saved at: $reportPath"
    } catch {
        Write-Host "Failed to generate the wireless network report on $ComputerName $($_.Exception.Message)"
    }
}

Write-Host "Wi-Fi troubleshooting completed."
