<# 

This script provides a convenient way to identify and export information about stale computer accounts in Active Directory based on their last logon timestamp, helping administrators manage their AD infrastructure effectively. 

#>

function Get-StaleADComputers {
    param(
        [int]$DaysInactive = 90,
        [string]$OutputPath = "C:\Temp\StaleComps.CSV"
    )

    $time = (Get-Date).AddDays(-$DaysInactive)

    Get-ADComputer -Filter {LastLogonTimeStamp -lt $time} -ResultPageSize 2000 -ResultSetSize $null -Properties Name, OperatingSystem, SamAccountName, DistinguishedName, LastLogonDate |
    Export-Csv -Path $OutputPath -NoTypeInformation
}
