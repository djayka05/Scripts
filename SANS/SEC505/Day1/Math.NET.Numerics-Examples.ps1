<#
.SYNOPSIS
PowerShell can utilize the math libraries of Math.NET Numerics and the processor-optimized Intel Math Kernel Library﻿ (MKL).  To help coders get started, this article has a bunch of PowerShell examples of using Math.NET with Intel's MKL.  You might be pleasantly surprised at how easy it is to use.

Because source code can be hard to read in a blog, you can download a script with all the examples: get the SEC505 zip file from the Downloads page of http://cyber-defense.sans.org/blog, open it to the \Day1-PowerShell folder, and find the Math.NET.Numerics-Examples.ps1 script.  In the zip file you'll find over a hundred other PowerShell scripts, all in the public domain, used in my six-day SANS course Securing Windows with PowerShell (SEC505﻿).


.DESCRIPTION
Math.NET (www.MathDotNet.com) is a set of open source mathematical toolkits optimized for ease of use and performance. The Math.NET libraries are compatible with the Microsoft .NET Framework and the Mono project, which makes them accessible to PowerShell too. The toolkits are available for free under the MIT/X11 license, which is even more liberal than the GNU Public License (except for the Intel MKL, which has its own license).

One part of the Math.NET project is Math.NET Numerics, which is especially useful for math computations in science and engineering. It includes methods for statistics, probability, random numbers, linear algebra, interpolation, regression, optimization problems, and more. The project includes hardware-optimized native libraries to maximize performance on x64 or x86 processors utilizing Intel's Math Kernel Library (MKL).

The majority of computers used by scientists and engineers worldwide run Microsoft Windows. PowerShell is built into Windows and is relatively easy to learn.  Think of PowerShell as "simplified C#" for use in a command shell and in scripts.  Just like C#, PowerShell can access the .NET Framework; in fact, PowerShell itself is a .NET Framework application.

