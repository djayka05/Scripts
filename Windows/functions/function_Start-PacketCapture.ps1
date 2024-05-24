function Start-PacketCapture {
    try {
        # Prompt user for port number
        $portNumber = Read-Host -Prompt "Enter the port number to filter (e.g., 88)"

        # Prompt user for sleep time
        $sleepTime = Read-Host -Prompt "Enter the sleep time in seconds (e.g., 120)"

        # Check if C:\temp exists, if not, create it
        if (-not (Test-Path -Path "C:\temp" -PathType Container)) {
            New-Item -Path "C:\temp" -ItemType Directory -ErrorAction Stop | Out-Null
        }

        # Get current date and time in a format suitable for filenames
        $dateTime = Get-Date -Format "yyyyMMdd-HHmmss"

        # Set the output file name with current date and time
        $outputFile = "C:\temp\capture-$dateTime.etl"

        # Set the output pcap file name
        $outputPcapFile = "C:\temp\capture-$dateTime.pcap"

        # Change directory to C:\temp
        Set-Location -Path "C:\temp" -ErrorAction Stop | Out-Null

        # Check if the filter is already added
        $existingFilters = pktmon filter list | Select-String -Pattern $portNumber | Out-Null

        # If the filter is not added, add it
        if (-not $existingFilters) {
            pktmon filter add -p $portNumber -ErrorAction Stop | Out-Null
        }

        # Start capturing packets
        pktmon start -c --pkt-size 0 --comp 9 -s 1000 -f $outputFile -ErrorAction Stop | Out-Null

        # Wait for the capturing process to complete
        Start-Sleep -Seconds $sleepTime

        # Stop capturing packets
        pktmon stop -ErrorAction Stop | Out-Null
        pktmon filter remove -ErrorAction Stop | Out-Null

        # Convert the output file to pcap format
        pktmon etl2pcap $outputFile -o $outputPcapFile -ErrorAction Stop | Out-Null

        # Remove the output file after conversion
        Remove-Item $outputFile -Force -ErrorAction Stop | Out-Null
    }
    catch {
        Write-Error "An error occurred: $_"
    }
}
