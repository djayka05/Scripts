##############################################################################
#.SYNOPSIS
#   Send e-mail using SMTP or SMTPS.
#.DESCRIPTION
#   If multiple addresses to the addressing fields, separate with commas.
#   Use the -UseIntegrated switch to use NTLM or Kerberos with the
#   credentials of the person running the script.
#.NOTES
#    Date: 23.May.2007
# Version: 1.0
#  Author: Jason Fossen, Enclave Consulting LLC
#   Legal: 0BSD
##############################################################################


function Send-Email ($To, $CC, $BCC, $From, $Subject, $Body, $Attachments, $Username, $Password, 
                     $SmtpServer, [Switch] $UseIntegrated, [Switch] $UseSSL) 
{
    $mail = new-object System.Net.Mail.MailMessage
    $mail.To.Add($to)       
    $mail.From = $from   
    if ($cc)  { $mail.CC.Add($cc)   }
    if ($bcc) { $mail.BCC.Add($bcc) }
    if ($body){ $mail.Body = $body  }
    if ($subject) { $mail.Subject = $subject }

    $smtpclient = new-object System.Net.Mail.SmtpClient
    $smtpclient.Host = $smtpserver
    $smtpclient.Port = 25
    $smtpclient.Timeout = 10  #seconds

    if ($UseSSL) { $smtpclient.EnableSSL = $true ; $smtpclient.Port = 465 }

    if ($UseIntegrated)
        { $smtpclient.UseDefaultCredentials = $true }
    elseif ($username)
        { $smtpclient.Credentials = new-object System.Net.NetworkCredential($username, $password) 
          if (-not $UseSSL) { "WARNING: Password sent in plaintext! Use SSL!" }
        }
    else
        { $smtpclient.UseDefaultCredentials = $false } # Send message without authentication. 
   
    $smtpclient.Send($mail)
}

