# Import individual function scripts
. "$PSScriptRoot\function_Get-GroupMembershipChanges.ps1"
. "$PSScriptRoot\function_Send-Email.ps1"

# Prompt user for email parameters
$From = Read-Host "Enter sender's email address (From)"
$To = Read-Host "Enter recipient's email address (To)"
$SmtpServer = Read-Host "Enter SMTP server address"
$Port = Read-Host "Enter SMTP server port"

# Prompt for email and password for credential
$Email = Read-Host "Enter email address for credential"
$Password = Read-Host -AsSecureString "Enter password for credential"

# Call Get-GroupMembershipChanges function to retrieve group membership changes
$emailBody = Get-GroupMembershipChanges

# Create credential object
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($Email, $Password)

# Email parameters
$emailParams = @{
    From       = $From
    To         = $To
    Subject    = "Group Membership Change Detected"
    SmtpServer = $SmtpServer
    Port       = $Port
    Credential = $Credential
}

# Call Send-Email function to send the email
Send-Email @emailParams -Body $emailBody
