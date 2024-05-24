<# 

This script retrieves IP information from an API endpoint, displays it to the user, and writes each piece of information (such as IP address, hostname, etc.) to its corresponding registry value under a custom registry key. It handles failures in retrieving information and executes without requiring user input.



function Get-IspInfo {
    # Define API URL
    $apiUrl = "https://ipinfo.io/json"

    try {
        # Invoke REST Method to get IP information
        $response = Invoke-RestMethod -Uri $apiUrl

        # Output the information
        $response | Select-Object ip, hostname, city, region, country, loc, org, postal, timezone

        # Write each value to the registry
        $registryPath = "HKLM:\Software\Scripts\IPInfo"
        if (-not (Test-Path $registryPath)) {
            New-Item -Path $registryPath -Force | Out-Null
        }
        
        Set-ItemProperty -Path $registryPath -Name "IPAddress" -Value $response.ip
        Set-ItemProperty -Path $registryPath -Name "Hostname" -Value $response.hostname
        Set-ItemProperty -Path $registryPath -Name "City" -Value $response.city
        Set-ItemProperty -Path $registryPath -Name "Region" -Value $response.region
        Set-ItemProperty -Path $registryPath -Name "Country" -Value $response.country
        Set-ItemProperty -Path $registryPath -Name "Location" -Value $response.loc
        Set-ItemProperty -Path $registryPath -Name "Organization" -Value $response.org
        Set-ItemProperty -Path $registryPath -Name "PostalCode" -Value $response.postal
        Set-ItemProperty -Path $registryPath -Name "Timezone" -Value $response.timezone
        
        Write-Host "IP information saved to registry."
    } catch {
        Write-Host "Failed to retrieve IP information. Check your internet connection."
        return
    }
}

#>

<# 

This script retrieves IP information from an API endpoint, displays it to the user, and writes each piece of information (such as IP address, hostname, etc.) to its corresponding registry value under a custom registry key. It handles failures in retrieving information and executes without requiring user input.

#>

function Get-IspInfo {
    param (
        [string]$Target = "local"
    )

    if ($Target -eq "local") {
        Get-IspInfoLocal
    }
    elseif ($Target -eq "remote") {
        Get-IspInfoRemote
    }
    elseif ($Target -eq "file") {
        Get-IspInfoFromFile
    }
    elseif ($Target -eq "ad") {
        Get-IspInfoFromAD
    }
    else {
        Write-Host "Invalid choice. Please choose 'local', 'remote', 'file', or 'ad'."
    }
}

function Get-IspInfoLocal {
    # Define API URL
    $apiUrl = "https://ipinfo.io/json"

    try {
        # Invoke REST Method to get IP information
        $response = Invoke-RestMethod -Uri $apiUrl

        # Output the information
        $response | Select-Object ip, hostname, city, region, country, loc, org, postal, timezone

        # Write each value to the registry
        $registryPath = "HKLM:\Software\Scripts\IPInfo"
        if (-not (Test-Path $registryPath)) {
            New-Item -Path $registryPath -Force | Out-Null
        }
        
        Set-ItemProperty -Path $registryPath -Name "IPAddress" -Value $response.ip
        Set-ItemProperty -Path $registryPath -Name "Hostname" -Value $response.hostname
        Set-ItemProperty -Path $registryPath -Name "City" -Value $response.city
        Set-ItemProperty -Path $registryPath -Name "Region" -Value $response.region
        Set-ItemProperty -Path $registryPath -Name "Country" -Value $response.country
        Set-ItemProperty -Path $registryPath -Name "Location" -Value $response.loc
        Set-ItemProperty -Path $registryPath -Name "Organization" -Value $response.org
        Set-ItemProperty -Path $registryPath -Name "PostalCode" -Value $response.postal
        Set-ItemProperty -Path $registryPath -Name "Timezone" -Value $response.timezone
        
        Write-Host "IP information saved to registry."
    } catch {
        Write-Host "Failed to retrieve IP information. Check your internet connection."
        return
    }
}

function Get-IspInfoRemote {
    $targetMachine = Read-Host "Enter the remote machine's hostname or IP address:"
    $pingResult = Test-Connection -ComputerName $targetMachine -Count 1 -Quiet

    if ($pingResult) {
        Invoke-Command -ComputerName $targetMachine -ScriptBlock {
            param (
                [string]$apiUrl
            )
            $response = Invoke-RestMethod -Uri $apiUrl
            $response | Select-Object ip, hostname, city, region, country, loc, org, postal, timezone
        } -ArgumentList $apiUrl
    } else {
        Write-Host "Failed to ping $targetMachine. Please make sure the machine is reachable."
    }
}

function Get-IspInfoFromFile {
    $filePath = Read-Host "Enter the path to the file containing a list of machine names or IP addresses:"
    $machines = Get-Content $filePath
    foreach ($machine in $machines) {
        $pingResult = Test-Connection -ComputerName $machine -Count 1 -Quiet
        if ($pingResult) {
            Invoke-Command -ComputerName $machine -ScriptBlock {
                param (
                    [string]$apiUrl
                )
                $response = Invoke-RestMethod -Uri $apiUrl
                $response | Select-Object ip, hostname, city, region, country, loc, org, postal, timezone
            } -ArgumentList $apiUrl
        } else {
            Write-Host "Failed to ping $machine. Skipping..."
        }
    }
}

function Get-IspInfoFromAD {
    # Not implemented in this example
    Write-Host "Functionality to retrieve information from Active Directory is not implemented in this example."
}

# Let the user choose the target
$choice = Read-Host "Choose target: local, remote, file, ad"
Get-IspInfo -Target $choice
