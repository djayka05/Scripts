# Specify the directory containing DMARC report XML files
$xmlDirectory = "D:\Downloads\dmarc\"

# Get a list of XML files in the directory
$xmlFiles = Get-ChildItem -Path $xmlDirectory -Filter "*.xml"

# Loop through each XML file
foreach ($xmlFile in $xmlFiles) {
  
    try {
        # Load the DMARC report XML file
        [xml]$xml = Get-Content $xmlFile.FullName -ErrorAction Stop

        # Extract relevant data from the XML
        $records = $xml.feedback.record
        if (-not $records) {
            Write-Host "No records found in $($xmlFile.Name)."
            continue
        }

        # Loop through each record and format the output
        foreach ($record in $records) {
            try {
                # Extracting data from the record
                $orgName = $xml.feedback.report_metadata.org_name
                $sourceIP = $record.row.source_ip
                $count = $record.row.count
                $selector = $record.auth_results.dkim.selector
                $dkimResult = $record.auth_results.dkim.result
                $spfResult = $record.auth_results.spf.result
                $headerFrom = $record.identifiers.header_from
                $domain = $record.auth_results.dkim.domain

                # Determine color based on DKIM and SPF results
                $dkimColor = if ($dkimResult -eq "pass") { "Green" } else { "Red" }
                $spfColor = if ($spfResult -eq "pass") { "Green" } else { "Red" }

                # Outputting data with color
                Write-Host "-----------------------------"
                Write-Host "XML filename: $($xmlFile.Name)" -ForegroundColor Yellow
                Write-Host "Organization Name: $orgName" -ForegroundColor White -BackgroundColor Black
                Write-Host "-----------------------------"
                Write-Host "Record:"
                Write-Host "  Source IP: $sourceIP"
                Write-Host "  Count: $count"
                Write-Host "  DKIM Selector: $selector"
                Write-Host "  DKIM Result: $dkimResult" -ForegroundColor $dkimColor
                Write-Host "  SPF Result: $spfResult" -ForegroundColor $spfColor
                Write-Host "  Header From: $headerFrom"
                Write-Host "  Domain: $domain"
            } catch {
                Write-Host "Error processing record: $_"
            }
        }
    } catch {
        Write-Host "Error processing XML file $($xmlFile.Name): $_"
    }
}