For scientists and engineers, PowerShell is great for managing long-running background jobs﻿, programmatically interacting with REST/SOAP/XML/JSON web applications﻿, doing quick-and-dirty distributed computing with Workflows and Remoting, importing/exporting data with Excel spreadsheets﻿, wrapping other programs and scripts to automate complex scheduled tasks, and quickly brainstorming or prototyping new ideas (which could then be later ported to C# because of the similarities between PowerShell and C#).  For data visualization, PowerShell and Math.NET can import and export data in a variety of file formats, including MATLAB, NIST Matrix Market, XML, CSV and TSV.

As an uncompiled and dynamically-typed language, PowerShell will never come close to the performance of C/C++, but with Math.NET and the Intel MKL provider, this is less of an issue. On the other hand, C/C++ will never match the convenience (and fun) of using PowerShell with Math.NET or Python with NumPy. 


.NOTES
Version: 1.6
Date: 22.May.2016
Author: Enclave Consulting LLC, Jason Fossen (http://www.sans.org/sec505) 
Legal: 0BSD.
#>



##########################################################################
##
## Overview and Installation
##
## http://numerics.mathdotnet.com
##
##########################################################################

# Overview of using compiled math libraries:
https://msdn.microsoft.com/en-us/library/vstudio/hh304368(v=vs.100).aspx#gg 


# See the main Math.NET Numerics project site:
http://numerics.mathdotnet.com


# With PoSh 5.0 or later, choose an appropriate folder for installing, then:
cd C:\SomeFolder
Install-Package -ProviderName NuGet -Name MathNet.Numerics -Destination .
Install-Package -ProviderName NuGet -Name MathNet.Numerics.MKL.Win-x64 -Destination . -Force
Install-Package -ProviderName NuGet -Name MathNet.Numerics.Data.Text -Destination . -Force
Install-Package -ProviderName NuGet -Name MathNet.Numerics.Data.Matlab -Destination . -Force


# If you do not have PoSh 5.0 or later, get the NUGET.EXE package installer:
http://docs.nuget.org/consume/installing-nuget


# Then, with NUGET.EXE, pick an appropriate folder, then install there:
cd C:\SomeFolder
.\nuget.exe install MathNet.Numerics
.\nuget.exe install MathNet.Numerics.MKL.Win-x64
.\nuget.exe install MathNet.Numerics.Data.Text
.\nuget.exe install MathNet.Numerics.Data.Matlab


# For the Intel MKL Native Provider (x86 or x64) see:
#    http://numerics.mathdotnet.com/MKL.html
# For simplicity, copy the two MKL DLLs (libiomp5md.dll and
# MathNet.Numerics.MKL.dll) from the package's Content folder
# into the same folder as your PowerShell script.  See the URL
# above for the use of other default paths instead.  Use of Intel
# MKL will greatly accelerate linear algebra tasks.


# For the MathNet.Numerics.Data.Text package for CSV
# files and NIST MatrixMarket files see:
#    http://numerics.mathdotnet.com/CSV.html
#    http://numerics.mathdotnet.com/MatrixMarket.html
#    http://math.nist.gov/MatrixMarket/


# For MATLAB Level-5 MAT files, see:
#    http://numerics.mathdotnet.com/MatlabFiles.html




##########################################################################
##
## Add Types and Create Shortcut Abbreviations
##
##########################################################################

# Switch to the folder where you installed the Math.NET package(s) for 
# your version of the .NET Framework (your folder will be different):
cd F:\MathNet\MathNet.Numerics.3.11.1\lib\net40


# Load the Math.NET Numerics DLL (nearly always required):
Add-Type -Path .\MathNet.Numerics.dll


# Load the MathNet.Numerics.Data.Text DLL (optional):
Add-Type -Path .\MathNet.Numerics.Data.Text.dll


# Create shortcuts for long type names (these are used throughout this script):
$MATRIX = [MathNet.Numerics.LinearAlgebra.Matrix[Double]] 
$VECTOR = [MathNet.Numerics.LinearAlgebra.Vector[Double]] 
$STAT = [MathNet.Numerics.Statistics.Statistics]  
$FUNC = [MathNet.Numerics.SpecialFunctions]



##########################################################################
##
## Intel Math Kernel Library (MKL) Native Provider
##
## http://numerics.mathdotnet.com/MKL.html
##
##########################################################################


# Enable the use of Intel MKL for linear algebra:
[MathNet.Numerics.Control]::UseNativeMKL("Auto")


# The legal options for the use of Intel MKL native provider above are
# Auto, Compatible, SSE2, SSE4_2, AVX, and AVX2 (see above command).
# It is highly recommended that you use the Intel MKL Native Provider!


# Confirm the switch from "Managed" to "Intel MKL":
[MathNet.Numerics.Control]::LinearAlgebraProvider


# If you want to switch back to the slower managed .NET code:
[MathNet.Numerics.Control]::UseManaged()


##########################################################################
##
## Intel MKL Performance Testing
##
## Test System:
##
##   Intel MKL x64 libiomp5md.dll file version 5.0.2015.609 (Sept 2015)
##   Intel Core i7-4790 CPU @ 3.60GHz
##   32GB Memory (DDR3 1600)
##   Windows 10 Pro (Build 10.0.10586.122)
##   PowerShell 5.0.10586.122
##   CLR Version 4.0.30319.42000
##
##########################################################################

# Use the Intel MKL provider whenever possible:
[MathNet.Numerics.Control]::UseNativeMKL("Auto")


# If you wish to use the slower .NET default (no MKL):
[MathNet.Numerics.Control]::UseManaged()


# Confirm the switch from "Managed" to "Intel MKL":
[MathNet.Numerics.Control]::LinearAlgebraProvider



# Multiply two 2000x2000 matrices of random doubles:
#    With Default:   4720.48ms average
#    With Intel MKL:  350.09ms average
#    MKL Increase:      13.5X
1..10 | ForEach { Measure-Command -Expression { $MATRIX::Build.Random(2000,2000) * $MATRIX::Build.Random(2000,2000) } } | Measure-Object -Property TotalMilliseconds -Average


# Compute eigenvalues and eigenvectors on a 1000x1000 matrix of random doubles:
#    With Default:   12554.58ms average
#    With Intel MKL:   694.03ms average
#    MKL Increase:      18.1X
1..10 | ForEach { Measure-Command -Expression { ($MATRIX::Build.Random(1000,1000)).Evd() } } | Measure-Object -Property TotalMilliseconds -Average


# Compute single value decomposition on a 1000x1000 matrix of random doubles:
#    With Default:   11167.04ms average
#    With Intel MKL:   362.52ms average
#    MKL Increase:      30.8X
1..10 | ForEach { Measure-Command -Expression { ($MATRIX::Build.Random(1000,1000)).Svd() } } | Measure-Object -Property TotalMilliseconds -Average


# Compute the inverse of a 1000x1000 matrix of random doubles:
#    With Default:   14536.91ms average
#    With Intel MKL:    64.10ms average
#    MKL Increase:     226.8X
1..10 | ForEach { Measure-Command -Expression { ($MATRIX::Build.Random(1000,1000)).Inverse() } } | Measure-Object -Property TotalMilliseconds -Average


# Compute the determinant of a 1000x1000 matrix of random doubles:
#    With Default:     371.14ms average
#    With Intel MKL:    39.61ms average
#    MKL Increase:       9.4X
1..10 | ForEach { Measure-Command -Expression { ($MATRIX::Build.Random(1000,1000)).Determinant() } } | Measure-Object -Property TotalMilliseconds -Average



##########################################################################
##
## Constants
##
## http://numerics.mathdotnet.com/Constants.html
##
##########################################################################

[MathNet.Numerics.Constants] | Get-Member -Static
[MathNet.Numerics.Constants]::Pi
[MathNet.Numerics.Constants]::Avogadro
[MathNet.Numerics.Constants]::ProtonMass



##########################################################################
##
## Creating Matrices
##
## http://numerics.mathdotnet.com/Matrix.html
##
##########################################################################

# Create a dense matrix of random numbers(3 rows, 4 columns):
$m = [MathNet.Numerics.LinearAlgebra.Matrix[Double]]::Build.Random(3, 4) 


# Create a dense zero-vector of length ten as [Double[]]:
$v = [MathNet.Numerics.LinearAlgebra.Vector[Double]]::Build.Dense(10)


# Create a dense matrix of random numbers(3 rows, 4 columns):
$MATRIX::Build.Random(3, 4)


# Create a dense zero-vector of length ten:
$VECTOR::Build.Dense(10)


# 3x4 dense matrix filled with zeros:
$MATRIX::Build.Dense(3, 4)


# 3x4 dense matrix filled with 1.0:
$MATRIX::Build.Dense(3, 4, 1.0)


# 3x4 dense matrix where each field is initialized using a function:
function myfunc ($i, $j){ (100 * $i) + $j } 
$MATRIX::Build.Dense(3, 4, (myfunc -i 3 -j 1) )


# 3x4 square dense matrix with each diagonal value set to 2.0:
$MATRIX::Build.DenseDiagonal(3, 4, 2.0)


# 3x3 dense identity matrix:
$MATRIX::Build.DenseIdentity(3)


# 3x4 dense random matrix sampled from a Gamma distribution:
$gammadist = [MathNet.Numerics.Distributions.Gamma]::Sample( 1.0, 5.0 ) 
$MATRIX::Build.Random(3, 4, $gammadist )


# Create a matrix in column major order (column by column):
[Double[]] $array = @( 1, 2, 3, 4,
                       5, 6, 7, 8,
                       9,10,11,12 )
$MATRIX::Build.DenseOfColumnMajor(3,4,$array) 


# Create a matrix from arrays representing columns:
[Double[]] $d1 = @( 1,4,7 )
[Double[]] $d2 = @( 2,5,8 )
[Double[]] $d3 = @( 3,6,9 )
$MATRIX::Build.DenseOfColumnArrays( @($d1,$d1,$d3) )


# Create a matrix of column vectors:
$MATRIX::Build.DenseOfColumnVectors( $VECTOR::Build.Random(3), $VECTOR::Build.Random(3) ) 



##########################################################################
##
## Creating Vectors
##
## http://numerics.mathdotnet.com/Matrix.html
##
##########################################################################

# Create a standard-distributed random vector of length 10:
$VECTOR::Build.Random(10)


# Create an all-zero vector of length 10:
$VECTOR::Build.Dense(10)


# Create a vector where each field is initialized using a function:
function myfunc ($i){ $i * $i } 
$VECTOR::Build.Dense(10, (myfunc -i 3) )


# Create a vector from an array of Double:
[Double[]] $d1 = @( 1,2,3,4,5 )
$VECTOR::Build.DenseOfArray( $d1 ) 



##########################################################################
##
## Matrix and Vector Arithmetic
##
## http://numerics.mathdotnet.com/Matrix.html
##
##########################################################################

# Create a matrix and vector to play around with:
[Double[]] $d1 = @( 1,4,7 )
[Double[]] $d2 = @( 2,5,8 )
[Double[]] $d3 = @( 3,6,9 )
[Double[]] $d4 = @( 10,20,30 )
$m = $MATRIX::Build.DenseOfColumnArrays( @($d1,$d1,$d3) )
$v = $VECTOR::Build.DenseOfArray( $d4 ) 


# Common arithmetic operators:
$m * $v 
$m + (2 * $m)


# Instance methods:
$m | Get-Member
$m.Multiply( $v )
$m.Add( $m.Multiply(2) )
$m.Transpose()
$m.Inverse()
$m.Nullity()
$m.Kernel()
$v.Sum()


# Instance methods for in-place operations:
$m.Multiply( $v, $v )   #Second arg captures output
$m.Multiply(  3, $m )   #Value of $m changes



##########################################################################
##
## Manipulating Matrices and Vectors
##
## http://numerics.mathdotnet.com/Matrix.html
##
##########################################################################

$m[0,0]               # Returns row 0, column 0
$m[2,0]               # Returns row 2, column 0
$m[0,2]               # Returns row 0, column 2
$m[0,2] = -1.0        # Assigns row 0, column 2 to -1.0

$m.Column(2)          # Returns entire 3rd column
$m.Row(1)             # Returns entire 2nd row

$m.SubMatrix(1,2,1,2) # Returns new matrix from an existing one

$m.ClearColumn(2)     # Set 3rd column to all zeros
$m.Clear()            # Set all columns to all zeros



##########################################################################
##
## Displaying Matrix and Vector Data
##
## http://numerics.mathdotnet.com/Matrix.html
##
##########################################################################

$m.RowCount           # Returns count of rows
$m.ColumnCount        # Returns count of columns

$m.ToColumnArrays()   # Emits an array of all values by column
$m.ToRowArrays()      # Emits an array of all values by row

$m.ToMatrixString()   # A 2D matrix as a string for printing

$v = $VECTOR::Build.Random(30)  # Fill a vector to have something to display
$v.Count              # Returns total number of items in vector
$v.ToArray()          # Returns array of items
$v                    # Same as $v.ToArray()
$v.ToString(5,80)     # max per column = 5, max columns = 80



##########################################################################
##
## Generating Data
##
## http://numerics.mathdotnet.com/Generate.html
##
##########################################################################

# List the generator functions supported:
[MathNet.Numerics.Generate] | Get-Member -Static


# Generate a range from 1..15, stepping by 1:
[MathNet.Numerics.Generate]::LinearRange(1,1,15) 


# Generate a range from 100..2000, stepping by 50:
[MathNet.Numerics.Generate]::LinearRange(100,50,2000) 


# Generate a sine wave of a given length, sampling rate, frequency, and amplitude:
[MathNet.Numerics.Generate]::Sinusoidal(15, 1000, 100, 10) 


# Generate 100 random numbers, uniformly distributed between 0 and 1:
[MathNet.Numerics.Generate]::Uniform(100) 



##########################################################################
##
## Random Numbers 
##
## http://numerics.mathdotnet.com/Random.html
##
##########################################################################

# Generate 1000 random numbers between 0 and 1 using the
# System.Security.Cryptography.RandomNumberGenerator class:
[Double[]] $samples = [MathNet.Numerics.Random.CryptoRandomSource]::Doubles(1000) 


# Overwrite the $samples array with new random numbers:
[MathNet.Numerics.Random.CryptoRandomSource]::Doubles($samples) 


# Generate an infinite sequence of random numbers:
ForEach ( $num in [MathNet.Numerics.Random.CryptoRandomSource]::DoubleSequence() ){ $num }


# Generate a random seed using System.Security.Cryptography.RandomNumberGenerator:
[MathNet.Numerics.Random.RandomSeed]::Robust()


# With Mersenne Twister 19937 generator, make five Doubles with a seed of 42:
[MathNet.Numerics.Random.MersenneTwister]::Doubles( 5, 42 ) 


# With Multiply-with-Carry XOR-Shift generator, make five Doubles with a seed 
# of 42 and a=9, c=6, x1=11, x2=12: 
[MathNet.Numerics.Random.Xorshift]::Doubles( 5, 42, 9, 6, 11, 12 )


# Fill an array of Byte[] with random bytes using the System.Random class:
[System.Byte[]] $buffer = 1..100
$rng = [MathNet.Numerics.Random.SystemRandomSource]::Default
$rng.NextBytes( $buffer ) 
$buffer -join ','


# Fill an array of Int32[] with random numbers between 4 and 999 using System.Random:
[Int32[]] $buffer = 1..100
$rng = [MathNet.Numerics.Random.SystemRandomSource]::Default
$rng.NextInt32s( $buffer, 4, 999 ) 
$buffer -join ','


# Generate five random Doubles using 42 as a seed:
[MathNet.Numerics.Random.SystemRandomSource]::Doubles( 5, 42 )




##########################################################################
##
## Distance Metrics
##
## http://numerics.mathdotnet.com/Distance.html
##
##########################################################################

# Sum of Absolute Difference (SAD):
[MathNet.Numerics.Distance]::SAD( [Double] 44, [Double] 55 ) 


# Sum of Squared Difference (SSD):
[MathNet.Numerics.Distance]::SSD( [Double] 44, [Double] 55 )


# Euclidean Distance:
[MathNet.Numerics.Distance]::Euclidean( [Double] 44, [Double] 55 )


# Hamming Distance:
[MathNet.Numerics.Distance]::Hamming( [Double] 44, [Double] 55 )



##########################################################################
##
## Descriptive Statistics
##
## http://numerics.mathdotnet.com/DescriptiveStatistics.html
##
##########################################################################

# There are four main classes with static methods for statistics:
[MathNet.Numerics.Statistics.Statistics] | Get-Member -Static


# Optimized for single-dimensional arrays:
[MathNet.Numerics.Statistics.ArrayStatistics] | Get-Member -Static


# Optimized for very large data sets:
[MathNet.Numerics.Statistics.StreamingStatistics] | Get-Member -Static 


# Optimized for sorted arrays:
[MathNet.Numerics.Statistics.SortedArrayStatistics] | Get-Member -Static


# Generate some Double[] data for the examples below:
[Double[]] $data = [MathNet.Numerics.Random.CryptoRandomSource]::Doubles(1000) 


# Common statistical calculations with unsorted data:
[MathNet.Numerics.Statistics.Statistics]::Mean($data)    #Mean or average, using full class name.
$STAT::Mean($data)       #Mean or average, but using the shortcut defined above.
$STAT::Median($data)     #Median
$STAT::Minimum($data)    #Minimum
$STAT::Maximum($data)    #Maximum
$STAT::PopulationVariance($data)  #Variance
$STAT::PopulationStandardDeviation($data)  #Standard Deviation
$STAT::Covariance($data, $data)   #Covariance


# Compute both mean and standard deviation simultaneously for efficiency:
$both = [MathNet.Numerics.Statistics.ArrayStatistics]::MeanStandardDeviation($data) 
$both.Item1   #mean
$both.Item2   #standard deviation


# When $data is sorted ascending, use SortedArrayStatistics instead:
[MathNet.Numerics.Statistics.SortedArrayStatistics]::Median($data) 


# Create a histogram of $data with 10 buckets:
$hist = New-Object -TypeName MathNet.Numerics.Statistics.Histogram -ArgumentList $data,10 
$hist.BucketCount
$hist.Item(0)        #First bucket
$hist.Item(9)        #Tenth bucket
$hist.Item(0).Count
$hist.Item(0).LowerBound
$hist.Item(0).UpperBound
$hist.Item(0).Width


# Output each bucket from histogram with properties:
function Get-Bucket ( $Histogram )
{
    $bucket = ' ' | select BucketIndex,Count,LowerBound,UpperBound,Width
    $lastbucket = $Histogram.BucketCount 
    for ($i = 0 ; $i -lt $lastbucket ; $i++)
    { 
        $bucket.BucketIndex = $i 
        $bucket.Count = $Histogram.Item($i).Count
        $bucket.LowerBound = $Histogram.Item($i).LowerBound 
        $bucket.UpperBound = $Histogram.Item($i).UpperBound 
        $bucket.Width = $Histogram.Item($i).Width 
        $bucket
    } 
}

Get-Bucket -Histogram $hist | Format-Table -AutoSize



##########################################################################
##
## Probability Distributions
##
## http://numerics.mathdotnet.com/Probability.html
##
##########################################################################

# Create a parameterized instance and show its distribution properties:
$gamma = New-Object -TypeName MathNet.Numerics.Distributions.Gamma -ArgumentList 2.0,1.5
$gamma 


# Distribution functions:
[Double] $a = $gamma.Density(2.3)                  # PDF
[Double] $b = $gamma.DensityLn(2.3)                # ln(PDF)
[Double] $c = $gamma.CumulativeDistribution(0.7)   # CDF


# Fill an array:
[Double[]] $data = 1..1000
$gamma.Samples($data) 




##########################################################################
##
## Special Functions and Trigonometry
##
## http://numerics.mathdotnet.com/Functions.html
##
##########################################################################

# Special Functions:
[MathNet.Numerics.SpecialFunctions]::Factorial(13)
[MathNet.Numerics.SpecialFunctions]::FactorialLn(31) #Log


[MathNet.Numerics.SpecialFunctions]::Binomial(15,7) 
[MathNet.Numerics.SpecialFunctions]::BinomialLn(15,7) #Log


[MathNet.Numerics.SpecialFunctions]::Gamma(33)
[MathNet.Numerics.SpecialFunctions]::GammaLn(33) #Log


# Using the FUNC shortcut defined above:
$FUNC::ExponentialIntegral(17,4) 
$FUNC::Beta(17,2)
$FUNC::Erf(0.9) 
$FUNC::Harmonic(37)


# Trigonometry
[MathNet.Numerics.Trig]::Cos(36)
[MathNet.Numerics.Trig]::Tan(12)
[MathNet.Numerics.Trig]::DegreeToRadian(360) 



##########################################################################
##
## Euclid and Number Theory
##
## http://numerics.mathdotnet.com/Euclid.html
##
##########################################################################

[MathNet.Numerics.Euclid]::GreatestCommonDivisor(99,33) 
[MathNet.Numerics.Euclid]::LeastCommonMultiple(3,5,6)
[MathNet.Numerics.Euclid]::IsPowerOfTwo(1024) 
[MathNet.Numerics.Euclid]::Remainder(7,3) 
[MathNet.Numerics.Euclid]::Modulus(-5,3)



##########################################################################
##
## Curve Fitting: Linear Regression
##
## http://numerics.mathdotnet.com/Regression.html
##
##########################################################################

# Compute intercept and slope using least squares fit:
[Double[]] $xdata = @(10,20,30,40,50)
[Double[]] $ydata = @(15,25,35,45,55)
$Line = [MathNet.Numerics.Fit]::Line($xdata, $ydata) 
$Line.Item1  #Intercept
$Line.Item2  #Slope


# Compute coefficient of determination:
[MathNet.Numerics.GoodnessOfFit]::RSquared($xdata, $ydata) 


# Polynomial regression of order 3:
[MathNet.Numerics.Fit]::Polynomial($xdata,$ydata,3) 


# Multiple regression with QR decomposition:
[Double[][]] $xy = @( [Double[]]@(1,4), [Double[]]@(2,5), [Double[]]@(3,2) )
[Double[]] $z = @(15,20,10) 
$QR = [MathNet.Numerics.LinearRegression.DirectRegressionMethod]::QR
[MathNet.Numerics.Fit]::MultiDim( $xy, $z, $true, $QR ) 



##########################################################################
##
## Loading and Saving Data Using MathNet.Numerics.Data.Text
##
## http://numerics.mathdotnet.com/CSV.html
##
##########################################################################

# The MathNet.Numerics.Data.Text package is available on NuGet as separate 
# package and not included in the basic distribution.


# Load the MathNet.Numerics.Data.Text DLL before calling the functions:
Add-Type -Path .\MathNet.Numerics.Data.Text.dll


# Function to save a matrix to a file:
# (Defaults to tab-delimited Double[] data with no column headers.)
Function Export-MatrixToFile 
{
    [CmdletBinding()] Param 
    (
        [Parameter(Mandatory = $true)] $FilePath,
        [Parameter(Mandatory = $true)] $Matrix,
        $DataType = "Double",
        $Delimeter = "`t",
        $ColumnHeaders = $Null,
        $Format = $Null,
        $FormatProvider = $Null,
        $MissingValue = $Null 
    ) 

    #If $FilePath is not explicit, assume present working directory:
    if ( ($FilePath -like '.\*') -or ($FilePath -notlike '*\*'))
    { $FilePath = "$pwd\$FilePath" } 

    $Methods = [MathNet.Numerics.Data.Text.DelimitedWriter].GetMethods() | Where { $_.IsStatic -and $_.IsPublic -and $_.Name -eq 'Write' }

    ForEach ($Method in $Methods)
    {   
        if ($Method.GetParameters() | Where {$_.Name -eq 'filePath'})
        {  
            $Generic = $Method.MakeGenericMethod($DataType) 
            $Generic.Invoke( [MathNet.Numerics.Data.Text.DelimitedWriter], @($FilePath, $Matrix, $Delimeter, $ColumnHeaders, $Format, $FormatProvider, $MissingValue)) 
            Return
        }
    }
}


# Example of calling the function:
$m = $MATRIX::Build.Random(500,500) 
Export-MatrixToFile -FilePath "output.tsv" -Matrix $m 




# Function to load a matrix from a file:
# (Defaults to tab-delimited Double[] data with no column headers.)
Function Import-MatrixFromFile 
{
    [CmdletBinding()] Param 
    ( 
        [Parameter(Mandatory = $true)] $FilePath, 
        $DataType = "Double", 
        $Sparse = $false, 
        $Delimeter = "`t", 
        $HasHeaders = $false, 
        $FormatProvider = $Null, 
        $MissingValue = $Null 
    )

    #Get full path to $FilePath
    $FilePath = @(dir $FilePath)[0].FullName

    $Methods = [MathNet.Numerics.Data.Text.DelimitedReader].GetMethods() | Where { $_.IsStatic -and $_.IsPublic -and $_.Name -eq 'Read' }

    ForEach ($Method in $Methods)
    {   
        if ($Method.GetParameters() | Where {$_.Name -eq 'filePath'})
        {  
            $Generic = $Method.MakeGenericMethod($DataType) 
            $Generic.Invoke( [MathNet.Numerics.Data.Text.DelimitedReader], @($FilePath, $Sparse, $Delimeter, $HasHeaders, $FormatProvider, $MissingValue)) 
            Return
        }
    }
}


# Example of calling the function:
Import-MatrixFromFile -FilePath "output.tsv" 



##########################################################################
##
## NIST Matrix Market Text Files
##
## http://numerics.mathdotnet.com/MatrixMarket.html
##
##########################################################################

# The MathNet.Numerics.Data.Text package is available on NuGet as separate 
# package and not included in the basic distribution.

# Load the MathNet.Numerics.Data.Text DLL:
Add-Type -Path .\MathNet.Numerics.Data.Text.dll


# Function to load a NIST Matrix Market file:
# (Defaults to uncompressed, matrix of Double[], not vectors.)
Function Import-NistMatrixMarketFile
{
    [CmdletBinding()] Param 
    (
        [Parameter(Mandatory = $true)] $FilePath,
        $DataType = "Double",
        [Switch] $IsVector,
        [Switch] $IsCompressed
    ) 

    #Assume file contains a matrix
    if ($IsVector){$Name = 'ReadVector'} else {$Name = 'ReadMatrix'} 

    #Assume file is not compressed
    if ($IsCompressed){ $Compression = [MathNet.Numerics.Data.Text.Compression]::GZip } 
    else { $Compression = [MathNet.Numerics.Data.Text.Compression]::Uncompressed } 

    #Get full path to $FilePath
    $FilePath = @(dir $FilePath)[0].FullName

    $Methods = [MathNet.Numerics.Data.Text.MatrixMarketReader].GetMethods() | Where { $_.IsStatic -and $_.IsPublic -and $_.Name -eq $Name } 

    ForEach ($Method in $Methods)
    {   
        if ($Method.GetParameters() | Where {$_.Name -eq 'filePath'})
        {  
            $Generic = $Method.MakeGenericMethod($DataType) 
            $Generic.Invoke( [MathNet.Numerics.Data.Text.MatrixMarketReader], @($FilePath, $Compression)) 
            Return
        }
    }
}


# Example of calling the function:
Import-NistMatrixMarketFile -FilePath "matrixmarket.mtx"






# Function to save a NIST Matrix Market file:
# (Defaults to matrix of Double[], not vector.)
Function Export-NistMatrixMarketFile
{
    [CmdletBinding()] Param 
    (
        [Parameter(Mandatory = $true)] $FilePath,
        [Parameter(Mandatory = $true)] $Matrix,
        $DataType = "Double",
        [Switch] $IsVector,
        [Switch] $IsCompressed
    ) 

    #Assume file will contain a matrix
    if ($IsVector){$Name = 'WriteVector'} else {$Name = 'WriteMatrix'} 
    
    #Assume file is not compressed
    if ($IsCompressed){ $Compression = [MathNet.Numerics.Data.Text.Compression]::GZip } 
    else { $Compression = [MathNet.Numerics.Data.Text.Compression]::Uncompressed }     

    #If $FilePath is not explicit, assume present working directory:
    if ( ($FilePath -like '.\*') -or ($FilePath -notlike '*\*'))
    { $FilePath = "$pwd\$FilePath" } 

    $Methods = [MathNet.Numerics.Data.Text.MatrixMarketWriter].GetMethods() | Where { $_.IsStatic -and $_.IsPublic -and $_.Name -eq $Name } 

    ForEach ($Method in $Methods)
    {   
        if ($Method.GetParameters() | Where {$_.Name -eq 'filePath'})
        {  
            $Generic = $Method.MakeGenericMethod($DataType) 
            $Generic.Invoke( [MathNet.Numerics.Data.Text.MatrixMarketWriter], @($FilePath, $Matrix, $Compression)) 
            Return
        }
    }
}


# Example of calling the function:
$m = $MATRIX::Build.Random(500,500) 
Export-NistMatrixMarketFile -FilePath "matrixmarket2.mtx" -Matrix $m

$v = $VECTOR::Build.Random(1000)
Export-NistMatrixMarketFile -FilePath "matrixmarket3.mtx" -Matrix $v -IsVector




##########################################################################
##
## Save or read large arrays of doubles to binary files very quickly.
## Uses System.Runtime.Serialization.Formatters.Binary.BinaryFormatter,
## which means any other .NET application can easily read it too, but
## the file contents are not text, i.e., not good for non-.NET apps.
## 
##########################################################################

#Test data saved or restored in about 300ms to a 200MB file:
$m1 = $MATRIX::Build.Random(5000,5000) 


function Save-NumericalArrayToFile ([String] $FilePath, $Array)
{
    if (($FilePath.IndexOf(':') -eq -1) -and (-not $FilePath.StartsWith('\\'))) 
    { throw 'FilePath must be a full explicit path!' ; return } 

    Try
    {
        $FileStream = New-Object -TypeName System.IO.FileStream -ArgumentList @( $FilePath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write) -ErrorAction Stop 
        $BinFormatter = New-Object -TypeName 'System.Runtime.Serialization.Formatters.Binary.BinaryFormatter' -ErrorAction Stop
        $BinFormatter.Serialize( $FileStream, $Array ) 
    }
    Catch { return $_ } 
    Finally { if ($FileStream){ $FileStream.Close() } }
}


Save-NumericalArrayToFile -FilePath 'f:\temp\serial.bin' -Array $m1.Values  #Notice the .Values on the matrix to return Double[]. 




function Read-NumericalArrayFromFile ([String] $FilePath)
{
    Try { $FilePath = (dir $FilePath -ErrorAction Stop | Resolve-Path -ErrorAction Stop).ProviderPath } Catch { return $_ } 
    
    Try
    {
        $FileStream = New-Object -TypeName System.IO.FileStream -ArgumentList @( $FilePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read) -ErrorAction Stop 
        $BinFormatter = New-Object -TypeName 'System.Runtime.Serialization.Formatters.Binary.BinaryFormatter' -ErrorAction Stop
        ,($BinFormatter.Deserialize( $FileStream )) #Don't delete the comma; returns the entire filled array.
    } 
    Catch { return $_ }
    Finally { if ($FileStream){ $FileStream.Close() } }
}


$data = Read-NumericalArrayFromFile -FilePath "f:\temp\serial.bin" 

# Note: you have to remember the shape of the matrix when restoring from the binfile.
# Consider saving to a file with the dimensions in the name of the file.
$m2 = $MATRIX::Build.DenseOfColumnMajor(5000,5000,$data) 

# Confirm reload:
$m1 -eq $m2  





##########################################################################
##
## Save and read data using Export/Import-CliXml.
## This is MUCH slower and the files are MUCH bigger, but it is XML.
## It would be far better to use .NET's XML serializer.
##
##########################################################################

# Create a matrix to save:
$OriginalMatrix = $MATRIX::Build.Random(5000,5000)


# Save as XML with UTF-8 encoding to reduce file size (creates a 1GB file):
# (Requires 68sec to save on an Intel Core i7-4790 @ 3.6GHz, SATA III drive.)
$OriginalMatrix | Export-Clixml -Encoding UTF8 -Path .\Matrix-5000x5000.xml 


# Restore the original matrix from XML using accelerator:
# (Requires 27sec to import XML and build matrix on test machine.)
[Double[]] $RestoredValues = (Import-Clixml -Path .\Matrix-5000x5000.xml).Values 
$RestoredMatrix = $MATRIX::Build.DenseOfColumnMajor(5000,5000,$RestoredValues) 





##########################################################################
##
## Misc Tips
##
##########################################################################

# List and use the methods of System.Math:
[MATH] | Get-Member -Static
[MATH]::PI
[MATH]::Pow(3,2) 
[MATH]::Round( [Double] 13.283928334, 5) 



# Number notes:
1e-3      #[Double] 0.001
986e+6    #[Double] 986,000,000
$i = [System.Numerics.Complex]::ImaginaryOne  #Square root of -1 for complex numbers
[Int64]::MaxValue
[UInt64]::MaxValue
[Decimal]::MaxValue
[Float]::MaxValue
[Double]::MaxValue
[BigInt] 202839723900997236320954029278819837329040934929712300349340934238712397208239237273232



# Preallocate memory for large lists and dictionaries and specify a fixed type using
# the System.Collections.Generic classes; for example, to create a list of
# ten million doubles and then fill the list (approx 400ms on my test machine):
$list = New-Object -TypeName 'System.Collections.Generic.List[Double]' -ArgumentList 10e6
$list.AddRange( $VECTOR::Build.Random(10e6) ) 
$list.Count



