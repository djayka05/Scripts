##############################################################################
#.SYNOPSIS
#   Get object constructor hints.
#.DESCRIPTION
#   Show information about the possible arguments to .NET constructors.
#   Pass in the name of a .NET class, such as "System.String", and
#   some crudely-formatted "help" is shown.
#.NOTES
#    Date: 16.May.2007
# Version: 1.0
#  Author: Jason Fossen, Enclave Consulting LLC (BlueTeamPowerShell.com)
#   Legal: 0BSD
##############################################################################


Function Get-Constructor-Hints ($classname) {
    $command = "[$classname]" + '.GetConstructors() | foreach-object { $_.getparameters() } | select-object  name,member' 
    invoke-expression $command
}

Get-Constructor-Hints $args[0] | format-table -autosize

