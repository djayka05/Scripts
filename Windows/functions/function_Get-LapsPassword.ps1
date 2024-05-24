<#

Get-LAPSPassword retrieves the Local Administrator Password Solution (LAPS) password for the current computer from Active Directory. Upon execution, it obtains the current computer name and domain. It constructs an LDAP path to the domain controller and creates a DirectoryEntry object for the domain. Utilizing a DirectorySearcher object, it seeks the current computer object in Active Directory based on its Common Name (CN). Upon successful retrieval, it extracts the LAPS password attribute (ms-Mcs-AdmPwd) and displays it. If the computer object is not found, an appropriate message is displayed. Error handling mechanisms are in place to manage exceptions, ensuring smooth execution. Resources are properly disposed of in the final block. By encapsulating the functionality within a function, this script provides a reusable and modular solution for retrieving LAPS passwords for domain-joined computers.

#>

function Get-LAPSPassword {
    [CmdletBinding()]
    param ()

    # Get the current computer name
    $computerName = $env:COMPUTERNAME

    # Get the current domain
    $currentDomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
    $domainName = $currentDomain.Name

    # Construct the LDAP path to the domain
    $ldapPath = "LDAP://$($currentDomain.FindDomainController().Name)"

    # Create a DirectoryEntry object for the domain
    $directoryEntry = New-Object System.DirectoryServices.DirectoryEntry($ldapPath)

    # Create a DirectorySearcher object to search for the current computer object
    $searcher = New-Object System.DirectoryServices.DirectorySearcher($directoryEntry)
    $searcher.Filter = "(&(objectClass=computer)(cn=$computerName))"

    # Specify the attribute to retrieve (ms-Mcs-AdmPwd)
    $searcher.PropertiesToLoad.Add("ms-Mcs-AdmPwd")

    try {
        # Perform the search
        $result = $searcher.FindOne()

        if ($null -ne $result) {
            # Retrieve the ms-Mcs-AdmPwd attribute
            $admPwd = $result.Properties["ms-Mcs-AdmPwd"][0]

            # Output the attribute with colors
            Write-Host ""
            Write-Host "LAPS password for ${computerName}:  " -NoNewline -ForegroundColor Green
            Write-Host "$admPwd"
        } else {
            Write-Host ""
            Write-Host "Computer $computerName not found in Active Directory." -ForegroundColor Red
        }
    } catch {
        Write-Host "An error occurred: $_"
    } finally {
        $directoryEntry.Dispose()
        $searcher.Dispose()
    }
}
