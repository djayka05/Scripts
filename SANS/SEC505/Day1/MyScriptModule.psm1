# To import a module not in the module search paths:
#     Import-Module -Name .\MyScriptModule.psm1
#     dir .\MyScriptModule.psm1 | Import-Module


# Modules may include commands, not just functions, and these
# commands will execute when the module is imported just like
# when running a regular script:
#     Get-Process | Out-File ThisWillBeCreated.txt


# Functions defined in a .psm1 file are imported into the 
# function:\ drive in the current session by default.
# Using the New-ModuleManifest cmdlet, you can specify
# metadata about your module, including which functions
# are made publicly available from it.  A manifest file
# ends with the .psd1 extension, not .psm1.


function Start-FavoriteProcess
{
    Start-Job -Name FavoriteProcess -ScriptBlock { Get-Process } | Out-Null
}


function Stop-FavoriteProcess
{
    Stop-Job -Name FavoriteProcess -PassThru | Remove-Job
}


function Repair-FavoriteProcess
{
    "This function will not be exported,"
    "it is private, i.e., it is only visible"
    "or accessible from within the module."
}

# Note: See "Get-Help *-Job*" to understand the Job cmdlets above.

# Instead of using a .psd1 manifest file to define the
# functions and other members of module which are to be
# made publicly visible, visibility can be managed within
# the .psm1 module file itself with Export-ModuleMember.
# If you do not export any members explicitly, all members
# are exported by default.  Functions, cmdlets, variables
# and aliases may be exported. Once you explicitly export
# even one member, all members become priviate, i.e., not
# visible or accessible outside the module, by default.

Export-ModuleMember -Function Start-FavoriteProcess
Export-ModuleMember -Function Stop-FavoriteProcess


# Like any PowerShell command or script, it is possible
# to create, read and write to a GLOBAL variable, i.e.,
# a variable that any other command or script can see
# and modify as well, which is a problem.  Instead of 
# using a GLOBAL scope variable in a module, use a 
# variable with SCRIPT scope instead.  A SCRIPT scope
# variable defined in a module is available to all the
# commands and functions from that module, but only that
# module.  The SCRIPT scope variable cannot be seen or
# modified by any other commands besides those defined
# in the module itself.  Thus, a SCRIPT scope variable
# is both private to the module and persists over time
# in the session to maintain state from one command
# invocation to the next.

# A GLOBAL variable is editable by any command in the session:
$GLOBAL:VisibleToEveryOne = "Go ahead and modify me!"

# A SCRIPT variable defined in a module is only visible 
# and editable by code implemented in the module:
$SCRIPT:OnlyVisibleToMyModule = 0

function Add-One { $SCRIPT:OnlyVisibleToMyModule += 1 } 
function Remove-One { $SCRIPT:OnlyVisibleToMyModule -= 1 } 
function Get-One { $SCRIPT:OnlyVisibleToMyModule } 
function Set-One ($Value) { $SCRIPT:OnlyVisibleToMyModule = $Value } 

Export-ModuleMember -Function Add-One 
Export-ModuleMember -Function Remove-One 
Export-ModuleMember -Function Get-One 
Export-ModuleMember -Function Set-One 




