<# 

This PowerShell script performs several tasks related to managing local user accounts, installing the Local Administrator Password Solution (LAPS), and updating Group Policy. 

$lapsAdmin = "laps_admin": Defines the name of the LAPS administrator account.
$administrator = "Administrator": Defines the name of the built-in Administrator account.

Defines a function named New-RandomPassword that generates a random password of 32 characters using a set of characters defined in the $chars variable.
Check if LAPS admin account exists:

If the LAPS admin account does not exist, generate a random password using the New-RandomPassword function and create the account using New-LocalUser.

Attempts to get the state (enabled/disabled) of the built-in Administrator account. If the account does not exist, it outputs "No such account exists".

If the Administrator account is enabled, it disables the account using Disable-LocalUser and sets a new random password.

Renames the built-in Administrator account to "default_admin" using Rename-LocalUser.

Adds the LAPS admin account to the Local Administrators group using Add-LocalGroupMember.

Checks if the directory C:\Temp\ exists and creates it if it doesn't using Test-Path and New-Item.

Checks if the LAPS client components are installed by testing the presence of Admpwd.dll in C:\Program Files\LAPS\CSE\.

If LAPS is not installed, it copies the LAPS MSI installer from a network location to C:\Temp\ and installs it silently using Start-Process with msiexec.exe.

Forces an immediate update of Group Policy on the computer using gpupdate /target:computer /force.
Overall, this script automates the setup and configuration of the LAPS administrator account, management of the built-in Administrator account, installation of LAPS if not already installed, and updating Group Policy. It ensures proper security practices by generating random passwords and renaming sensitive accounts.

#>

# BEGIN SCRIPT

$lapsAdmin = "laps_admin"
$administrator = "Administrator"

function New-RandomPassword { $chars = 'abcdefghijkmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_=+' 
	$password = "" 
		for ($i = 0; $i -lt 32; $i++) { 
            $password += 
$chars[(Get-Random -Minimum 0 -Maximum $chars.Length)] 
} 
	return $password
}

if (-not (Get-LocalUser -Name $lapsAdmin -ErrorAction SilentlyContinue)) { 
	$password = New-RandomPassword | ConvertTo-SecureString -AsPlainText -Force
        New-LocalUser -Name $lapsAdmin -Password $password -Description "LAPS Administrator"       
}
 
try {    
    $isEnabled = (Get-LocalUser $administrator -ErrorAction Stop).enabled
}

catch {
    "No such account exists"
}

if ($isEnabled) {
    Disable-LocalUser $administrator   
} 
	$password = New-RandomPassword | ConvertTo-SecureString -AsPlainText -Force

Set-LocalUser -Name $administrator -Password $password -Description "DO NOT ENABLE THIS ACCOUNT"
Rename-LocalUser -Name $administrator -NewName "default_admin"
Add-LocalGroupMember -Group "Administrators" -Member $lapsAdmin

$folderPath = "C:\Temp\"

if (-not (Test-Path -PathType Container $folderPath)) {
    New-Item -ItemType Directory -Path $folderPath
}

$lapsInstalled = Test-Path 'C:\Program Files\LAPS\CSE\Admpwd.dll'

if (-not $lapsInstalled) {
    
    $localPath = 'C:\Temp\LAPS.x64.msi'
    $msipath = '\\$env:USERDNSDOMAIN\SYSVOL\$env:USERDNSDOMAIN\Software\LAPS.x64.msi'
    Copy-Item -Path $msipath -Destination $localPath -Force
    Start-Process -FilePath msiexec.exe -ArgumentList "/i $localPath /qn" -Wait

}

gpupdate /target:computer /force 

