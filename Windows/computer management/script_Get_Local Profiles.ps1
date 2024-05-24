<#


#>

# BEGIN SCRIPT

Get-WmiObject win32_userprofile | Select-Object @{LABEL=”last used”;EXPRESSION={$_.ConvertToDateTime($_.lastusetime)}}, LocalPath, SID | Format-Table -a