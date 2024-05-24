<# 

This script retrieves information about the operating system version and product type of the local machine. It first checks the PowerShell version and then uses either Get-CimInstance or Get-WmiObject to retrieve the operating system information, depending on the version. It extracts the major and minor version components of the operating system, maps them to human-readable Windows version names, and determines the product type (workstation or server). Finally, it reports the operating system version and product type. If any error occurs during execution, it displays an error message.

#>

# BEGIN SCRIPT

$null = try {
    # Check the PowerShell version
    $psVersion = $PSVersionTable.PSVersion.Major

    if ($psVersion -ge 5) {
        # PowerShell version is 5 or higher, use Get-CimInstance
        $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    } else {
        # PowerShell version is lower than 5, use Get-WmiObject
        $osInfo = Get-WmiObject -Class Win32_OperatingSystem -ErrorAction Stop
    }

    # Extract major and minor version components
    $majorVersion = [int]$osInfo.Version.Split('.')[0]
    $minorVersion = [int]$osInfo.Version.Split('.')[1]

    # Map OS version to human-readable format
    $osName = switch -Regex ($majorVersion) {
        "10" { "Windows 10" }
        "6" {
            switch ($minorVersion) {
                "3" { "Windows 8.1" }
                "2" { "Windows 8" }
                "1" { "Windows 7" }
                "0" { "Windows Vista" }
                Default { "Unknown" }
            }
        }
        "5" {
            switch ($minorVersion) {
                "2" { "Windows Server 2003" }
                "1" { "Windows XP" }
                Default { "Unknown" }
            }
        }
        Default { "Unknown" }
    }

    # Determine product type
    $productType = switch ($osInfo.ProductType) {
        "1" { "Workstation" }
        "2" { "Server" }
        Default { "Unknown" }
    }

    # Report the OS version and product type
    Write-Host "Operating System Version: $osName"
    Write-Host "Product Type: $productType"
} catch {
    Write-Host "An error occurred: $_"
}
