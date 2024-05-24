<# 

This script provides a simple interface for users to encode text into Base64 format, offering basic error handling in case of issues during the encoding process. 

#>

function ConvertTo-Base64 {
    $text = Read-Host "Enter Decoded Text"
    try {
        $encodedText = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($text))
        Write-Output "Encoded Text: $encodedText"
    } catch {
        Write-Output "Error encoding input: $_"
    }
}
