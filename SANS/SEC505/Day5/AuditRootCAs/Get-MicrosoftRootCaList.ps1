######################################################################
#.SYNOPSIS
#   Get list of Microsoft-trusted root CA certificate hashes.
#
#.DESCRIPTION
#   This script will download Microsoft's latest list of trustworthy 
#   root Certification Authorities (CAs) and save their SHA-1 hashes
#   to a text file in the present folder for the sake of performing
#   audits of machines' current lists of trusted root CAs.
#
#.NOTES
#   Can only run on Windows because of the COM object used.
#   Version: 1.0, Author: JF, Legal: 0BSD.
######################################################################


# Download CAB with latest list of Microsoft-trusted root CAs:
invoke-webrequest -uri http://ctldl.windowsupdate.com/msdownload/update/v3/static/trustedr/en/authrootstl.cab -OutFile .\authrootstl.cab 


# Confirm download of CAB:
if (-not (Test-Path -Path .\authrootstl.cab)){ "CAB file not downloaded, exiting." ; return } 


# Extract STL file from CAB:
$shell = new-object -com Shell.Application
$filepath = dir .\authrootstl.cab | select -ExpandProperty fullname
$folderpath = dir .\authrootstl.cab | select -ExpandProperty DirectoryName

$cab = $shell.NameSpace( $filepath )

foreach($item in $cab.items())
{
    $shell.Namespace($folderpath).copyhere($item)
}


# Confirm extraction of STL file:
if (-not (Test-Path -Path .\authroot.stl)){ "STL file not extracted, exiting." ; return } 


# Construct file path for output:
$outfile = "Microsoft-Trusted-Root-CA-Certs-" + (get-date).Day + "." + (get-date).Month + "." + (get-date).Year + ".txt" 


# Select SHA-1 hashes of trusted root CA certs from STL file:
certutil.exe -dump .\authroot.stl | Select-String -Pattern 'Subject Identifier:' | foreach { $_ -split 'Subject Identifier: ' } | select-string -pattern '...' | foreach { $_.line.toupper() } | Out-File -FilePath $outfile 


# Say something useful...
"`nFile saved as $outfile `n"


# Clean up temp files:
del .\authrootstl.cab -ErrorAction SilentlyContinue
del .\authroot.stl -ErrorAction SilentlyContinue



