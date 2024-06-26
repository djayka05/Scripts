##########################################################################
#.SYNOPSIS
#    Export Certificate Services settings and private keys.
#
#.DESCRIPTION
#   After installing and configuring a certificate server for your PKI, you
#   should export a backup copy of the registry settings for the CA, the
#   CA's machine certificates and private keys, and the contents of 
#   $env:WinDir\System32\Certsrv\CertEnroll\.  This script will export
#   these items to a single zip archive.  Private keys held by a
#   Hardware Security Module (HSM) are not backed up by this script.
#
#   You will be prompted for a passphrase to encrypt the exported private
#   keys.  This should be complex and 15+ characters long.  
#
#   DO NOT LOSE THE DECRYPTION PASSPHRASE!  PROTECT THE ZIP ARCHIVE!
#
#   For ongoing backups of the CA database, make system backups with
#   ADCS-aware backup products or use the Backup-CARoleService cmdlet.
#
#.NOTES
#   This script does very little error handling and no logging.  Add
#   these and other security features before production use.
#   Legal: 0BSD.
##########################################################################

# Prompt for an encryption passphrase:
$creds = Get-Credential -UserName 'NotUsed' -Message 'Enter the passphrase to encrypt the private keys'


# Get the number of 100-nanosecond intervals since January 1 of Year 1 
# (1.Jan.0001) and use this as a timestamp in the zip file: 
[String] $Ticks = (Get-Date).Ticks


# Export the configuration settings for Certificate Services from the registry:
reg.exe export hklm\system\CurrentControlSet\Services\CertSvc "Certificate-Services-Config-$Ticks.reg" /y | Out-Null


# Create a zip archive named after $Ticks and add the REG file:
Compress-Archive -Path "Certificate-Services-Config-$Ticks.reg" `
                 -DestinationPath "CA-Backup-$Ticks.zip" 


# Delete the exported REG file:
Remove-Item -Path "Certificate-Services-Config-$Ticks.reg"


# Not every machine certificate will be exportable: 
dir Cert:\LocalMachine\My |
ForEach `
{
    # Use the cert hash as the name of the PFX file:
    $hashpfx = $_.Thumbprint + ".pfx" 

    Try 
    {
        # Export cert and private key, encrypted with the passphrase:
        Export-PfxCertificate -Cert $_ -Password $creds.Password -FilePath $hashpfx -Force | Out-Null

        # Add that PFX file to the zip archive:
        Compress-Archive -Update -Path $hashpfx -DestinationPath "CA-Backup-$Ticks.zip"
    
        # Delete the PFX file from the drive (isn't scrubbed, but not Recycle Bin either):
        Remove-Item -Path $hashpfx 
    }
    Catch
    {
        Write-Warning -Message $_.Exception.Message
        Write-Warning -Message ("Failed to export: $hashpfx")
    }
}


# Create zip of $env:WinDir\System32\Certsrv\CertEnroll\
Compress-Archive -Path $env:WinDir\System32\Certsrv\CertEnroll\ -DestinationPath CertEnrollFolder.zip 

# Add that CertEnroll zip to the CA-Backup-$Ticks.zip:
Compress-Archive -Update -Path CertEnrollFolder.zip -DestinationPath "CA-Backup-$Ticks.zip"

# Delete the CertEnroll zip:
Remove-Item -Path CertEnrollFolder.zip


# Report or log something useful:
Write-Verbose -Verbose -Message "Backup Archive: CA-Backup-$Ticks.zip"




# FYI, to convert a ticks number back into a human-readable date and time,
# just pass it into Get-Date:
#
#    Get-Date 634119712163445855
#
# Or cast it:
#
#    [DateTime] 634119712163445855
#
# In a dir listing of many files, sort on the file name, and the name with the
# largest ticks number is the one generated most recently.  Filesystem
# timestamps can be lost as files are moved or restored from media.
