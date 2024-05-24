##############################################################################
#.SYNOPSIS
#   Get loaded .NET assemblies.
#.NOTES
#    Date: 16.May.2007
# Version: 1.0
#  Author: Jason Fossen, Enclave Consulting LLC (BlueTeamPowerShell.com)
#   Legal: 0BSD
##############################################################################


Function Get-Loaded-Assemblies {
    [System.AppDomain]::CurrentDomain.GetAssemblies() | 
    select-object FullName,Location
}

get-loaded-assemblies | format-list



