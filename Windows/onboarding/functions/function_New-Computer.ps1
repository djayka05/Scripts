function New-Computer {

    # Record the start time
    $startTime = Get-Date

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $domainStatus = (Get-CimInstance -ClassName Win32_ComputerSystem).PartOfDomain
    $domain = (Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object {$_.IPEnabled}).DNSDomainSuffixSearchOrder[0]
    $machineType = Read-Host -Prompt "Is this computer going to be a user machine or an administrator machine? Enter 'user' or 'admin'"

    if ($null -eq $domain) {
        Write-Host "Unable to determine the domain name. Please enter it manually."
        $domain = Read-Host -Prompt "Enter the domain name"
    }

    $username = Read-Host -Prompt "Enter the username"
    $username = "$domain\$username"
    $password = Read-Host -Prompt "Enter the password" -AsSecureString
    $credential = New-Object System.Management.Automation.PSCredential($username, $password)
    $scriptFolder = $PSScriptRoot
    $getADOUFunction = Get-ChildItem -Path $scriptFolder -Recurse -Filter function_Get-ADOrganizationalUnits.ps1 | Select-Object -First 1

    # Call Get-ADOrganizationalUnits Function

    if ($null -eq $getADOUFunction) {
        throw "function_Get-ADOrganizationalUnits.ps1 not found under $scriptFolder."
    }
    . $getADOUFunction.FullName

    # Call SelectOU Function

    $selectOUFunction = Get-ChildItem -Path $scriptFolder -Recurse -Filter function_Select-OU.ps1 | Select-Object -First 1
    if ($null -eq $selectOUFunction) {
        throw "function_Select-OU.ps1 not found under $scriptFolder."
    }
    . $selectOUFunction.FullName

    $ous = Get-ADOrganizationalUnits -Domain $domain -Credential $credential
    if ($ous.Count -eq 0) {
        throw "No Organizational Units found."
    }
    $ouPath = Select-OU -OrganizationalUnits $ous

    # Select computer name for later, ie join computer to domain step

    if ($domainStatus) {
        Write-Host "The computer is already joined to the domain." -ForegroundColor Yellow
    } else {
        do {
            $computerName = Read-Host -Prompt "Enter new computer name (press Enter to use the current $env:COMPUTERNAME)"
            if ([string]::IsNullOrWhiteSpace($computerName)) {
                $computerName = $env:COMPUTERNAME
            } elseif (Test-Connection -ComputerName $computerName -Count 1 -Quiet) {
                Write-Host "The computer name '$computerName' already exists. Please choose a different name." -ForegroundColor Red
            }
        } while ([string]::IsNullOrWhiteSpace($computerName) -or (Test-Connection -ComputerName $computerName -Count 1 -Quiet))
    }

    # Disable Internet Explorer

    $check = Get-WindowsOptionalFeature -Online | Where-Object {$_.FeatureName -eq "Internet-Explorer-Optional-amd64"}
    If ($check.State -ne "Disabled") {
        Disable-WindowsOptionalFeature -FeatureName Internet-Explorer-Optional-amd64 -Online -NoRestart | Out-Null
    }

    # Call Install NuGet Function

    $selectNuGetFunction = Get-ChildItem -Path $scriptFolder -Recurse -Filter function_Install-NuGet.ps1 | Select-Object -First 1
    if ($null -eq $selectNuGetFunction) {
        throw "function_Install-NuGet.ps1 not found under $scriptFolder."
    }
    . $selectNuGetFunction.FullName

    # Call Install Windows Updates Function

    $getInstallUpdatesFunction = Get-ChildItem -Path $scriptFolder -Recurse -Filter function_Install-Updates.ps1 | Select-Object -First 1
    if ($null -eq $getInstallUpdatesFunction) {
        throw "function_Install-Updates.ps1 not found under $scriptFolder."
    }
    . $getInstallUpdatesFunction.FullName

    # Call New Jumpbox Function

    try {
        if ($machineType -eq "admin") {
            $getNewJumpboxScript = Get-ChildItem -Path $scriptFolder -Recurse -Filter script_New-Jumpbox.ps1 | Select-Object -First 1
            if ($null -eq $getNewJumpboxScript) {
                throw "script_New-Jumpbox.ps1 not found under $scriptFolder."
            }
            . $getNewJumpboxScript.FullName
        }

        # Join computer to the domain

        if (-not $domainStatus) {
            try {
                Add-Computer -DomainName $domain -Credential $credential -OUPath $ouPath -NewName $computerName -ErrorAction Stop
                Write-Host "Computer joined to domain successfully." -ForegroundColor Green
                Restart-Computer -Force -Confirm:$true
            } catch {
                throw "Failed to join computer to domain. Error: $_"
            }
        } else {
            Write-Host "The computer is already part of the domain." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
    }
    
    # Record the end time
    $endTime = Get-Date

    # Calculate the duration
    $duration = New-TimeSpan -Start $startTime -End $endTime

    # Write the total runtime to a text file
    $logFilePath = "C:\Logs\New-Computer.log"  # Modify this path as needed
    "Total runtime: $($duration.Hours) hours, $($duration.Minutes) minutes, $($duration.Seconds) seconds" | Out-File -FilePath $logFilePath
}
