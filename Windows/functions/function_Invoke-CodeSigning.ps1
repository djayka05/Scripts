<# 

This script provides a convenient way to sign files with a code signing certificate, which is often necessary for ensuring the authenticity and integrity of scripts or executables in Windows environments. 

#>

function Invoke-CodeSigning {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string] $File
    )

    try {
        $cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert | Select-Object -First 1
        if (-not $cert) {
            throw "No code signing certificate found."
        }
        
        Set-AuthenticodeSignature -FilePath $File -Certificate $cert -ErrorAction Stop
    } 
    catch {
        Write-Error "Error: $_"
    }
}
