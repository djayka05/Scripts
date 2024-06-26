###########################################################################
<#
.SYNOPSIS
    A minimally-viable wrapper for running all the scripts in a folder.

.DESCRIPTION
    This script is a KISS wrapper for running all the PowerShell scripts
    in the $ScriptsFolderPath folder.  It is deliberately designed to
    be easy for a PowerShell beginner to modify, such as to add custom
    logging, while also avoiding The Curse of Over-Engineering.

    This script creates a global hashtable: $Global:Top.  $Top.Request can be
    set by any child script, for example, to "Reboot" or "Stop" to reboot the
    computer or to prevent this wrapper script from executing any further
    child scripts.  The reboot or cessation occurs after that child script
    finishes its execution, not during.  If necessary, a child script could 
    set $Top.Request to "Reboot" or "Stop" immediately, perform other  
    work, then set $Top.Request back to "Continue" just before finishing,
    which would allow this wrapper to resume execution of the other
    scripts on the list like normal.  Child scripts should avoid creating
    background jobs if possible to maintain a semblance of serial execution.  
    Beware of software packages being installed in the background taking longer
    than expected to complete the package installation.  

    If a child script throws an exception, or even if the $ErrorAction for
    a failed command in a child script is set to Stop, then the child script will
    terminate.  By default, this script will continue to run any remaining child 
    scripts, even if there is an error, unless '-ErrorAction Stop' is set. 

    To deal with the problem of shared state among the child scripts, either
    1) use the global $Top hashtable, 2) have the first script in the 
    list set other global variables as needed, or 3) store the state externally 
    somehow, e.g., file(s), registry value(s), etc.  The last script executed 
    could clean up this external state.  Note that the $Top global variable is 
    removed by this script when it finishes.  The assumption is that the child 
    scripts are not malicious, but may fail anyway, and that all of these scripts 
    are protected from unauthorized modification. 

.PARAMETER ScriptsFolderPath
    Path to folder with PowerShell scripts to run.  If this folder has any
    subdirectories, scripts into those subdirectories will NOT be run.  The 
    PowerShell scripts in this folder must be named "###-NAME.ps1" where the 
    name of each script must begin with exactly three numbers, followed by a 
    dash, followed by the rest of the script's name, and ending with ".ps1."  
    Specifically, the name must match this regular expression pattern: 
        ^[0-9]{3,3}\-.+\.ps1$
    Hence, "340-Patches.ps1" is valid, but none of the following are valid:
    "35-Patches.ps1", "350Patches.ps1", "3401-Patches.ps1", "Patches-370.ps1".
    The path defaults to $PWD\DefaultRunAll\ if no path is provided.

.PARAMETER DataFilePath
    The path to a .PSD1 PowerShell data file.  This will be imported into
    the $Global:Top hashtable with Import-PowerShellDataFile.  The .PSD1
    file will likely contain a hashtable of configuration settings required
    by one or more child scripts run by this wrapper.  It is not required.
    By default, this script will look for and import "DefaultDataFile.psd1"
    in the -ScriptsFolderPath directory, but no error is thrown if
    this file does not exist.  

.PARAMETER DataHashTable
    The argument must be a hashtable or a variable for a hashtable.  The
    keys and values will be added to the $Global:Top hashtable.  If a
    hashtable is given to this parameter, then any .PSD1 file given to
    the -DataFilePath parameter will be ignored.

.PARAMETER ErrorAction
    Just as a reminder, when you set "-ErrorAction Stop", if a child script 
    throws an exception or stops, then no further child scripts will be run.  
    By default, this script will continue to run any remaining child scripts 
    even when one child script throws an error or fails. 

.EXAMPLE

    .\Start-Top.ps1

     Runs all the scripts in numerical order from $PWD\DefaultRunAll\*.ps1 and,
     if it exists, imports the $PWD\DefaultRunAll\DefaultDataFile.psd1 hashtable. 

.EXAMPLE

    .\Start-Top.ps1 -ScriptsFolderPath .\IISTemplate

     Runs all the scripts in numerical order from $PWD\IISTemplate\*.ps1 and,
     if it exists, imports the $PWD\IISTemplate\DefaultDataFile.psd1 hashtable.

.EXAMPLE

    .\Start-Top.ps1 -ScriptsFolderPath .\IIS99 -DataFilePath .\Folder\Settings.psd1

    Runs all the scripts in numerical order from $PWD\IIS99\*.ps1, ignores the
    $PWD\IIS99\DefaultDataFile.psd1, if it exists, and instead imports the
    .\Folder\Settings.psd1 hashtable into $Global:Top.

