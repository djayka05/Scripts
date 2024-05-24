<# 

This script connects to a network share on a remote computer using specified credentials, creates a PSDrive to that share, and then executes a command located on that share on the remote computer. This is useful for remotely deploying software or executing scripts stored on a network share.

#>

# BEGIN SCRIPT

$credential = Get-Credential
$psdrive = @{
    Name = "PSDrive" 
    PSProvider = "FileSystem" 
    Root = "\\fileserver\share" 
    Credential = $credential
}

Invoke-Command -ComputerName $computerName -ScriptBlock {
    New-PSDrive @using:psdrive
    \\fileserver\share\installer.exe /silent 
}
