##############################################################################
#.SYNOPSIS
#   Demo how to query Windows Event Logs using WMI.
#.NOTES
#   Updated: 27.Oct.2017
#   Created: 30.May.2007
#   Version: 2.0
#   Author: Jason Fossen, Enclave Consulting LLC
#   Legal: 0BSD
##############################################################################


$computer = "."     # A period indicates the local machine, the default.

$query = "SELECT * FROM Win32_NTLogEvent WHERE logfile = 'Security' AND EventCode = '529' OR EventCode = '4625'"       # Bad username/password.
# $query = "SELECT * FROM Win32_NTLogEvent WHERE logfile = 'Security' AND EventCode = '528' OR EventCode = '4624'"     # Successful logons.
# $query = "SELECT * FROM Win32_NTLogEvent WHERE logfile = 'Security' AND EventCode = '644'"       # Account lockout.
# $query = "SELECT * FROM Win32_NTLogEvent WHERE logfile = 'Security' AND EventCode = '624'"       # User account created.
# $query = "SELECT * FROM Win32_NTLogEvent WHERE logfile = 'Security' AND EventCode = '627'"       # Password change attempted.
# $query = "SELECT * FROM Win32_NTLogEvent WHERE logfile = 'Security' AND EventCode = '628'"       # Password change successful.
# $query = "SELECT * FROM Win32_NTLogEvent WHERE logfile = 'Security' AND EventCode = '629'"       # User account disabled.
# $query = "SELECT * FROM Win32_NTLogEvent WHERE logfile = 'Security' AND EventCode = '517'"       # Security log cleared.
# $query = "SELECT * FROM Win32_NTLogEvent WHERE logfile = 'Security' AND Type = 'audit failure'"  # Security log failed events.
# $query = "SELECT * FROM Win32_NTLogEvent WHERE logfile = 'System' AND Type = 'Error'"            # System log errors.
# $query = "SELECT * FROM Win32_NTLogEvent WHERE logfile = 'System' AND EventCode = '6008'"        # System log unexpected shutdowns.

Get-CimInstance -Query $query -ComputerName $computer |
Select-Object RecordNumber,TimeGenerated,ComputerName,LogFile,User,SourceName,EventCode,Type,Message

