function Get-FileDownloadLink {
    param (
        [string]$FilePath
    )

    # Check if the file exists
    if (-not (Test-Path $FilePath)) {
        Write-Host "File does not exist: $FilePath"
        return
    }

    # Attempt to read the Zone.Identifier stream
    try {
        $zoneIdentifier = Get-Content -Path $FilePath -Stream 'Zone.Identifier' -ErrorAction Stop
    } catch {
        Write-Host "No Zone.Identifier stream found for this file."
        return
    }

    # Output the entire Zone.Identifier stream for inspection
    Write-Host "Zone.Identifier contents:"
    $zoneIdentifier | ForEach-Object { Write-Host $_ }

    # Parse the Zone.Identifier stream to find any URL
    $downloadUrl = $zoneIdentifier | ForEach-Object {
        if ($_ -match 'https?://.*$') {
            return $matches[0]
        }
    }

    if ($downloadUrl) {
        return $downloadUrl
    } else {
        Write-Host "No valid download URL found in the Zone.Identifier stream."
    }
}

# Example usage:
$filePath = Read-Host "Enter Filepath"
$downloadLink = Get-FileDownloadLink -FilePath $filePath

# Output the download link
if ($downloadLink) {
    Write-Host "Download Link: $downloadLink"
}
