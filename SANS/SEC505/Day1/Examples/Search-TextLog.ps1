######################################################################################
#.SYNOPSIS
#   Search text log file with list of regular expressions.
#.DESCRIPTION
#   Will search every line of a textual log file against every regex
#   pattern provided in a second file, producing a summary of matches
#   found, or, if -ShowMatchedLines is specified, only the log lines
#   which matched at least one regex with no summary report.
#.PARAMETER LogFile
#   Path to text log file to be searched.
#.PARAMETER PatternsFile
#   Path to text file with regex patterns and their descriptions.
#.PARAMETER ShowMatchedLines
#   Switch to output matched log file lines and suppress summary.
#   Lines that match multiple regexes will only be output once.
#.NOTES
# Updated: 13.Jun.2012
# Version: 2.2
#  Author: Jason Fossen, Enclave Consulting LLC
#   Legal: 0BSD
######################################################################################

param ($LogFile, $PatternsFile, [Switch] $ShowMatchedLines)

# Load file with the regex patterns, but ignore blank lines.  
$Patterns = Get-Content -Path $PatternsFile | Where-Object {$_.length -ne 0} 

# From each line in $patterns, extract the regex pattern and its description, add these 
# back as synthetic properties to each line, plus a counter of matches initialized to zero.
foreach ($line in $Patterns) 
{
    if ( $line -match "(?<pattern>^[^\t]+)\t+(?<description>.+$)" )
    { 
        add-member -membertype NoteProperty -name Pattern     -value $matches.pattern     -input $line | out-null
        add-member -membertype NoteProperty -name Description -value $matches.description -input $line | out-null
        add-member -membertype NoteProperty -name Count       -value 0                    -input $line | out-null
    }
}

# Remove lines which could not be parsed correctly (they will not have a Count property).
# If you have comment lines, don't include any tabs in those lines so that they'll be ignored.
$Patterns = $Patterns | where-object { $_.count -ne $null } 

# Must resolve full path to $logfile or else StreamReader constructor will fail.
$LogFile = (Resolve-Path -Path $LogFile -ErrorAction Stop).Path 

# Use StreamReader to process each line of logfile, one line at a time, comparing each line against
# all the patterns, incrementing the counter of matches to each pattern.  Have to use StreamReader
# because get-content and the Switch statement are extremely slow with large files.  
$reader = New-Object System.IO.StreamReader -ArgumentList "$Logfile"

if (-not $?) { "`nERROR: Could not find file: $Logfile`n" ; exit }

while ( ($line = $reader.readline()) -ne $null ) 
{
    #Ignore blank lines and comment lines.
    if ($line.length -eq 0 -or $line.startswith(";") -or $line.startswith("#") ) { continue }

    foreach ($pattern in $Patterns) 
    {
        if ($line -match $pattern.pattern) 
        {
            if ($ShowMatchedLines) { $line ; break }  #Break out of foreach, one match is sufficient.
            $pattern.count++ 
        }     
    }
}


# Emit count of patterns that matched at least one line.
if (-not $ShowMatchedLines) 
{
    $Patterns | Where-Object { $_.Count -gt 0 } | 
    Select-Object Count,Description,Pattern | Sort-Object Count -Descending
}



