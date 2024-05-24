# Check if Active Directory module is available, if not install it
try {
    if (-not (Get-Module -Name ActiveDirectory -ListAvailable)) {
        Write-Host "Active Directory module not found. Installing RSAT tools..." -ForegroundColor Green
        Add-WindowsFeature RSAT-AD-PowerShell
        Import-Module ActiveDirectory -ErrorAction Stop
    }
} catch {
    Write-Host "Error occurred while installing or importing Active Directory module: $_" -ForegroundColor Red
    exit
}
function New-User {
    try {
        # Retrieve domain name
        $domain = ([System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()).Name

        # Prompt for account type
        $accountType = Read-Host -Prompt "Is this account for a user or a service? (Enter 'user' or 'service')"

        if ($accountType -eq "service") {
            # Prompt for service account details
            $serviceUserName = Read-Host -Prompt "Enter the username for the service account"
            $serviceUserName = "svc_$serviceUserName"

            # Check if Service Accounts group exists, if not create it
            try {
                $serviceAccountsGroup = Get-ADGroup -Filter {Name -eq "Service Accounts"} -ErrorAction Stop
            } catch {
                Write-Host "Error occurred while retrieving Service Accounts group: $_" -ForegroundColor Red
                exit
            }
            
            if (-not $serviceAccountsGroup) {
                try {
                    New-ADGroup -Name "Service Accounts" -GroupCategory Security -GroupScope Global -Path "OU=Groups,OU=YourOU,DC=$domain" -ErrorAction Stop
                    Write-Host "Service Accounts group created successfully." -ForegroundColor Green
                } catch {
                    Write-Host "Error occurred while creating Service Accounts group: $_" -ForegroundColor Red
                    exit
                }
            }

            # Add service account to Service Accounts group
            try {
                Add-ADGroupMember -Identity "Service Accounts" -Members $serviceUserName -ErrorAction Stop
            } catch {
                Write-Host "Error occurred while adding service account to Service Accounts group: $_" -ForegroundColor Red
                exit
            }

            # Prompt for admin to set password
            $newUserPassword = Read-Host -Prompt "Enter the password for the service account" -AsSecureString
        }
        elseif ($accountType -eq "user") {
            # Generate a random portion of the password
            $randomPassword = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 8 | ForEach-Object {[char]$_})

            # Combine the random portion with the word "Password" with a capitalized "P"
            $newUserPassword = "Password$randomPassword"

            # Prompt for new user details
            $firstName = Read-Host -Prompt "Enter the first name for the new user"
            $lastName = Read-Host -Prompt "Enter the last name for the new user"
            $initial = $firstName.Substring(0,1)
            $newUserName = "$initial$lastName"

            # Check if username already exists
            $suffix = ""
            $counter = 1
            while (Get-ADUser -Filter {SamAccountName -eq $newUserName$suffix}) {
                $suffix = $counter++
            }
            if ($suffix -ne "") {
                $newUserName += $suffix
            }

            $newUserPath = Read-Host -Prompt "Enter the OU path for the new user (e.g., OU=Users,OU=YourOU,DC=$domain)"
            $newUserDescription = Read-Host -Prompt "Enter the description for the new user"
            $newUserOffice = Read-Host -Prompt "Enter the office for the new user"
            $newUserTitle = Read-Host -Prompt "Enter the title for the new user"
            $newUserDepartment = Read-Host -Prompt "Enter the department for the new user"

            # Choose template user
            $templateUsers = @("TemplateUser1", "TemplateUser2", "TemplateUser3")  # Add as many template users as needed
            Write-Host "Choose a template user:"
            for ($i = 0; $i -lt $templateUsers.Count; $i++) {
                Write-Host "$($i + 1). $($templateUsers[$i])"
            }
            $templateUserChoice = Read-Host -Prompt "Enter the number corresponding to the template user"

            # Get selected template user properties
            try {
                $templateUser = Get-ADUser -Identity $templateUsers[$templateUserChoice - 1] -ErrorAction Stop
            } catch {
                Write-Host "Error occurred while retrieving template user: $_" -ForegroundColor Red
                exit
            }

            # Create new user
            try {
                New-ADUser -SamAccountName $newUserName -UserPrincipalName "$newUserName@$domain" -Name "$firstName $lastName" -GivenName $firstName -Surname $lastName -AccountPassword $newUserPassword -Path $newUserPath -Description $newUserDescription -Office $newUserOffice -Title $newUserTitle -Department $newUserDepartment -ErrorAction Stop
            } catch {
                Write-Host "Error occurred while creating new user: $_" -ForegroundColor Red
                exit
            }

            # Copy template user attributes to new user
            try {
                Get-ADUser $newUserName | Set-ADUser -Description $templateUser.Description -Office $templateUser.Office -Title $templateUser.Title -Department $templateUser.Department -ErrorAction Stop
            } catch {
                Write-Host "Error occurred while copying attributes to new user: $_" -ForegroundColor Red
                exit
            }
        }
        else {
            Write-Host "Invalid account type. Please enter 'user' or 'service'." -ForegroundColor Red
        }
    } catch {
        Write-Host "An unexpected error occurred: $_" -ForegroundColor Red
    }
}
