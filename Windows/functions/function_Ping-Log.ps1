<# 

This script continuously pings target every 5 seconds and logs any failures to the Windows Event Viewer under the specified log name and source. 

#>

$target = Read-Host -Prompt "Add IP/FQDN"
$logName = "Application"
$source = "Ping Fail"

function Ping-Google {
    param(
        [string]$logName,
        [string]$source,
        [string]$message
    )
    $evt = New-Object System.Diagnostics.EventLog($logName)
    $evt.Source = $source
    $evt.WriteEntry($message, "Error")
}

while ($true) {
    $pingResult = Test-Connection -ComputerName $target -Count 1 -ErrorAction SilentlyContinue
    if (-not $pingResult) {
        $errorMessage = "Ping to $target failed at $(Get-Date)."
        Write-Host $errorMessage
        Log-EventViewer -logName $logName -source $source -message $errorMessage
    }
    Start-Sleep -Seconds 5
}
