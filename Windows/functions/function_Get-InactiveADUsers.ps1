<# 

This script retrieves inactive users from Active Directory, defined as users who haven't logged in for the last 90 days. It exports information about these inactive users, including their name, SamAccountName, and DistinguishedName, into a CSV file located at "C:\Temp\InactiveUsers.CSV" (or a specified output path if provided). Additionally, it ensures that only enabled users are included in the exported data. 

#>

function Get-InactiveADUsers {
    param(
        [string]$OutputPath = "C:\Temp\InactiveUsers.CSV"
    )

    $date = (Get-Date).AddDays(-90)

    Get-ADUser -Filter {LastLogonDate -lt $date} -Property Enabled |
    Where-Object {$_.Enabled -eq $true} |
    Select-Object Name, SamAccountName, DistinguishedName |
    Export-Csv -Path $OutputPath -NoTypeInformation
}

