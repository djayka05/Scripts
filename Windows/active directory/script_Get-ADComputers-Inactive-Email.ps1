<#

Overall, this script helps in identifying inactive enabled computers in Active Directory and notifies the specified recipient via email.

Defines variables such as $logdate for generating a timestamp, $logfile for specifying the path of the log file, and prompts the user to input SMTP server, sender address, and recipient address.

Sets up parameters like $DaysInactive to determine the threshold for inactive computers and constructs the email body and subject.

Utilizes a try-catch block to handle potential errors during execution.

Within the try block:

Retrieves a list of inactive enabled computers from Active Directory based on the specified criteria (last logon time and enabled status).
Exports the retrieved data to a CSV file specified by $logfile.
Sends an email with the CSV file attached.
In case of any errors during execution, the catch block catches and displays the error.

#>

# Define variables
$logdate = Get-Date -format yyyyMMdd
$logfile = "C:\Temp\ExpiredComputers - " + $logdate + ".csv"

# Prompt user for SMTP server, sender address, and recipient address
$smtpserver = Read-Host -Prompt "Enter SMTP Server"
$emailFrom = Read-Host -Prompt "Enter Sender Address"
$emailTo = Read-Host -Prompt "Enter Recipient Address"
$subject = "Inactive Enabled Computers in Active Directory"
$DaysInactive = 45 
$time = (Get-Date).Adddays(-($DaysInactive))
$body = "Attached you will find inactive computers file. Please review"

# Try block to handle potential errors
try {
    # Retrieve list of inactive enabled computers from Active Directory and export to CSV
    Get-ADComputer -Filter {LastLogon -lt $time -and enabled -eq $true} -Properties LastLogon, description |
    Select-Object Name, DistinguishedName, description, enabled, @{Name="Stamp"; Expression={[DateTime]::FromFileTime($_.LastLogon)}} |
    Export-Csv $logfile -NoTypeInformation

    # Send email with attachment
    Send-MailMessage -To $emailTo -From $emailFrom -Subject $subject -Body $body -Attachments $logfile -SmtpServer $smtpserver

    Write-Host "Script executed successfully. Email sent."
}
catch {
    # Catch any errors that occur during execution
    Write-Error "An error occurred: $_"
}
