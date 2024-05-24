function Get-WHOISInfo {
    param (
        [string]$domain
    )
    
    # Define a hashtable mapping domain extensions to their WHOIS servers
    $whoisServers = @{
        ".com" = "whois.verisign-grs.com"
        ".net" = "whois.verisign-grs.com"
        ".org" = "whois.pir.org"
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
        
        $output | Sort-Object SortOrder | Select-Object Key, Value | Format-Table -AutoSize
    }
    else {
        Write-Host "WHOIS server not found for extension: $extension"
    }
}

# Example usage
# $domain = Read-Host "Input domain name"
Get-WHOISInfo -domain $domain
