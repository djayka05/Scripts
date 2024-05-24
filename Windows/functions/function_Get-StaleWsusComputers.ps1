<# 

This script offers a simple and efficient way to find stale computers in a WSUS environment by comparing their last reported status time against a specified threshold, providing valuable information for system administrators to manage and maintain their WSUS infrastructure effectively. 

#>

function Get-StaleWsusComputers {
    param(
        [int]$DaysThreshold = 30
    )

    $computers = Get-WsusComputer -All
    $cutoffDate = (Get-Date).AddDays(-$DaysThreshold)

    $staleComputers = $computers | Where-Object { $_.LastReportedStatusTime -lt $cutoffDate }

    return $staleComputers
}
