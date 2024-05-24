##############################################################################
#.SYNOPSIS
#   Create a global/domain user account in AD using .NET classes directly.
#.NOTES
#    Date: 10.Sep.2007
# Version: 1.1
#  Author: Jason Fossen, Enclave Consulting LLC
#   Legal: 0BSD
##############################################################################


param ($UserName, $Container = "CN=Users", $Domain = "")


function Create-GlobalUser ($UserName, $Container = "CN=Users", $Domain = "") 
{ 
    $DirectoryEntry = new-object System.DirectoryServices.DirectoryEntry -arg $Domain
    $Container = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$Container," + $DirectoryEntry.DistinguishedName) 
    $DirectoryEntries = $Container.PSbase.Children
    
    $User = $DirectoryEntries.Add('CN=' + $UserName, 'User')    
    $User.PSbase.InvokeSet('sAMAccountName', $UserName)
    $User.PSbase.CommitChanges()
    
    $User.PSbase.InvokeSet('AccountDisabled', 'False')
    $User.PSbase.CommitChanges()

    $User.PSbase.Dispose() 
}


create-globaluser -username $username -container $container -domain $domain

