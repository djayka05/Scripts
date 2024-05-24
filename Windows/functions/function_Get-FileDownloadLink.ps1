function Get-FileDownloadLink {
    param (
        [string]$FilePath
    )

    $fileStream = Get-Item $FilePath -Stream *
    $zoneIdentifierStream = Get-Content -Path $FilePath -Stream 'Zone.Identifier'

    return @{
        FileStream = $fileStream
        ZoneIdentifierStream = $zoneIdentifierStream
    }
}

# Example usage:
$filePath = Read-Host "Add Filepath"
$result = Get-FileDownloadLink -FilePath $filePath

# Access the results
$result.FileStream
$result.ZoneIdentifierStream
