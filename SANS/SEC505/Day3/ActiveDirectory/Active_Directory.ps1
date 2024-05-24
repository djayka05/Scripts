Exit

# Import the Active Directory Module
Import-Module -Name ActiveDirectory

Get-Command -Module ActiveDirectory 



# Browse the AD:\ drive 
cd ad:\
dir
cd "dc=testing,dc=local"
dir
cd c:\




# Create and Delete User Accounts  
$pw = ConvertTo-SecureString "Pa55wurD" -AsPlainText -Force

New-ADUser -Name "Kim Pine" -SamAccountName "Kim" -AccountPassword $pw -Enabled $true -Path "ou=boston,ou=east_coast,dc=testing,dc=local"

Remove-ADUser -Identity Kim -Confirm:$False 

Remove-ADUser -Identity "cn=Kim Pine,ou=boston,ou=east_coast,dc=testing,dc=local"





# Reset Passwords
function Reset-Password ($UserName)
{
   $pw = Read-Host -Prompt "Enter New Password" -AsSecureString
   Set-ADAccountPassword -Identity $UserName -Reset -NewPassword $pw 
}

Reset-Password -UserName "Justin"





# Modify User Attributes
Set-ADUser -Identity Justin -Description "R&D" -EmailAddress "justin@testing.local" -SmartcardLogonRequired $true

Set-ADAccountExpiration -Identity "Justin" -TimeSpan "30"       #Days

Set-ADAccountExpiration -Identity "Justin" -TimeSpan "12:00"    #Hours

Set-ADAccountExpiration -Identity "Justin" -DateTime "5/18/2021 6:00 AM"

Clear-ADAccountExpiration -Identity "Justin"




# Enable, Disable and Unlock Users 
Unlock-ADAccount -Identity "Justin"

Disable-ADAccount -Identity "Justin"

Enable-ADAccount -Identity "Justin"

Enable-ADAccount -Identity "cn=Justin McCarthy,ou=boston,ou=east_coast,dc=testing,dc=local"




#The -Filter Parameter
Get-ADUser -Filter *

Get-ADUser -Filter { department -like "Engineer*" }

Get-ADUser -Filter { mail -notlike "*" }   #mail is blank/empty

Get-ADUser -Filter { logonCount -lt 3 }




#The -SearchBase Parameter
Get-ADUser -Filter * -SearchBase "ou=boston,ou=east_coast,dc=testing,dc=local"

Get-ADUser -Filter { badpwdcount -gt 10 } -SearchBase "ou=boston,ou=east_coast,dc=testing,dc=local"


Get-ADForest -Identity "testing.local"

Get-ADForest -Current "LocalComputer"

Get-ADForest -Current "LoggedOnUser"


Get-ADDomain -Identity "testing.local"

Get-ADDomain -Current "LocalComputer"

Get-ADDomain -Current "LoggedOnUser"




#Search for Anything: Get-ADObject
Get-ADObject -Filter { objectClass -eq "computer" } 

$Results = Get-ADObject -Filter { (objectClass -eq "user") -and (objectCategory -eq "person") } 




#Get-ADObject -SearchBase and -Filter  
$results = Get-ADObject -SearchBase "ou=boston,ou=east_coast,dc=testing,dc=local" -Filter { (objectclass -eq "user") -and (objectcategory -eq "person") -and (name -like "*admin*") -and (badpwdcount -gt 100) } 

$results = Get-ADObject -Filter {(objectclass -eq "computer")} -SearchBase "ou=hvt,dc=testing,dc=local" 

$30daysago = $(Get-Date) - $(New-TimeSpan -Days 30)
Get-ADObject -Filter { (objectclass -eq "organizationalunit") -and (whenCreated -gt $30daysago) }




#Randomize Smart Card Users' Passwords
$SmartPeople = Get-ADUser -SearchBase "ou=boston,ou=east_coast,dc=testing,dc=local" -Filter { SmartCardLogonRequired -eq $True } 

ForEach ($User in $SmartPeople)
{
   Set-ADUser -Identity $User -SmartcardLogonRequired $False
   Set-ADUser -Identity $User -SmartcardLogonRequired $True
}




# Manage Computer Accounts
New-ADComputer -SAMAccountName "LAPTOP47" -Name "LAPTOP47"

New-ADComputer -SAMAccountName "SERVER47" -Name "SERVER47" -Description "IIS for SharePoint" -Path "ou=boston,ou=east_coast,dc=testing,dc=local" 

Set-ADComputer -Identity "SERVER47" -OperatingSystem "Server 2019 Standard"

Remove-ADComputer -Identity "SERVER47" -Confirm:$False




# Manage Groups
New-ADGroup -Name "HR" -GroupScope "Global"

