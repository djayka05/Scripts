function Select-OU {
    # Record the start time
    $startTime = Get-Date

    param (
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[PSObject]]$OrganizationalUnits
    )

    Write-Host "Select OU to join the computer to" -ForegroundColor Green
    for ($i=0; $i -lt $OrganizationalUnits.Count; $i++) {
        Write-Host "$($i+1). $($OrganizationalUnits[$i].Name)" -NoNewline -ForegroundColor Green
        Write-Host " - $($OrganizationalUnits[$i].Path)" 
    }
    
    $ouIndex = Read-Host -Prompt "Enter the number of the OU"

    $selectedOUPath = $OrganizationalUnits[$ouIndex-1].Path

    # Record the end time
    $endTime = Get-Date

    # Calculate the duration
    $duration = New-TimeSpan -Start $startTime -End $endTime

    # Write the total runtime to a text file
    $logDirectory = "C:\Logs"
    $logFilePath = "$logDirectory\Select-OU.log"  # Modify this path as needed
    "Total runtime: $($duration.Hours) hours, $($duration.Minutes) minutes, $($duration.Seconds) seconds" | Out-File -FilePath $logFilePath

    return $selectedOUPath
}
