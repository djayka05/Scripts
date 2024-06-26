<#
.Synopsis
   Disables Cortana and blocks outbound Cortana network traffic.

.DESCRIPTION
   Disables Cortana and blocks outbound Cortana network traffic using
   the Windows Firewall.  Requires a reboot.  The script does not disable
   or terminate any Cortana-related services or processes.  The search
   feature will still work to find local settings and apps.  Must be run
   as administrator.  Requires Windows 10 version 1607 or later.

.PARAMETER EnableCortana
   Switch to delete the firewall rules created by this script and to
   activate Cortana again.  Requires a reboot.

.PARAMETER Verbose
   Show verbose progress information. 

.EXAMPLE
   .\Block-Cortana.ps1 -Verbose

.EXAMPLE
   .\Block-Cortana.ps1 -EnableCortana -Verbose

.LINK
    http://www.zdnet.com/article/windows-10-tip-turn-off-cortana-completely/
    https://www.sans.org/sec505

.NOTES
   Version: 1.0. 
   Last Updated: 20-Aug-2016. 
   Author: Jason Fossen, Enclave Consulting LLC, no rights reserved.
   Legal: 0BSD.

   For Windows security and PowerShell training from @JasonFossen at
   the SANS Institute, please visit https://www.sans.org/sec505
#>

[CmdletBinding()] 
Param ( [Switch] $EnableCortana )


# Always create the registry key:
if (!(Test-Path -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search')) 
{     
    Write-Verbose -Message "Creating the 'Windows Search' key..."
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows' -Name 'Windows Search' -Force | Out-Null
}


# Remove or set the AllowCortana reg value:
if ($EnableCortana)
{ 
    Write-Verbose -Message "Removing the AllowCortana value (resets to factory default)..."
    Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name AllowCortana 
}
else
{
    Write-Verbose -Message "Setting AllowCortana to 0..."
    New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name AllowCortana -Value 0 -PropertyType DWORD -Force | Out-Null
}


# Enable/disable all factory default firewall rules related to Cortana:
if ($EnableCortana)
{
    Write-Verbose -Message "Enabling all built-in Cortana firewall rules..."
    Get-NetFirewallRule -DisplayGroup 'Cortana' | Enable-NetFirewallRule
    Get-NetFirewallRule | where {$_.DisplayGroup -like '*Microsoft*Windows*Cortana*'} | Enable-NetFirewallRule
}
else
{
    Write-Verbose -Message "Disabling all built-in Cortana firewall rules..."
    Get-NetFirewallRule -DisplayGroup 'Cortana' -ErrorAction SilentlyContinue | Disable-NetFirewallRule 
    Get-NetFirewallRule | where {$_.DisplayGroup -like '*Microsoft*Windows*Cortana*'} | Disable-NetFirewallRule
}


# Delete any existing rules previously created by this script:
Write-Verbose -Message "Deleting all blocking firewall rules previously created by this script..."

Get-NetFirewallRule -Direction Outbound -Action Block -Enabled True -PolicyStoreSource PersistentStore |
where { $_.DisplayName -like 'Block Cortana*' -and $_.Description -eq 'Block Cortana Outbound UDP/TCP Traffic (Scripted)' } |
Remove-NetFirewallRule 


# Don't go any further if -EnableCortana switch was used:
if ($EnableCortana){ return } 


# Create the 'Block Cortana Package' outbound firewall rule using the Cortana package SID number:
Write-Verbose -Message "Creating outbound blocking rule named 'Block Cortana Package'..."
$AppFilter = Get-NetFirewallRule -DisplayGroup 'Cortana' -Direction Outbound | Get-NetFirewallApplicationFilter
New-NetFirewallRule -Direction Outbound -Action Block -RemoteAddress Internet -Enabled True -PolicyStore PersistentStore -Name 'Block Cortana Package' -DisplayName 'Block Cortana Package' -Description 'Block Cortana Outbound UDP/TCP Traffic (Scripted)' -Package ($AppFilter.Package.ToString()) | Out-Null


# Create more firewall rules to block outbound Cortana by the paths to Cortana-related
# executables, just in case Microsoft goes all "tricksy hobbitses" on us...

# Get path to Cortana folder, and assume there should be only one:
$cortanaDir = @(dir $env:windir\SystemApps\Microsoft.Windows.Cortana_*)
if ($cortanaDir.Count -ne 1)
{ 
    Write-Error -Message "Too many Cortana folders found, or no Cortana folder found."
    $cortanaDir = $null #Required so that the dir below will fail.
} 
else
{ $cortanaDir = $cortanaDir[0].FullName } 


# Get paths to EXEs under the Cortana folder (don't hard-code, Microsoft may change them):
$cortanaEXEs = @(dir -Path $cortanaDir -Filter *.exe -Recurse -File -ErrorAction SilentlyContinue)


# Create outbound blocking rule for each EXE found:
if ($cortanaEXEs -eq $null -or $cortanaEXEs.Count -eq 0)
{ 
    Write-Error -Message "No Cortana-related EXEs found, no EXE rules created."
}
else
{
    ForEach ($EXE in $cortanaEXEs) 
    { 
        # Note: Do not edit the name or description text for the rules, they are used for deletions.
        # Note: The -RemoteAddress is "Internet" in case a future local intranet/subnet Cortana feature is desired later.
        $name = "Block Cortana " + $EXE.Name
        Write-Verbose -Message ("Creating outbound blocking rule named '" + $name + "'...")
        New-NetFirewallRule -Direction Outbound -Action Block -RemoteAddress Internet -Enabled True -PolicyStore PersistentStore -Name $name -DisplayName $name -Description 'Block Cortana Outbound UDP/TCP Traffic (Scripted)' -Program $EXE.FullName | Out-Null
    }
}

# Currently, there are no other known Cortana services or device drivers, but the WSearch service (SearchIndexer.exe)
# may become involved in the future, so it may become necessary to block its outbound traffic too -- but not yet.


# FIN
Write-Verbose -Message "Remember, a reboot is necessary for changes to take effect."

