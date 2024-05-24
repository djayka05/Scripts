<#

Get the hostname of the computer running the script:

$hostname = $env:COMPUTERNAME: Retrieves the hostname of the local computer where the script is executed using the COMPUTERNAME environment variable.
Get the current domain context:

$domainContext = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain(): Retrieves the current domain context using .NET's System.DirectoryServices.ActiveDirectory.Domain class.
Retrieve the domain distinguished name:

$domainDN = $domainContext.GetDirectoryEntry().Properties["distinguishedName"].Value: Retrieves the distinguished name (DN) of the current domain by accessing the distinguishedName property of the domain's directory entry.
Define the LDAP path for the domain:

$ldapPath = "LDAP://$domainDN": Constructs the LDAP path for the domain using the retrieved distinguished name.
Specify the custom registry key path:

$registryKeyPath = "HKLM:\Software\lapsadmin\LAPSExpiration": Specifies the path for the registry key where the LAPS expiration time will be written.
Create a directory searcher object:

$searcher = New-Object DirectoryServices.DirectorySearcher([ADSI]$ldapPath): Creates a directory searcher object to search for computer objects in Active Directory within the specified LDAP path.
Set the search filter:

$searcher.Filter = "(&(objectClass=computer)(Name=$hostname))": Sets the search filter to find a computer object with a matching hostname.
Find the computer object in Active Directory:

$searchResult = $searcher.FindOne(): Executes the search and retrieves the first search result.
Check if the computer object is found:

if ($searchResult -ne $null) { ... }: Checks if the search result is not null, indicating that the computer object was found in Active Directory.
Retrieve the LAPS expiration time attribute:

$lapsExpiration = $searchResult.Properties["ms-Mcs-AdmPwdExpirationTime"]: Retrieves the value of the LAPS expiration time attribute (ms-Mcs-AdmPwdExpirationTime) from the computer object's properties.
Convert LAPS expiration time to a readable format:

$lapsExpirationTime = [datetime]::FromFileTime([long]::Parse($lapsExpiration[0])): Converts the LAPS expiration time value from a file time format to a DateTime object.
Write the LAPS expiration time to the registry:

New-Item -Path $registryKeyPath -Force | Out-Null: Creates a new registry key if it doesn't exist, suppressing any output.
Set-ItemProperty -Path $registryKeyPath -Name "LAPSExpirationTime" -Value $lapsExpirationTime: Sets the value of the "LAPSExpirationTime" property under the specified registry key with the converted LAPS expiration time.
Output status messages:

Write-Host "LAPS expiration time written to registry: $lapsExpirationTime": Displays a message indicating that the LAPS expiration time has been successfully written to the registry.
This script essentially searches Active Directory for the computer object matching the hostname of the local machine, retrieves its LAPS expiration time attribute, converts it to a readable format, and writes it to the registry under a specified key path.

#>

# BEGIN SCRIPT

$hostname = $env:COMPUTERNAME
$domainContext = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
$domainDN = $domainContext.GetDirectoryEntry().Properties["distinguishedName"].Value
$ldapPath = "LDAP://$domainDN"
$registryKeyPath = "HKLM:\Software\lapsadmin\LAPSExpiration"
$searcher = New-Object DirectoryServices.DirectorySearcher([ADSI]$ldapPath)
$searcher.Filter = "(&(objectClass=computer)(Name=$hostname))"
$searchResult = $searcher.FindOne()

if ($null -ne $searchResult) {
    $lapsExpiration = $searchResult.Properties["ms-Mcs-AdmPwdExpirationTime"]

    if ($lapsExpiration.Count -gt 0) {
        $lapsExpirationTime = [datetime]::FromFileTime([long]::Parse($lapsExpiration[0]))

        New-Item -Path $registryKeyPath -Force | Out-Null
        Set-ItemProperty -Path $registryKeyPath -Name "LAPSExpirationTime" -Value $lapsExpirationTime
        Write-Host "LAPS expiration time written to registry: $lapsExpirationTime"
    } else {
        Write-Host "LAPS expiration time not found."
    }
} else {
    Write-Host "Computer object not found."
}
