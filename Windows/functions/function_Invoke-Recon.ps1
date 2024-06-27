function Invoke-Recon {
    param(
        [string]$Domain
    )

    # Prompt for the domain name if not provided
    if (-not $Domain) {
        $Domain = Read-Host -Prompt (Write-Host "Type/paste domain name" -ForegroundColor Yellow)
    }

    Clear-Host

    # DNS record types to query
    $RecordTypes = @("A", "AAAA", "CNAME", "MX", "NS", "PTR", "SOA", "SRV", "TXT")

    foreach ($Type in $RecordTypes) {
        try {
            $Records = Resolve-DnsName -Name $Domain -Type $Type -ErrorAction Stop
            if ($Records) {
                Write-Host " $Type Records for $Domain " -ForegroundColor Black -BackgroundColor Cyan
                $Records | Format-Table -AutoSize
                Write-Host ""
            }
        }
        catch {
            Write-Host "Error occurred while querying records of type $Type for $Domain $_"
        }
    }

    # Query DMARC record
    $DMARCRecord = Resolve-DnsName -Name "_dmarc.$Domain" -Type TXT -ErrorAction SilentlyContinue | Where-Object {$_.Name -eq "_dmarc.$Domain"} | Select-Object -ExpandProperty "Strings"
    if ($DMARCRecord) {
        Write-Host " DMARC Records for $Domain " -ForegroundColor Black -BackgroundColor Cyan
        Write-Host ""
        $DMARCRecord | Format-Table -AutoSize
        Write-Host ""
    } else {
        Write-Host "No DMARC record found for $Domain"
    }

    try {
        # Create a TCP client to connect to the server
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Connect($Domain, 443)
        
        # Specify SSL protocol
        $sslProtocols = [System.Security.Authentication.SslProtocols]::Tls12
        
        # Create an SSL stream to secure the connection
        $sslStream = New-Object System.Net.Security.SslStream($tcpClient.GetStream(), $false)
        $sslStream.AuthenticateAsClient($Domain, $null, $sslProtocols, $false)
        
        # Retrieve the SSL certificate from the server
        $cert = $sslStream.RemoteCertificate
        
        # Get the expiration date
        $expirationDate = [datetime]::Parse($cert.GetExpirationDateString())
        
        # Determine the color based on expiration date
        if ($expirationDate -gt (Get-Date)) {
            $expirationDateColor = "Green"
        } else {
            $expirationDateColor = "Red"
        }
        
        # Output certificate information with colored expiration date
        Write-Host " Certificate Information for $Domain " -ForegroundColor Black -BackgroundColor Cyan
        Write-Host ""
        Write-Host "Subject: $($cert.Subject)"
        Write-Host "Issuer: $($cert.Issuer)"
        Write-Host "Expiration Date: $($expirationDate.ToString())" -ForegroundColor $expirationDateColor
        Write-Host "Thumbprint: $($cert.GetCertHashString())"
        
        # Clean up
        $sslStream.Dispose()
        $tcpClient.Close()
    } 
    catch {
        $script:certError = "Failed to retrieve certificate information for $Domain"
    }
}

# Function to resolve FQDN to IP address
function Resolve-FQDN {
    param(
        [string]$FQDN
    )

    try {
        $resolvedIP = [System.Net.Dns]::GetHostAddresses($FQDN) | Select-Object -ExpandProperty IPAddressToString -First 1
        return $resolvedIP
    } catch {
        $script:resolveError = "Failed to resolve IP address for domain: $FQDN"
        return $null
    }
}

# Function to lookup ASN using ipinfo.io API
function Get-ASN {
    param(
        [string]$IPAddress
    )

    # Make API request
    $response = Invoke-RestMethod -Uri "https://ipinfo.io/$IPAddress/json" -ErrorAction SilentlyContinue

    # Check if ASN information is available
    if ($response -and $response.org) {
        $asnInfo = @{
            ASN = $response.org
            City = $response.city
            Region = $response.region
            Country = $response.country
            Location = $response.loc
            Postal = $response.postal
        }
        return $asnInfo
    } else {
        return "ASN information not found for IP address: $IPAddress"
    }
}

