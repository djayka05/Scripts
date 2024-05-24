<# 

This script gathers critical update information from enabled and reachable machines in the Active Directory domain and stores it in a CSV file for further analysis or action. 

#>

function Get-CriticalUpdates {
    param(
        [string]$OutputPath = "C:\Temp\CriticalUpdates.csv"
    )

    # Check if the output directory exists, if not, create it
    $outputDirectory = Split-Path -Path $OutputPath
    if (-not (Test-Path -Path $outputDirectory)) {
        New-Item -Path $outputDirectory -ItemType Directory -Force | Out-Null
    }

    # Get list of enabled machines from Active Directory
    $enabledMachines = Get-ADComputer -Filter {Enabled -eq $true} | Select-Object -ExpandProperty Name

    $pingableMachines = @()

    # Check pingability of machines
    foreach ($machine in $enabledMachines) {
        if (Test-Connection -ComputerName $machine -Count 1 -Quiet) {
            $pingableMachines += $machine
        }
    }

    $updates = @()

    # Query critical updates for pingable machines
    foreach ($pingableMachine in $pingableMachines) {
        $session = New-Object -ComObject Microsoft.Update.Session
        $searcher = $session.CreateupdateSearcher()
        $updates += $searcher.Search("IsHidden=0 and IsInstalled=1 and IsAssigned=1 and IsPresent=1 and Type='Software'").Updates |
            Where-Object { $_.MsrcSeverity -eq 'Critical' } |
            Select-Object Title, MsrcSeverity, Deadline, RebootRequired, IsInstalled, IsMandatory, LastDeploymentChangeTime, UninstallationNotes, SupportURL |
            Select-Object *,@{Name="ComputerName";Expression={$pingableMachine}}
    }

    # Export results to CSV
    $updates | Export-Csv -Path $OutputPath -NoTypeInformation
}
