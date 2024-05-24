# Define a function to uninstall Adobe products
function Uninstall-AdobeProducts {
    param($computer)
    if (Test-Connection -ComputerName $computer -Count 1 -Quiet) {
        $hostname = $computer
        $software = Get-WmiObject -Class Win32_Product -Filter "Name LIKE '*Adobe*'" -ComputerName $computer -ErrorAction SilentlyContinue
        if ($software) {
            foreach ($item in $software) {
                if ($item.Uninstall().ReturnValue -eq 0) {
                    Write-Host "Successfully uninstalled $($item.Name) from $hostname"
                } else {
                    Write-Warning "Failed to uninstall $($item.Name) from $hostname"
                }
            }
        } else {
            Write-Host "No Adobe products found on $hostname"
        }
    } else {
        Write-Warning "Cannot ping $computer"
    }
}

# Get list of computers
$computers = Get-ADComputer -Filter {Enabled -eq $true} | Select-Object -ExpandProperty Name

# Run in parallel with throttle limit of 5
$computers | ForEach-Object -Parallel {
    Uninstall-AdobeProducts $_
} -ThrottleLimit 5