New-ADGroup -Name "Sales" -GroupScope "Global" -Path "ou=boston,ou=east_coast,dc=testing,dc=local" 

Add-ADGroupMember -Identity "Sales" -Members @("Justin","Administrator") 

$Members = Get-ADGroupMember -Identity "Sales"

Get-ADPrincipalGroupMembership -Identity "Justin"

Get-ADGroupMember -Identity "cn=Sales,ou=boston,ou=east_coast,dc=testing,dc=local"

Remove-ADGroup -Identity "Sales"

Remove-ADGroup -Identity "cn=Sales,ou=boston,ou=east_coast,dc=testing,dc=local"





##############################################################################
# FROM THE FIRST LAB
##############################################################################

# Switch into the C:\SANS\Day3\ActiveDirectory folder:
cd C:\SANS\Day3\ActiveDirectory


# Create an object to the represent the AD forest:
Get-ADForest -Current LocalComputer


# Get the list of AD replication sites for your forest:
Get-ADForest -Current LocalComputer | Select-Object -ExpandProperty Sites


# Get the name of the root domain of your forest:
(Get-ADForest -Current LocalComputer).RootDomain


# Create an object which represents the AD domain:
Get-ADDomain -Current LoggedOnUser


# Examine a few properties of your AD domain:
$mydomain = Get-ADDomain -Current LoggedOnUser

$mydomain.DistinguishedName

$mydomain.NetBIOSName


# Create an object to represent your user account in AD:
Get-ADUser -Identity "Administrator"


# Run the same command again, but also ask for the badPwdCount and mail properties:
Get-ADUser -Identity "Administrator" -Properties badPwdCount,mail


# Run the same command again, but ask for all of the user account's properties:
$me = Get-ADUser -Identity "Administrator" -Properties *

$me | Get-Member

$me | Select-Object objectClass,objectCategory

$me.badPwdCount

$me.mail


# Disable Alice's user account and reset her password to "P@ssword":
Get-ADUser -Identity "Alice" | Disable-ADAccount -PassThru | Set-ADAccountPassword -Reset -NewPassword (Read-Host -AsSecureString)


# Get the timestamp of when Alice's password was last set:
Get-ADUser -Identity "Alice" -Properties PasswordLastSet


# Extract just the PasswordLastSet property by itself: 
Get-ADUser -Identity "Alice" -Properties PasswordLastSet | Select-Object -ExpandProperty PasswordLastSet 


# Find users whose passwords never expire:
$Results = Search-ADAccount -PasswordNeverExpires 

ForEach ($User in $Results){ $User.DistinguishedName }


# Find all the user accounts currently disabled:
Search-ADAccount -AccountDisabled -UsersOnly


# Enable all the user accounts currently disabled:
Search-ADAccount -UsersOnly -AccountDisabled | Where { $_.Name -NotMatch 'Guest|krbtgt' } | Enable-ADAccount -PassThru | Export-Clixml -Path .\EnabledUsers.xml  

Import-Clixml -Path .\EnabledUsers.xml | Select Name,SID




##############################################################################
# FROM THE SECOND LAB
##############################################################################

# Switch into the C:\SANS\Day3\ActiveDirectory folder:
cd C:\SANS\Day3\ActiveDirectory

# Create an array of user account objects from the AD domain:
$Users = Get-ADUser -Filter * -Properties *

$Users.Count 

$Users | Select-Object -First 1 


# Export all user data to an XML file for safekeeping:
$Users | Export-Clixml -Path Users.xml


# Export just two user properties to a CSV file:
Import-Clixml -Path Users.xml | Select-Object SamAccountName,Department | Export-Csv -Path Departments.csv


# Peek at the Departments.csv file in Out-Gridview and also inside the command shell:
Import-Csv -Path Departments.csv | Out-GridView

Get-Content -Path Departments.csv 


# Update the department property of IT people:
Import-Clixml -Path Users.xml | Where { $_.Department -eq "IT" } | ForEach { Set-ADUser -Identity "$_" -Department "The IT Crowd" } 


# See the changes in AD: 
Get-ADUser -Filter * -Properties Department | Select-Object SamAccountName,Department 


# Get the users in the HVT organizational unit who have no email address:
$People = Get-ADUser -SearchBase "ou=hvt,dc=testing,dc=local" -Filter { mail -notlike "*" } 


# Assign each of these people a new e-mail address of the form "username@testing.local":
$People | ForEach { Set-ADUser -Identity $_ -EmailAddress ($_.SamAccountName + "@testing.local") } 


# Add those users to the Contractors global group in the Boston OU: 
Add-ADGroupMember -Identity "Contractors" -Members $People


