# Import the Active Directory module if not already imported
Import-Module ActiveDirectory

# Function to retrieve group membership change events
function Get-GroupMembershipChanges {
    param(
        [datetime]$StartDate = (Get-Date).AddHours(-4)
    )

    # Get domain controllers list
    $DCs = Get-ADDomainController -Filter *

    # Initialize an array to store results
    $results = @()

    # Store group membership changes events from the security event logs in an array.
    foreach ($DC in $DCs){
        $events = Get-EventLog -LogName Security -ComputerName $DC.Hostname -After $StartDate | 
                  Where-Object { $_.EventID -eq 4728 -or $_.EventID -eq 4729 }

        # Loop through each stored event and add details to results array
        foreach ($e in $events){
            if ($e.EventID -eq 4728) {
                $result = "Group: $($e.ReplacementStrings[2])`tAction: Member added`tWhen: $($e.TimeGenerated)`tWho: $($e.ReplacementStrings[6])`tAccount added: $($e.ReplacementStrings[0])"
                $results += $result
            }
            elseif ($e.EventID -eq 4729) {
                $result = "Group: $($e.ReplacementStrings[2])`tAction: Member removed`tWhen: $($e.TimeGenerated)`tWho: $($e.ReplacementStrings[6])`tAccount removed: $($e.ReplacementStrings[0])"
                $results += $result
            }
        }
    }

    return $results -join "`r`n"
}
