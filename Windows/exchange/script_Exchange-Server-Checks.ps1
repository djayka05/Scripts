<# 

Executive Summary:

This script ensures that Exchange Server is functioning optimally by managing certificate renewal, conducting health checks, and keeping the Exchange Health Checker script up to date for future monitoring.

Detailed Breakdown:

Exchange Server Check:
Utilizes Get-Command to determine if Exchange Server is installed on the current system.
Retrieves and displays the Exchange Server version if it is installed.

Certificate Renewal:
Retrieves the current authentication certificate's thumbprint using Get-AuthConfig.
Calculates the number of days until the certificate expires.
If the certificate is expired or will expire within 60 days.
Creates a new certificate with specified parameters using New-ExchangeCertificate.
Sets the new certificate thumbprint and effective date using Set-AuthConfig.
Publishes and clears the previous certificate using Set-AuthConfig.
Restarts necessary web application pools to apply changes.

Server Health Checks:
Retrieves the state of server components using Get-ServerComponentState and formats the output in a table.
Performs a service health check using Test-ServiceHealth.
Gets the status of Exchange-related services using Get-Service, filters the services related to Exchange, and formats the output in a table.

Exchange Health Checker Script Management:
Defines the URL of the Exchange HealthChecker.ps1 script on GitHub.
Defines the path to save the script on the user's desktop.
Checks if the script already exists on the desktop:
Updates the existing script if found.
Downloads the script from GitHub if not found.
Displays appropriate messages based on the success or failure of the download/update operation.
Executes the downloaded script.

#>

# BEGIN SCRIPT

# Check if Exchange Server is installed
if (Get-Command Get-ExchangeServer -ErrorAction SilentlyContinue) {
    # Exchange Server is installed, get the version
    $exchangeVersion = (Get-ExchangeServer).AdminDisplayVersion
    Write-Host "Exchange Server is installed. Version: $exchangeVersion" -ForegroundColor Green

    # Continue with the rest of the script
    $currentThumbprint = (Get-AuthConfig).CurrentCertificateThumbprint
    $authCert = Get-ExchangeCertificate -Thumbprint $currentThumbprint
    $expirationDate = $authCert.NotAfter
    $daysUntilExpiration = ($expirationDate - (Get-Date)).Days

    if ($expirationDate -lt (Get-Date) -or $daysUntilExpiration -lt 60) {
        $newCert = New-ExchangeCertificate -KeySize 2048 -PrivateKeyExportable $true -SubjectName "cn=Microsoft Exchange Server Auth Certificate" -FriendlyName "Microsoft Exchange Server Auth Certificate" -DomainName @()

        Set-AuthConfig -NewCertificateThumbprint $newCert.Thumbprint -NewCertificateEffectiveDate (Get-Date)
        Set-AuthConfig -PublishCertificate
        Set-AuthConfig -ClearPreviousCertificate

        Restart-WebAppPool MSExchangeOWAAppPool
        Restart-WebAppPool MSExchangeECPAppPool

        Write-Host "Certificate renewed successfully."
    } else {
        Write-Host "Authentication certificate is valid and does not need renewal."
    }

    Get-ServerComponentState | Format-Table Component, State -AutoSize
    Test-ServiceHealth
    Get-Service | Where-Object {$_.DisplayName -Like "*Exchange*"} | Format-Table DisplayName, Name, Status

    # Define the URL of the Exchange HealthChecker.ps1 script on GitHub
    $scriptUrl = "https://raw.githubusercontent.com/Microsoft/Exchange-Application-Healthcheck/master/Scripts/Exchange%20HealthChecker.ps1"

    # Define the path where you want to save the script
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $scriptFilePath = Join-Path -Path $desktopPath -ChildPath "Exchange HealthChecker.ps1"

    # Check if the script already exists on the desktop
    if (Test-Path $scriptFilePath) {
        # Update the existing script
        Write-Host "Updating existing Exchange HealthChecker.ps1 script..."
        Invoke-WebRequest -Uri $scriptUrl -OutFile $scriptFilePath
    } else {
        # Download the script from GitHub and save it to the desktop
        Write-Host "Downloading Exchange HealthChecker.ps1 script..."
        Invoke-WebRequest -Uri $scriptUrl -OutFile $scriptFilePath
    }

    # Check if the script was successfully downloaded or updated
    if (Test-Path $scriptFilePath) {
        Write-Host "Exchange HealthChecker.ps1 downloaded/updated and saved to desktop." -ForegroundColor Green
    } else {
        Write-Host "Failed to download/update Exchange HealthChecker.ps1." -ForegroundColor Red
        exit
    }

    # Execute the downloaded script
    & $scriptFilePath
} else {
    Write-Host "Exchange Server is not installed. Exiting script." -ForegroundColor Red
}