.EXAMPLE

    $Config = @{ IPaddress = "10.4.3.2"; Mask = 24; Gateway = "10.4.3.1" }

    .\Start-Top.ps1 -ScriptsFolderPath .\IIS99 -DataHashTable $Config -ErrorAction Stop

    Runs the all scripts in numerical order from $PWD\IIS99\*.ps1, ignores any .PSD1
    files that may exist, and imports the $Config hashtable into $Global:Top. If
    any child script throws an exception, do not run any further child scripts.  

.NOTES
    Legal: 0BSD, no rights reserved, no warranties or guarantees.
    Updated: 21.Aug.2021 by JF@Enclave.
#>
###########################################################################

[CmdLetBinding()]
Param 
(
  $ScriptsFolderPath = (Join-Path -Path $PWD -ChildPath "DefaultRunAll"),
  $DataFilePath = (Join-Path -Path $ScriptsFolderPath -ChildPath "DefaultDataFile.psd1"),
  [System.Collections.Hashtable] $DataHashTable = @{}
) 



# The $Global:Top.Request variable is checked before every script execution.
# Each child script can set $Global:Top.Request to "Reboot" or "Stop" to
# either reboot the machine or prevent this wrapper from running any 
# more scripts.  The reboot or cessation comes *after* that child
# script finishes running, not during its execution.  The $Global:Top variable 
# is automatically removed after this wrapper script finishes normally.

$Global:Top = @{ Request = "Continue" } 


# Define your own list of legal $Top.Request values so that anything
# not on this list will be interpreted as a Stop request: 
$PermittedRequests = @('Continue','Reboot','Stop')


# Will return to $PWD after running this script:
$CurrentDir = $PWD



# Ensure that paths given are full paths, not relative paths:
if (Test-Path -Path $ScriptsFolderPath)
{ $ScriptsFolderPath = Get-Item -Path "$ScriptsFolderPath" | Select-Object -ExpandProperty FullName }
else
{ Throw "ERROR: Cannot find $ScriptsFolderPath" ; Exit } 

if (Test-Path -Path $DataFilePath)
{ $DataFilePath = Get-Item -Path "$DataFilePath" | Select-Object -ExpandProperty FullName } 



# Imperative: DO NOT RECURSE INTO SUBDIRECTORIES in this wrapper to build the list
# of scripts to run.  Sort these scripts by name to get the intended order.
# This is why it is critical that the scripts conform to the naming scheme: 
# alphabetically, "2222-name.ps1" comes before "300-name.ps1", not after. 
# This is why a script must have leading zeros, if necessary, like 001-script.ps1.

$Private:TargetScripts = Join-Path -Path $ScriptsFolderPath -ChildPath "*.ps1"

$Private:ScriptsToInvoke = @( dir -Path $TargetScripts -File -ErrorAction Stop | 
                              Sort-Object -Property Name | Select-Object -ExpandProperty FullName ) 



# Exit if there are no scripts to run:
if ($ScriptsToInvoke.Count -eq 0)
{ 
    #Throw "ERROR: There are no scripts to run in $ScriptsFolderPath" 
    Write-Verbose -Verbose "There are no scripts to run in $ScriptsFolderPath"
    Exit 
}



# Confirm that all the $ScriptsToInvoke conform to the naming requirements:
ForEach ($FullName in $ScriptsToInvoke)
{ 
    $Name = Split-Path -Path $FullName -Leaf

    # This regex pattern means, "The beginning of the string (^) must have exactly three ({3,3})
    # numbers ([0-9]), not letters, followed by a dash (\-), followed by anything not blank (.+)
    # and ending exactly with .ps1 (\.ps1$).  See https://www.regular-expressions.info/dotnet.html

    if ($Name -notmatch '^[0-9]{3,3}\-.+\.ps1$') 
    { 
       Throw "ERROR: $Name does not begin with three digits and a dash."
       Exit 
    } 
} 



# Import the data file, if any, into $Global:Top before any child scripts are run:
if ($DataHashTable.Keys.Count -ne 0)
{
    Write-Verbose -Verbose "Importing a hashtable in memory, not a file."
    $Global:Top += $DataHashTable 
    if (-not $?){ Throw "ERROR: Could not append the given hashtable." } 
}
elseif (Test-Path -Path $DataFilePath)
{
    Write-Verbose -Verbose "Importing $DataFilePath"
    $Global:Top += Import-PowerShellDataFile -Path $DataFilePath -ErrorAction Stop
    if (-not $?){ Throw "ERROR: Could not correctly import the given data file." } 
}
else
{
    Write-Verbose -Verbose "Importing nothing, no hashtable or data file given."
}



