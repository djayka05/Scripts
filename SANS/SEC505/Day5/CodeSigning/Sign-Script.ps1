####################################################################################
#.SYNOPSIS 
#   Digitally signs PowerShell scripts. 
#
#.DESCRIPTION 
#   If you have a code signing certificate, this script will sign one or
#   more PowerShell scripts for the sake of AppLocker or PowerShell's
#   execution policy restrictions. Note that this script will not create 
#   or enroll for a code signing certificate itself; a code signing certificate
#   and private key must be obtained first.  PSD1 and CAT files can also be signed.
#
#.PARAMETER Path  
#   Path to a single .ps1, .psd1 or .cat file, or the path to a folder which
#   contains one or more .ps1, .psd1 or .cat files.  All matching files will be
#   signed.  Any non-ps1/psd1/cat files will be ignored.  
#
#.PARAMETER Recurse
#   Switch to recurse through subdirectories of the given path.  Only
#   *.ps1, *.psd1 and *.cat files will be signed.  
#
#.PARAMETER Thumbprint
#   Optional hash of the code-signing certificate to use if the user has
#   more than one available certificate with that purpose.
#
#.PARAMETER DoNotAskWhichCertificateToUse
#   Avoid compelling the user to enter a thumbprint when the user has
#   multiple code-signing certificates.  This switch will simply use
#   the first code-signing certificate it finds.  
#
#.PARAMETER ListCodeSigningCertificates
#    Show a list of the user's code-signing certificates, if any, and then
#    exit.  No files will be signed.  
#
#.EXAMPLE 
#    .\Sign-Script.ps1 -Path onescript.ps1
#.EXAMPLE 
#    .\Sign-Script.ps1 -Path c:\folder\*many*.ps1 
#.EXAMPLE 
#    .\Sign-Script.ps1 -Path c:\folder -recurse 
#.EXAMPLE 
#    .\Sign-Script.ps1 foo.ps1 -Thumprint 4342368F1339CB59010AE3720ED5672B73E94CD4
#.EXAMPLE 
#    .\Sign-Script.ps1 -Path script.ps1 -DoNotAskWhichCertificateToUse
#
#.NOTES 
#   Author: Jason Fossen, Enclave Consulting LLC (http://www.sans.org/sec505)  
#   Version: 1.2
#   Updated: 18.Mar.2017
#   Legal: 0BSD.
####################################################################################


Param ( $Path, [Switch] $Recurse, $Thumbprint = "blank" , [Switch] $DoNotAskWhichCertificateToUse, [Switch] $ListCodeSigningCertificates )

# Check for -ListCodeSigningCertificates and exit.
if ($ListCodeSigningCertificates){ dir cert:\currentuser\my -codesigningcert ; exit }

# Expand path of script(s) to sign.
if (-not $Path) { "`nError, you must enter the path to one or more files to sign; wildcards are permitted, exiting.`n" ; exit } 
if ($Recurse) { $Path = dir -Path $Path -force -recurse -file -include *.ps1,*.psd1,*.cat } else { $Path = dir -path $Path -force -file -include *.ps1,*.psd1,*.cat } 
if ($Path -eq $null) { "`nError, invalid argument to -Path parameter, exiting.`n" ; exit } 

# Get the current user's code-signing cert(s), if any.
$certs = @(dir cert:\currentuser\my -codesigningcert)

# Check for zero, one or multiple code-signing certificates.
if ($certs.count -eq 0) { "`nYou have no code-signing certificates, exiting.`n" ; exit }
elseif ($Thumbprint -ne "blank") { $signingcert = ($certs | where { $_.Thumbprint -match "$Thumbprint" }) } 
elseif ($certs.count -ge 1 -or $DoNotAskWhichCertificateToUse) { $signingcert = $certs[0] }
elseif ($Thumbprint -eq "blank") { "`nYou have multiple code-signing certificates.  Run the script again, but enter the thumbprint of the one you wish to use as the argument to the -Thumbprint parameter (or use -DoNotAskWhichCertificateToUse to simply use the first certificate available).`n" ; $certs | format-list Thumbprint,Issuer,Subject,SerialNumber,NotAfter,FriendlyName ; exit } 
else { "`nError, should not have gotten here, exiting.`n" ; exit } 

# Quick check that we actually got a cert to use...
if ($certs -notcontains $signingcert) 
{ 
    "`nError, an invalid certificate choice was made, exiting.`n"
    if ($Thumbprint -ne "blank") { "Did you enter the correct thumbprint hash value without`n any spaces, colons or other delimiters?`n" } 
    exit 
} 

# Sign each script.
foreach ($file in $Path) { Set-AuthenticodeSignature -FilePath $file.fullname -Certificate $signingcert } 

