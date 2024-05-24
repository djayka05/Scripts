$sourceFilePath = Read-Host -Prompt "Source"
$destinationFilePath = Read-Host -Prompt "Destination"

function Copy-FileWithProgress {
    param (
        [string]$sourcePath,
        [string]$destinationPath
    )

    # Get the size of the source file
    $totalSize = (Get-Item $sourcePath).Length
    $bytesCopied = 0
    $lastProgress = -1

    # Perform the file copy operation
    $fileStream = [System.IO.File]::OpenRead($sourcePath)
    $destinationStream = [System.IO.File]::OpenWrite($destinationPath)
    $buffer = New-Object byte[] 1024
    try {
        while ($bytesRead = $fileStream.Read($buffer, 0, $buffer.Length)) {
            $destinationStream.Write($buffer, 0, $bytesRead)
            $bytesCopied += $bytesRead
            $progress = [math]::Round(($bytesCopied / $totalSize) * 100, 2)
            
            # Update progress only if it has changed significantly
            if ($progress -ne $lastProgress -and ($progress -gt ($lastProgress + 5) -or $progress -eq 100)) {
                $lastProgress = $progress
                Write-Progress -Activity "Copying File" -Status "Progress: $($progress)%" -PercentComplete $progress
            }
        }
    } finally {
        $fileStream.Close()
        $destinationStream.Close()
    }
}

try {
    Copy-FileWithProgress -sourcePath $sourceFilePath -destinationPath $destinationFilePath
    Write-Host "Copy completed." -ForegroundColor Green
} catch {
    Write-Host "Error occurred: $_"
}
