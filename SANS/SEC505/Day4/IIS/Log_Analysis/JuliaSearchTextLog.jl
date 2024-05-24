#=
This is not a PowerShell script.  It is a Julia script (julialang.org).
Julia shares several similarities with PowerShell (both are dynamic and 
JIT-compiled languages), but Julia was not optimized for friendliness 
and systems administration, it was optimized for processing large 
datasets, statistics and scientific computation.  Your PowerShell script
could 'outsource' this kind of work to a Julia script and capture the
results back into your PowerShell script again.  As a DevOps automation 
language, PowerShell acts like a glue for orchestrating other tools.

This Julia script is similar to Search-TextLog.ps1.  This script is 
slower than PowerShell when the log file is 10MB in size and about
75% faster than PowerShell when the log file is 200MB in size.  When
working with log files that are GB or TB in size, the reduced wait
time might be significant enough to warrant 'outsourcing' to Julia.

This script outputs either raw log lines, if showmatchedlines is true,
or outputs JSON text for piping into CovertFrom-JSON, such as:

    $ouput = julia.exe juliascript.pl arg1 arg2 | convertfrom-json

Below are comments for a PowerShell coder learning Julia.  Julia and C# 
are both good languages to learn, if necessary, after learning PowerShell.
=#


# 'Using Dates' is similar to 'Import-Module -Name Dates'. 
using Dates


# 'Dates.now()' is similar to '[DateTime]::now'; in fact, both output
# a DateTime object for representing and manipulates dates and times.
scriptstarttime = Dates.now()


# Check the number of command-line arguments.  'ARGS' is similar to '$Args'.
if length(ARGS) < 2 || length(ARGS) > 3 
    println("Wrong number of arguments: PathToLogFile PathToPatternsFile [ShowMatchedLines]")
    exit(-1)
end


# Named parameters are not used in Julia, so ARGS must be processed separately.
# Notice that the first argument is ARGS[1], not ARGS[0].
path = ARGS[1]
patternsfile = ARGS[2]

# Treat showmatchedlines like a switch, so assume $false.  If there is a
# third argument to the script, set showmatchedlines to $true.
showmatchedlines = false
if length(ARGS) == 3; showmatchedlines = true; end


# A 'vector' is an array with only one dimension, like a list, not a grid.
# 'ReadLines' is like 'Get-Content' to read a text file into a vector/array.
patterns = readlines(patternsfile)


# A 'struct' is like a custom object with named properties.
# 'Mutable' means that objects created from the struct can be modified.
# '<variable>::<type>' constrains the type of data assigned to each property.
# The Pat structure/class will be used to create a vector/array of items
# parsed from the patterns file.
mutable struct Pat
    counter::Int32
    pattern::Regex
    description::String
end


# Create a vector/array of Pat objects of size length(patterns) above.
# The vector/array should be initially filled with undef(ined) objects.
pats = Vector{Pat}(undef,length(patterns))


# The lines of the patterns file have been read into the patterns vector/array.
# Process each line, ignore commented lines (beginning with ';' or '#') and ignore
# empty lines.  With a regex pattern, 'occursin' is similar to '-match'.  Remember
# that pats[] is a vector/array of Pat type objects.
for i = 1:length(patterns)
    if occursin(r"^;|^#",patterns[i]) || isempty(strip(patterns[i]))
        pats[i] = Pat(-1,r"A","BLANKORCOMMENTLINE")  #Counter set to -1 in Pat obj.
        continue
    end

    #Find position of the first tab character.
    pos = findnext("\t",patterns[i],1).start  
    
    #Extract and trim the regex pattern from line, convert to Regex type object.          
    reg = Regex(strip(SubString(patterns[i],1,pos))) 

    #Extract everything after the first tab, trim description text of all tabs.
    description = strip(SubString(patterns[i],pos))

    # Create a Pat object and put it into the pats[] vector/array.
    pats[i] = Pat(0,reg,description)
end


# This frees the memory of lines from the patterns file, which are no longer needed
# now that we have a pats[] vector, but it's not really needed, it's just to show
# that 'nothing' is similar to '$null' in PowerShell for the garbage collector.
patterns = nothing 


# ilines is a counter for the lines processed in the text file, and it is not defined
# inside a function or flow control block, hence, it is "global" to the script.
ilines = 0


# Process each line of the text file to be searched (path from ARGS[1]), incrementing
# the Pat counter whenever a regex matches the line.  But if showmatchedlines = true,
# then the first matching regex is enough, don't need the count of all matching regexes,
# so just output that line and move on to the next line.
for line in eachline(path)
    global ilines += 1
    for patr in pats #Process each regex pattern from the pats[] vector.
        # Counter was set above to -1 for blank or commented lines in the patterns file.
        if patr.counter != -1 && occursin(patr.pattern,line)
            patr.counter += 1
            if showmatchedlines
                println(line)
                break  #One regex match is enough, no need to look for more matches.
            end
        end
    end
end


# If not showmatchedlines, then output a summary of the count of matches as JSON text.
if !showmatchedlines
    # Remove every element of the pats vector where counter is not greater than zero.
    # The filter! function can be understood as, "Get every element of pats, put each
    # element in variable p, test whether 'p.counter > 0', and, if so, keep p in pats,
    # otherwise remove p from pats."  This is similar to Where-Object.
    filter!(p->(p.counter > 0),pats)

    # Output JSON for piping into PowerShell's CovertFrom-JSON
    if length(pats) == 0
        println("[]")
    else
        println("[")
        for i = 1:length(pats)
            print(" {\"Count\":",pats[i].counter,",\"Description\":","\"",pats[i].description,"\"}")
            if i < length(pats); print(",\n"); else print("\n"); end 
        end
        println("]")
    end

end


# Write some performance stats to StdErr for comparison with Search-TextLog.ps1.
timespan = Dates.now() - scriptstarttime
write(stderr,">>> Seconds: $(timespan.value / 1000)\n")
write(stderr,">>> Lines: $ilines\n") 
write(stderr,">>> Lines per Second: $(ilines / (timespan.value / 1000))\n")
