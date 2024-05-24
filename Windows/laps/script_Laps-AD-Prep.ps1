<#


#>

# BEGIN SCRIPT

# Check if Workstation Admins exists. If it does, skip this step. If it doesn't, create Workstation Admins group. 
$workstationAdmins = 'Workstation Admins'

try{
    if(Get-ADGroup -filter {Name -eq $workstationAdmins} -ErrorAction Continue)
    {
            $Result = "Already_Exists"
    } else
        {
            New-ADGroup -Name $workstationAdmins -GroupScope Global -GroupCategory Security -DisplayName "Workstation Administrators" -Description "Members of this group are Workstation Administrators"
            $Result = 'Success'
        }
}
catch{
$ErrorMessage = $_.Exception
}

# ************************* Result *********************************

$JSONOutput = @{"result"=$Result;"error"=$ErrorMessage} | ConvertTo-Json -Compress
Write-Output $JSONOutput


# Check if Server Admins exists. If it does, skip this step. If it doesn't, create Server Admins group. 
$serverAdmins = 'Server Admins'

try{
    if(Get-ADGroup -filter {Name -eq $computerGroup} -ErrorAction Continue)
    {
            $Result = "Already_Exists"
    } else
        {
            New-ADGroup -Name $serverAdmins -GroupScope Global -GroupCategory Security -DisplayName "Server Administrators" -Description "Members of this group are Server Administrators"
            $Result = 'Success'
        }
}
catch{
$ErrorMessage = $_.Exception
}

# ************************* Result *********************************

$JSONOutput = @{"result"=$Result;"error"=$ErrorMessage} | ConvertTo-Json -Compress
Write-Output $JSONOutput


# Part of this script requires installing the AdmPwd Powershell module. To do that, connectivity has to succeed to Microsoft using NuGet to download the module. this cannot happen if the security protocol being used is less than TLS 1.2. The next step runs .NET code to set this up. Without running the .NET code, installing the LAPS module could fail.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Note that you may want to look at extended rights. To do that, you would run this command. For more info as to why, refer to the link. https://4sysops.com/archives/faqs-for-microsoft-local-administrator-password-solution-laps/

$serverOU = Read-Host -Prompt "Paste OU Name"
$workstationOU = Read-Host -Prompt "Paste OU Name"

$serverOU1 = $serverOU
$workstationOU1 = $workstationOU

Find-AdmPwdExtendedrights -identity :$serverOU1 | Format-Table
Find-AdmPwdExtendedrights -identity :$workstationOU1 | Format-Table

Import-module AdmPwd.PS
Update-AdmPwdADSchema

# This where you'll need to set self-permissions so computers can read LAPS passwords. You may need to run these commands more than once and paste OUs when prompted. For example, if customer has workstations and servers in different OUs, you'll likely need to copy/paste DN of the OUs for both workstations and servers. If you're still unsure, contact the author of this script for clarificaiton. This cannot be hardcoded/defined because each customer domain is different.
Set-AdmPwdComputerSelfPermission -OrgUnit $serverOU1
Set-AdmPwdComputerSelfPermission -OrgUnit $workstationOU1

# Set OU read permissions for Server and Workstation Admins.
Set-AdmPwdReadPasswordPermission -OrgUnit $serverOU1 -AllowedPrincipals "Server Admins"
Set-AdmPwdReadPasswordPermission -OrgUnit $workstationOU1 -AllowedPrincipals "Workstation Admins"

# Set OU reset password permissions for Server and Workstation Admins.
Set-AdmPwdResetPasswordPermission -OrgUnit $serverOU1 -AllowedPrincipals "Server Admins"
Set-AdmPwdResetPasswordPermission -OrgUnit $workstationOU1 -AllowedPrincipals "Workstation Admins"