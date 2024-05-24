######################################################################################
#.SYNOPSIS
#   Search text file with a list of regular expression patterns.
#
#.DESCRIPTION
#   Will compare each line of a text file against every regex
#   pattern provided in the -PatternsFile, producing a summary of matches
#   found, or, if -ShowMatchedLines is used instead, output only the 
#   lines that matched at least one regex pattern from the -PatternsFile.
#   Multi-line search is not supported.  Text file is probably a log file.
#
#.PARAMETER Path
#   Path to the text file to be searched line-by-line.  
#
#.PARAMETER PatternsFile
#   Path to a text file with regex patterns and their descriptions. Each
#   line of the patterns file must begin with a regex pattern, followed
#   by one or more tabs, followed by a description of what the regex
#   pattern means or indicates.
#   
#.PARAMETER ShowMatchedLines
#   Switch to output every line that matches at least one regex pattern
#   from the -PatternsFile.  Lines that match multiple regex patterns
#   will only be output once.
#
#.NOTES
#   Updated: 20.Jun.2021
#   Version: 3.1
#   Author: Jason Fossen, Enclave Consulting LLC, BlueTeamPowerShell.com
#   Legal: 0BSD
######################################################################################
[CmdletBinding()]
Param ($Path, $PatternsFile, [Switch] $ShowMatchedLines)

$StartTime = Get-Date #Use with -Verbose output for measuring performance. 

# Load file with the regex patterns, but ignore comments and blank lines.  
$Patterns = @( Get-Content -Path $PatternsFile | Where-Object { $_ -notmatch '^;|^#|^\W*$' } ) 
Write-Verbose -Message ([String] $Patterns.Count + " non-blank, uncommented lines read from patterns file.") 

$Hashtable = @{} # Table to hold all the regex patterns, descriptions and a counter for each.
$i = 0  # Counter for parsed regex patterns from $PatternsFile.

# Compile regex and assert single-line search.  Defaults to case-sensitive matching.  Case-insensitive is slower.
$RegExOptions = [System.Text.RegularExpressions.RegexOptions]::Compiled + [System.Text.RegularExpressions.RegexOptions]::Singleline #+ [System.Text.RegularExpressions.RegexOptions]::IgnoreCase 

# From each line in $patterns, extract the regex pattern and its description, add these 
# back as synthetic properties to each line, plus a counter of matches initialized to zero.
ForEach ($Line in $Patterns) 
{
    If ( $Line -match "(?<pattern>^[^\t]+)\t+(?<description>.+$)" )
    { 
        $i++ 
        $Hashtable.Add($i, @{ Counter = 0; Description = $Matches.Description; Pattern = [RegEx]::New($Matches.Pattern, $RegExOptions) } )
    }
    Else
    {
        Write-Verbose -Message ("Invalid pattern line: " + $Line) 
    }
}

Write-Verbose -Message ([String] $i + " patterns accepted and loaded.") 

# Must resolve full path to $Path or else StreamReader constructor will fail.
$Path = (Resolve-Path -Path $Path -ErrorAction Stop).Path 

# Use StreamReader to process read each line of the $Path, one line at a time, 
# Have to use StreamReader because Get-Content is too slow.  
$Reader = New-Object System.IO.StreamReader -ArgumentList "$Path" -ErrorAction Stop

[UInt64] $c = 0 #Line counter. 64-bit integer should be big enough...

# Read each line from $Path, then compare each line against the patterns.
While ( ($Line = $Reader.ReadLine()) -ne $null ) 
{
    $c++

    ForEach ($Thing in $Hashtable.Values) 
    {
        If ($Thing.Pattern.IsMatch($Line))
        {
            If ($ShowMatchedLines) { $Line; Break }  #Break out of foreach, one match is sufficient.
            $Thing.Counter++                         #Increment counter of matches.
        }     
    }
}


# Emit count of patterns that matched at least one line.
If (-not $ShowMatchedLines) 
{
    #Custom object for the output; needed for both WinPosh and PoshCore compat.
    $Out = ''| Select-Object -Property Count,Description,Pattern  

    ForEach ($Thing in $Hashtable.Values)
    { 
        if ($Thing.Counter -gt 0) 
        { 
            $Out.Count = $Thing.Counter
            $Out.Description = $Thing.Description
            $Out.Pattern = $Thing.Pattern.ToString()
            $Out 
        }
    }
}


$TimeSpan = New-TimeSpan -Start $StartTime -End (Get-Date) | Select-Object -ExpandProperty TotalSeconds 
Write-Verbose -Message ([String] $c + " lines processed from $Path.")
Write-Verbose -Message ( "Processing time was " + $TimeSpan + " seconds.") 
Write-Verbose -Message ( [String] ( [Math]::Round($c / $TimeSpan,0) ) + " lines processed per second.")

