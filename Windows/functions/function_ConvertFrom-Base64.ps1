<# 

This script provides a straightforward way for users to decode Base64-encoded text, offering basic error handling in case of issues during the decoding process. 

#>

function ConvertFrom-Base64 {
    $text = Read-Host "Enter Encoded Text"
    try {
        $decodedText = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($text))
        Write-Output "Decoded Text: $decodedText"
    } catch {
        Write-Output "Error decoding Base64 input: $_"
    }
}
