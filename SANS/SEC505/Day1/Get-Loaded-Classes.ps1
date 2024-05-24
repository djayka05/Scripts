##############################################################################
#.SYNOPSIS
#   Get classes from all loaded .NET assemblies.
#.NOTES
#   Date: 16.May.2007
#   Version: 1.0
#   Author: Jason Fossen, Enclave Consulting LLC (BlueTeamPowerShell.com)
#   Legal: 0BSD
##############################################################################


Function Get-Loaded-Classes {
    [System.AppDomain]::CurrentDomain.GetAssemblies() | 
    foreach-object { $_.GetExportedTypes() } | 
    select-object fullname,assembly
}


get-loaded-classes | format-list


