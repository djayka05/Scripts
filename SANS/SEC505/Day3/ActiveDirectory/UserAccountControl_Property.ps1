<##########################################################
.NOTES
The UserAccountControl property of a domain user account is
a numeric field in which multiple bit flags can be set. 
Here is a list of Microsoft-defined constants for this bit
flags represented in hexadecimal.

For example, there is no such property as SmartCardLogonRequired.
This property is actually just a bit flag of the UserAccountControl
property.  Run the following command after (un)checking the box
for "Smart card is required for interactive logon" in the properties
of the Administrator account AD Users & Computers tool:

   Get-ADUser -Identity Administrator -Properties UserAccountControl,SmartcardLogonRequired

Because $ADS_UF_SMARTCARD_REQUIRED = 0x40000, and 0x40000 in
decimal is 262144, this decimal amount is added or subtracted
from the UserAccountControl property value in the user account.

To research one of these flags, do a search on the "ADS_UF_*"
name.  These are the official names of these constants in Windows.

Because UserAccountControl is a single property, if write permission
is granted to this property, any of the bit flags listed here
may be set by the grantee.  
##########################################################>


$ADS_UF_SCRIPT = 0x1                           #The logon script is executed. This flag does not work for the ADSI LDAP provider on either read or write operations.  For the ADSI WinNT provider, this flag is read only data, and it cannot be set on user objects. 
$ADS_UF_ACCOUNTDISABLE = 0x2                   #The account is disabled.
$ADS_UF_HOMEDIR_REQUIRED = 0x8                 #A home directory is required.
$ADS_UF_LOCKOUT = 0x10                         #The account is locked out.
$ADS_UF_PASSWD_NOTREQD = 0x20                  #A password is not required.
$ADS_UF_PASSWD_CANT_CHANGE = 0x40              #The user cannot change the password. You can read this flag, but you cannot set it directly.  
$ADS_UF_ENCRYPTED_TEXT_PASSWORD_ALLOWED = 0x80 #The user can send an encrypted password. 
$ADS_UF_TEMP_DUPLICATE_ACCOUNT = 0x100         #This is an account for users whose primary account is in another domain. This account provides user access to this domain, but not to any domain that trusts this domain. Also known as a local user account. 
$ADS_UF_NORMAL_ACCOUNT = 0x200                 #This is a default account type that represents a typical user. 
$ADS_UF_INTERDOMAIN_TRUST_ACCOUNT = 0x800      #This is a permit to trust account for a system domain that trusts other domains. 
$ADS_UF_WORKSTATION_TRUST_ACCOUNT = 0x1000     #This is a computer account that is a member of this domain. 
$ADS_UF_SERVER_TRUST_ACCOUNT = 0x2000          #This is a computer account for a backup domain controller that is a member of this domain. 
$ADS_UF_DONT_EXPIRE_PASSWD = 0x10000           #When set, the password will not expire on this account. 
$ADS_UF_MNS_LOGON_ACCOUNT = 0x20000            #This is an MNS logon account for a cluster. 
$ADS_UF_SMARTCARD_REQUIRED = 0x40000           #Interactive logon requires a smart card.
$ADS_UF_TRUSTED_FOR_DELEGATION = 0x80000       #When set, the service account (user or computer account), under which a service runs, is trusted for Kerberos delegation. Any such service can impersonate a client requesting the service. 
$ADS_UF_NOT_DELEGATED = 0x100000               #When set, the security context of the user will not be delegated to a service even if the service account is set as trusted for Kerberos delegation, i.e., the account is "sensitive." 
$ADS_UF_USE_DES_KEY_ONLY = 0x200000            #Restrict this principal to use only Data Encryption Standard (DES) encryption types for keys. 
$ADS_UF_DONT_REQUIRE_PREAUTH = 0x400000        #This account does not require Kerberos preauthentication for logon. 
$ADS_UF_PASSWORD_EXPIRED = 0x800000            #The user password has expired. UF_PASSWORD_EXPIRED is a bit created by the system, using data from the password last set attribute and the domain policy. It is read-only and cannot be set. To manually set a user password as expired, use USER_INFO_3 for Windows NT/Windows 2000 servers or USER_INFO_4 for Windows XP users. 
$ADS_UF_TRUSTED_TO_AUTHENTICATE_FOR_DELEGATION = 0x1000000    #The account is enabled for delegation. This setting enables a service running under the account to assume a client identity and authenticate as that user to other remote servers on the network. 


# PowerShell has bit-level/binary comparison operators: -band, -bor, -bxor, -bnot.
# PowerShell understands hexadecimal representations of bit patterns: 0x0, 0xFF, 0x1AF38CB14.
# (0x1 -band 0x1) evaluates to 0x1 in hex or 1 in decimal, both of which can be treated as 
# non-zero or $True-enough for the sake of conditional tests.  Hence, these all print "foo":
#       if(0x01 -band 0x1){"foo"}
#       if(0xFF -band 0x1B){"foo"}
#       if(0xDE934 -band 0x2000){"foo"}
#       if(0xD0934 -band 0x2000){"bar"}else{"foo"} 
#
# And you do not have to compare against hex, a decimal representation of the same bits is OK:
#       if(911668 -band 0x2000){"foo"}


# Get users with 'Smartcard required for interactive logon':
Get-ADUser -Filter { SmartCardLogonRequired -eq $True } 
Get-ADUser -Filter { UserAccountControl -band $ADS_UF_SMARTCARD_REQUIRED } 


# Get users with 'Account is sensitive and cannot be delegated':
Get-ADUser -Filter { UserAccountControl -band $ADS_UF_NOT_DELEGATED } 


# Get computers with 'Trust this computer for delegation to any service':
Get-ADComputer -Filter { UserAccountControl -band $ADS_UF_TRUSTED_FOR_DELEGATION }


# In the graphical property sheet of a computer account, you might think that the option
# to 'Trust this computer for delegation to specified sevices only' would also use
# a UserAccountControl flag, but actually not, it's a different property entirely: 
Get-ADComputer -Filter { msDS-AllowedToDelegateTo -like "*" } -Properties msDS-AllowedToDelegateTo


# Get service accounts that can authenticate to other systems as another user:
Get-ADObject -Filter { UserAccountControl -band $ADS_UF_TRUSTED_TO_AUTHENTICATE_FOR_DELEGATION }



