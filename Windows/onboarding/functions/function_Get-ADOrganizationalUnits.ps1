function Get-ADOrganizationalUnits {

    # Record the start time
    $startTime = Get-Date

    param (
        [Parameter(Mandatory = $true)]
        [string]$Domain,
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]$Credential
    )

    # Get all OUs in the domain
    $ldapPath = "LDAP://$Domain"
    $root = New-Object DirectoryServices.DirectoryEntry($ldapPath, $Credential.UserName, $Credential.GetNetworkCredential().Password)
    $searcher = New-Object DirectoryServices.DirectorySearcher($root)
    $searcher.Filter = "(objectClass=organizationalUnit)"
    $searcher.PageSize = 1000

    try {
        $ous = $searcher.FindAll() | ForEach-Object {
            [PSCustomObject]@{
                Name = $_.Properties["name"][0]
                Path = $_.Properties["distinguishedname"][0]
            }
        }
        return $ous
    }
    catch {
        Write-Host "Failed to authenticate. Please check your credentials and try again." -ForegroundColor Red
        exit
    }

    # Record the end time
    $endTime = Get-Date

    # Calculate the duration
    $duration = New-TimeSpan -Start $startTime -End $endTime

    # Write the total runtime to a text file
    $logFilePath = "C:\Logs\Get-ADOrganizationalUnits.log"  # Modify this path as needed
    "Total runtime: $($duration.Hours) hours, $($duration.Minutes) minutes, $($duration.Seconds) seconds" | Out-File -FilePath $logFilePath

}
