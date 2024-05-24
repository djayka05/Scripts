##############################################################################
#.SYNOPSIS
#   Obtain the response text of an HTTP request (not including headers).
#.DESCRIPTION
#   You can use HTTPS if desired, but defaults to plaintext.  Uses
#   HTTP version 1.1 and the Host: request header is sent.
#.NOTES
#    Date: 23.Jun.2007
#  Author: Jason Fossen, Enclave Consulting LLC (BlueTeamPowerShell.com)
#   Legal: 0BSD
##############################################################################

param ( $URL = $(throw "Enter a URL!") )


function Get-HttpPage ( $URL = $(throw "Enter a URL!") )
{
    if ( $URL -notmatch '^http' ) { $URL = "http://" + $URL }
    $WebClient = new-object System.Net.WebClient
    $WebClient.DownloadString( $URL )
}


Get-HttpPage -url $URL 



