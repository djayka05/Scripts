# Function to send email
function Send-Email {
    param(
        [string]$From,
        [string]$To,
        [string]$Subject,
        [string]$Body,
        [string]$SmtpServer,
        [int]$Port,
        [pscredential]$Credential
    )

    Send-MailMessage -From $From -To $To -Subject $Subject -Body $Body -SmtpServer $SmtpServer -Port $Port -Credential $Credential
}
