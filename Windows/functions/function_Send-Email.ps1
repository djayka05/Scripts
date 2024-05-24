# SMTP server details
$SmtpServer = Read-Host "SMTP Server"
$SmtpPort = Read-Host "Port"

# Sender and recipient details
$From = Read-Host "Sender Address"
$To = Read-Host "Recipient Address"
$Subject = "Test Email"
$Body = "This is a test email sent using PowerShell."

# Prompt for credentials
$Credentials = Get-Credential -Message "Enter your email credentials" -UserName $From

# Create SMTP client object
$SmtpClient = New-Object System.Net.Mail.SmtpClient($SmtpServer, $SmtpPort)
$SmtpClient.EnableSsl = $true
$SmtpClient.Credentials = $Credentials.GetNetworkCredential()

# Create email message
$Message = New-Object System.Net.Mail.MailMessage($From, $To, $Subject, $Body)

# Send email
try {
    $SmtpClient.Send($Message)
    Write-Host "Email sent successfully."
}
catch {
    Write-Host "Failed to send email. Error: $($_.Exception.Message)"
}
