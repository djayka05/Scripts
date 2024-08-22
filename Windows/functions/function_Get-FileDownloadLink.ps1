function Get-FileDownloadLink {
    param (
        [string]$FilePath
    )

    # Define a custom object to store results
    $result = [PSCustomObject]@{
        FilePath       = $FilePath
        FileExists     = $false
        ZoneIdentifier = $null
        DownloadLink   = $null
        Message        = $null
    }

    # Check if the file exists
    if (-not (Test-Path $FilePath)) {
        $result.Message = "File does not exist: $FilePath"
        return $result
    } else {
        $result.FileExists = $true
    }

    # Attempt to read the Zone.Identifier stream
    try {
        $zoneIdentifier = Get-Content -Path $FilePath -Stream 'Zone.Identifier' -ErrorAction Stop
        $result.ZoneIdentifier = $zoneIdentifier -join "`n"  # Join lines for easier storage in the object
    } catch {
        $result.Message = "No Zone.Identifier stream found for this file."
        return $result
    }

    # Parse the Zone.Identifier stream to find any URL
    $downloadUrl = $zoneIdentifier | ForEach-Object {
        if ($_ -match 'https?://.*$') {
            return $matches[0]
        }
    }

    if ($downloadUrl) {
        $result.DownloadLink = $downloadUrl
        $result.Message = "Download link found."
    } else {
        $result.Message = "No valid download URL found in the Zone.Identifier stream."
    }

    return $result
}

# Example usage:
$filePath = Read-Host "Enter Filepath"
$downloadLinkInfo = Get-FileDownloadLink -FilePath $filePath

# Output the custom object with details
$downloadLinkInfo | Format-List
