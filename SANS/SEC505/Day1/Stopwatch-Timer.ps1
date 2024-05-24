<#
.SYNOPSIS
    How to use high-resolution timing to measure performance.
.NOTES
    https://docs.microsoft.com/en-us/dotnet/api/system.diagnostics.stopwatch
#>

# Create a new stopwatch timer
$Stopwatch = [System.Diagnostics.Stopwatch]::New()

# Start the timer
$Stopwatch.Start() 

# Do something useful that requires time
"Hello Kitty" * 100000 | Out-Null

"How many milliseconds and ticks so far?"
$Stopwatch.Elapsed.Milliseconds
$Stopwatch.Elapsed.Ticks

# Do something useful that requires time
"Hello Kitty" * 100000 | Out-Null

"How many milliseconds and ticks so far?"
$Stopwatch.Elapsed.Milliseconds
$Stopwatch.Elapsed.Ticks

# Stop the timer
$Stopwatch.Stop()

# Time elapsed during the timing
"Hours  : " + $Stopwatch.Elapsed.TotalHours
"Seconds: " + $Stopwatch.Elapsed.TotalSeconds
"Millis : " + $Stopwatch.Elapsed.TotalMilliseconds
"Ticks  : " + $Stopwatch.Elapsed.Ticks

# Reset the timer back to zero
$Stopwatch.Reset()

# How accurate is the timer?
$TicksPerSecond = [System.Diagnostics.Stopwatch]::Frequency
$NanoSecondsPerTick = 1e9 / $TicksPerSecond  #1e9 = 1 Billion
"Timer is accurate to within " + $NanoSecondsPerTick + " nanosecond(s)."