# Main script
$Domain = Read-Host -Prompt (Write-Host "Type/paste domain name" -ForegroundColor Yellow)
Invoke-Recon -Domain $Domain

$ipAddress = Resolve-FQDN -FQDN $Domain

if ($ipAddress) {
    $asn = Get-ASN -IPAddress $ipAddress
    Write-Host ""
    Write-Host " ASN for domain $Domain (resolved to IP $ipAddress) " -ForegroundColor Black -BackgroundColor Cyan
    $asn | Format-Table
}

function Get-WHOISInfo {
    param (
        [string]$domain
    )
    
    # Define a hashtable mapping domain extensions to their WHOIS servers
    $whoisServers = @{
        ".com" = "whois.verisign-grs.com"
        ".net" = "whois.verisign-grs.com"
        ".org" = "whois.pir.org"
        ".me" = "whois.nic.me"
        # Add more mappings for other domain extensions as needed
    }
    
    # Get the domain extension
    $domainParts = $domain -split "\."
    $extension = "." + $domainParts[-1]
    
    # Check if the WHOIS server is known for this extension
    if ($whoisServers.ContainsKey($extension)) {
        # Construct the WHOIS server address
        $whoisServer = $whoisServers[$extension]
        $whoisPort = 43
        $whoisAddress = "$whoisServer`:$whoisPort"
        
        # Create a TCP client to connect to the WHOIS server
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        
        try {
            # Connect to the WHOIS server
            $tcpClient.Connect($whoisServer, $whoisPort)
            
            # Send the WHOIS query
            $stream = $tcpClient.GetStream()
            $query = "$domain`r`n"
            $queryBytes = [System.Text.Encoding]::ASCII.GetBytes($query)
            $stream.Write($queryBytes, 0, $queryBytes.Length)
            
            # Read the response from the WHOIS server
            $responseBytes = New-Object byte[] 4096
            $stream.Read($responseBytes, 0, $responseBytes.Length) | Out-Null
            $response = [System.Text.Encoding]::ASCII.GetString($responseBytes).Trim()
        }
        finally {
            # Close the TCP client
            $tcpClient.Close()
        }
        
        # Filter out unwanted lines and extract relevant information
        $relevantInfo = $response -split "`n" | Where-Object { $_ -match "Registrar:|Creation Date:|Updated Date:|Registry Expiry Date:|Domain Status:|DNSSEC:" } | ForEach-Object { $_ -replace '\s+', ' ' }
        
        # Create a custom sorting order for the keys
        $customSortOrder = @{
            "Registrar" = 1
            "Creation Date" = 2
            "Updated Date" = 3
            "Registry Expiry Date" = 4
            "Domain Status" = 5
            "DNSSEC" = 6
        }
        
        # Output WHOIS response as a table with keys sorted according to the custom order
        $output = foreach ($line in $relevantInfo) {
            $keyValue = $line -split ":", 2
            $key = $keyValue[0].Trim()
            $value = $keyValue[1].Trim()
            
            [PSCustomObject]@{
                Key = $key
                Value = $value
                SortOrder = $customSortOrder[$key]
            }
        }
        
        Write-Host ""
        Write-Host " WHOIS Information " -ForegroundColor Black -BackgroundColor Cyan
        $output | Sort-Object SortOrder | Select-Object Key, Value | Format-Table -AutoSize
    }
    else {
        Write-Host "WHOIS server not found for extension: $extension"
    }
}

Get-WHOISInfo -domain $Domain

# Display Errors section if there are any errors
if ($script:resolveError -or $script:certError) {
    Write-Host ""
    Write-Host " Errors " -ForegroundColor Black -BackgroundColor Cyan
    Write-Host ""

    if ($script:resolveError) {
        Write-Host $script:resolveError
    }

    if ($script:certError) {
        Write-Host $script:certError
    }
}
