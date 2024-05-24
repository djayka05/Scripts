<#


#>

# BEGIN SCRIPT

$Temp = "C:\Temp"
$Source = "C:\Temp\SysInternals\"
$Destination = "C:\Windows\System32\"

# Download latest version of SysInternals, extract to C:\Temp, move items to C:\Windows\System32, delete ZIP and folder.
Invoke-WebRequest "https://download.sysinternals.com/files/SysinternalsSuite.zip" -OutFile "$Temp\SysinternalsSuite.zip"
Expand-Archive "$Temp\SysinternalsSuite.zip" -DestinationPath $Source -Force
Remove-Item "$Temp\SysinternalsSuite.zip"
Move-Item -Path $Source\*.* -Destination $Destination -Force
Remove-Item -Path $Source