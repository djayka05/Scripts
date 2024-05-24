<#
.SYNOPSIS
Get certificate templates that allow the SAN to be supplied by enrollee.

.DESCRIPTION
In a Windows PKI, it is dangerous for a template to both allow the
enrollee to supply a Subject Alternative Name (SAN) in the certificate
enrollment request and also *not* require explicit approval of the 
request by a PKI manager. It is safer to either build the subject name
information from Active Directory (see the Subject Name tab in the
properties of a certificate template) or to require a CA manager to approve
to enrollment request (see the Issuance Requirements tab in the properties 
of template) when enrollees must be permitted to supply the subject name
in the request.  

It is normal that several built-in templates will be output by this script,
such as the following templates:

    EnrollmentAgentOffline  
    WebServer               
    CA                      
    SubCA                   
    IPSECIntermediateOffline
    OfflineRouter           
    CEPEncryption           
    ExchangeUser            
    ExchangeUserSignature   
    CrossCA                 
    CAExchange 

But are any of these templates loaded or enabled on the CA?  What are the
permissions on these templates?  Unneeded templates should be unloaded from
the CA.  Necessary templates should restrict the groups which have the
enroll or autoenroll permissions, especially those that allow the SANS to
be supplied by the enrollee.    

.PARAMETER DomainName
Either the DNS or NetBIOS name of the domain to be searched.
Defaults to the domain of the local computer.

.NOTES
Search docs.microsoft.com for msPKI-Certificate-Name-Flag and 
msPKI-Enrollment-Flag for documentation on these attributes.

Legal: 0BSD.
#>

Param ($DomainName)

Import-Module -Name ActiveDirectory -ErrorAction Stop

# Get the distinguished name of the desired domain, e.g., CN=testing,CN=local.
# Defaults to domain membership of the local computer.
if ($DomainName)
{ $DN = (Get-ADDomain -Identity $DomainName -ErrorAction Stop).DistinguishedName }
else
{ $DN = (Get-ADDomain -Current LocalComputer -ErrorAction Stop).DistinguishedName }

# Used with Get-ADObject
$SearchBase = "CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration," + $DN

# Get all certificate templates that permit "Supply in the request" on the
# Subject Name tab of the properties of the template (msPKI-Certificate-Name-Flag)
# but which also do NOT require "CA certificate manager approval" on the
# Issuance Requirements tab of the template (msPKI-Enrollment-Flag).
Get-ADObject -SearchBase $SearchBase `
             -Properties msPKI-Certificate-Name-Flag,msPKI-Enrollment-Flag `
             -Filter { 
                      (objectclass -eq "pKICertificateTemplate") 
                         -and
                      (msPKI-Certificate-Name-Flag -band 0x1) 
                         -and -not 
                      (msPKI-Enrollment-Flag -band 0x2)
                     } 





