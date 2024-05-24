##############################################################################
#.SYNOPSIS
#   Convert DMTF to DateTime object and vice versa.
#.DESCRIPTION
#   WMI encodes date and time information in a special way that is
#   somewhat difficult to read and manipulate.  These functions will
#   convert to/from WMI's DMTF format and System.DateTime objects.
#.NOTES
#   Version: 1.0
#   Author: Jason Fossen, Enclave Consulting LLC
#   Legal: 0BSD
##############################################################################


function Convert-DMTFtoDateTime ( [String] $dmtf ) { 
    [System.Management.ManagementDateTimeConverter]::ToDateTime($dmtf) 
}


function Convert-DateTimeToDMTF ( [System.DateTime] $datetime = $(get-date) ) { 
    [System.Management.ManagementDateTimeConverter]::ToDmtfDateTime($datetime) 
}


# Examples:

Convert-DMTFtoDateTime '20210427164745.000000-300'
Convert-DMTFtoDateTime '20211102102233.000000-360'

Convert-DateTimeToDMTF 'February 19, 2021 3:02 PM'
Convert-DateTimeToDMTF $(get-date)   # Now.


