##############################################################################
#.SYNOPSIS
#	Just demos the Switch statement for file processing...
#.NOTES
#    Date: 21.May.2007
#  Author: Jason Fossen (BlueTeamPowerShell.com)
#   Legal: 0BSD
##############################################################################


$droptcp = $dropudp = $dropicmp = 0
$allowtcp = $allowudp = $allowicmp = 0

# Log file is locked, copy it to local folder:
copy-item $Env:SystemRoot\system32\LogFiles\Firewall\pfirewall.log .

switch -regex -file .\pfirewall.log {
	'DROP TCP'   {$droptcp++}
	'DROP UDP'   {$dropupd++}
	'DROP ICMP'  {$dropicmp++}
	'ALLOW TCP'  {$allowtcp++}
	'ALLOW UDP'  {$allowudp++}
	'ALLOW ICMP' {$allowicmp++}
}

""
"FIREWALL LOG SUMMARY:"
"------------------------------------"
"Dropped: TCP=$droptcp, UDP=$dropudp, ICMP=$dropicmp"
"Allowed: TCP=$allowtcp, UDP=$allowudp, ICMP=$allowicmp"
""

remove-item .\pfirewall.log