# $PriorScript is used for tracking which script was run last:
$Private:PriorScript = $ScriptsToInvoke[0] 

# $iCounter is used to count how many scripts were run:
$iCounter = 0


# This is the main execution loop: execute all the $ScriptsToInvoke after 
# checking the value of $Top.Request each time to see if the prior script 
# has requested a stop or reboot:
ForEach ($Script in $ScriptsToInvoke)
{ 
    # Change PWD to $ScriptsFolderPath every time, just in case a child script sets
    # the directory location somewhere else.  Important for relative paths in child scripts.
    cd $ScriptsFolderPath 

    if (-not ($Global:Top.ContainsKey('Request')))
    {
        Remove-Variable -Name Top -Scope Global 
        cd $CurrentDir
        Throw "FAULT: $PriorScript has removed the Request key in Top."
        Exit #Not required, but makes clear what happens.
    }
    elseif ($PermittedRequests -notcontains $Global:Top.Request)
    {
        Remove-Variable -Name Top -Scope Global 
        cd $CurrentDir
        Throw ("FAULT: $PriorScript has made an illegal request: '" + $Global:Top.Request + "'") 
        Exit #Not required, but makes clear what happens.
    }
    elseif ($Global:Top.Request -eq "Continue")
    {
        Write-Verbose -Verbose "Running $Script"
        # Without the Try-Catch, an exception in a child script stops this wrapper too.
        Try  
        { 
            $iCounter++   #Increment counter by +1.
            & $Script     #The call operator (&) means, "Run $Script in a new scope".
        }
        Catch 
        { 
            cd $CurrentDir

            if ($ErrorActionPreference -eq "Stop")
            {
                Remove-Variable -Name Top -Scope Global
                Throw  #Rethrow the exception from the child script
                Exit   
            }
            else
            {
                # Write the error, but resume running the rest of the child scripts
                Write-Error -Exception $Error[0].Exception -ErrorId "$Script" 
            }
        }

        
        # Keep track of what was just executed:
        $PriorScript = $Script 
    } 
    elseif ($Global:Top.Request -eq "Reboot")
    { 
        Remove-Variable -Name Top -Scope Global 
        cd $CurrentDir
        Write-Verbose -Verbose "REBOOT was requested by $PriorScript"
        Start-Sleep -Seconds 3  #Not required, just a courtesy to the human at the console...
        Restart-Computer -Force
    } 
    elseif ($Global:Top.Request -eq "Stop")
    { 
        Remove-Variable -Name Top -Scope Global 
        cd $CurrentDir
        Write-Verbose -Verbose "STOP was requested by $PriorScript"
        Exit
    }
    else
    {
        Remove-Variable -Name Top -Scope Global 
        cd $CurrentDir
        Throw "$PriorScript has done something strange..."
        Exit
    } 
} #ForEach Script


# It's possible that the very last script run requested a reboot or stop,
# so check $Top.Request one last time and then exit.
if (-not ($Global:Top.ContainsKey('Request')))
{
    Remove-Variable -Name Top -Scope Global 
    cd $CurrentDir
    Throw "FAULT: $PriorScript has removed the Request key in Top."
    Exit #Not required, but makes clear what happens.
}
elseif ($PermittedRequests -notcontains $Global:Top.Request)
{
    Remove-Variable -Name Top -Scope Global 
    cd $CurrentDir
    Throw ("FAULT: $PriorScript has made an illegal request: '" + $Global:Top.Request + "'") 
    Exit #Not required, but makes clear what happens.
}
elseif ($Global:Top.Request -eq "Reboot")
{ 
    Remove-Variable -Name Top -Scope Global 
    cd $CurrentDir
    Write-Verbose -Verbose "REBOOT was requested by $PriorScript"
    Start-Sleep -Seconds 3  #Not required, just a courtesy to the human at the console...
    Restart-Computer -Force
} 
elseif ($Global:Top.Request -eq "Stop")
{ 
    Remove-Variable -Name Top -Scope Global 
    cd $CurrentDir
    Write-Verbose -Verbose "STOP was requested by $PriorScript"
    Exit
}
else
{
    Remove-Variable -Name Top -Scope Global 
    cd $CurrentDir
    Write-Verbose -Verbose "Ran $iCounter of $($ScriptsToInvoke.Count) scripts ($(Get-Date))"
}

# FIN