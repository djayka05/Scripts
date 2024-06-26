# Define the path for the output report
$outputDirectory = "C:\Temp"
$outputPath = Join-Path -Path $outputDirectory -ChildPath "BSOD_Report.csv"

# Check if the output directory exists and create it if it doesn't
if (-not (Test-Path -Path $outputDirectory)) {
    New-Item -Path $outputDirectory -ItemType Directory | Out-Null
    Write-Host "Created directory: $outputDirectory"
}

# Define the paths to check for dump files
$dumpPaths = @("C:\Windows\Minidump", "C:\Windows\MEMORY.DMP")

# Create an array to store report data
$report = @()

# Function to get dump file details
function Get-DumpFileDetails {
    param (
        [string]$path
    )

    $details = @()
    if (Test-Path $path) {
        Get-ChildItem -Path $path -Filter *.dmp | ForEach-Object {
            $details += [PSCustomObject]@{
                FileName   = $_.Name
                FilePath   = $_.FullName
                FileSizeKB = [math]::Round($_.Length / 1KB, 2)
                CreationTime = $_.CreationTime
            }
        }
    }
    return $details
}

# Iterate over defined dump paths and get dump file details
foreach ($path in $dumpPaths) {
    $dumps = Get-DumpFileDetails -path $path
    if ($dumps) {
        $report += $dumps
    }
}

# Get all events from the System log related to BSOD (Event ID 41 and 1001)
$bsodEvents = Get-WinEvent -LogName System -FilterXPath "*[System[(EventID=41 or EventID=1001)]]"

# Iterate through the events and extract relevant information
foreach ($event in $bsodEvents) {
    $eventData = @{
        TimeCreated = $event.TimeCreated
        EventID = $event.Id
        Level = $event.LevelDisplayName
        Message = $event.Message
    }
    $report += $eventData
}

# Check if there is data to export
if ($report.Count -eq 0) {
    Write-Host "No BSOD events or dump files found."
} else {
    # Convert the report array to a CSV and save it to the specified path
    $report | Export-Csv -Path $outputPath -NoTypeInformation
    Write-Host "BSOD report generated successfully at $outputPath"
}
