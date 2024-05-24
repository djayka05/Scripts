# Function to log messages to a file
function Write-Log {
    param(
        [string]$Message,
        [string]$LogFile = "C:\Users\$env:USERNAME\desktop\script_log.txt"
    )
    Add-Content -Path $LogFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
}

function GetUserByUsername {
    param(
        [string]$Username
    )

    try {
        $adUser = Get-ADUser -Identity $Username -Properties Name, mail, PasswordNeverExpires, LastLogonDate -ErrorAction Stop
        if (-not $adUser) {
            Write-Host "User '$Username' not found or not enabled."
            Write-Log -Message "User '$Username' not found or not enabled."
            return $null
        }
        return $adUser
    } catch {
        Write-Host "Error occurred while retrieving user information: $($_.Exception.Message)"
        Write-Log -Message "Error occurred while retrieving user information for '$Username': $($_.Exception.Message)"
        return $null
    }
}

function GetEnabledUsers {
    try {
        $adUsers = Get-ADUser -Filter {Enabled -eq $true} -Properties Name, mail, PasswordNeverExpires, LastLogonDate -ErrorAction Stop
        return $adUsers
    } catch {
        Write-Host "Error occurred while retrieving enabled users: $($_.Exception.Message)"
        Write-Log -Message "Error occurred while retrieving enabled users: $($_.Exception.Message)"
        return @()
    }
}

function DisplayUsersOnScreen {
    param(
        [array]$Users
    )

    $Users | Out-GridView
}

function SaveUsersToCSV {
    param(
        [array]$Users
    )

    try {
        $csvFilePath = "C:\Users\$env:USERNAME\desktop\enabled_ad_userlist.csv"
        $Users | Export-Csv -Path $csvFilePath -NoTypeInformation
        Write-Host "CSV file saved to $csvFilePath"
        Write-Log -Message "Saved user information to CSV file: $csvFilePath"
    } catch {
        Write-Host "Error occurred while saving user information to CSV: $($_.Exception.Message)"
        Write-Log -Message "Error occurred while saving user information to CSV: $($_.Exception.Message)"
    }
}

function ProcessUserSelection {
    param(
        [int]$UserSelection
    )

    switch ($UserSelection) {
        1 {
            $specificUsername = Read-Host -Prompt "Enter a specific username"
            $adUser = GetUserByUsername -Username $specificUsername
            if ($adUser) {
                DisplayUsersOnScreen -Users @($adUser)
            }
        }
        2 {
            $adUsers = GetEnabledUsers
            if ($adUsers.Count -gt 0) {
                DisplayUsersOnScreen -Users $adUsers
            }
        }
        Default {
            Write-Host "Invalid option selected."
            Write-Log -Message "Invalid option selected."
        }
    }
}

try {
    # Prompt the user for the choice
    $choice = Read-Host -Prompt "Choose output option:`n1. Output to screen`n2. Save to CSV`n3. Both"

    # Prompt for username or all users
    $userSelection = Read-Host -Prompt "Select option:`n1. Enter a specific username`n2. Run against all enabled users"

    ProcessUserSelection -UserSelection $userSelection

    # Calculate total user count
    $totalUserCount = if ($adUsers) { $adUsers.Count } else { 0 }

    # Select properties
    $selectedUsers = $adUsers | Select-Object -Property Name, mail, samAccountName, PasswordNeverExpires, LastLogonDate, distinguishedName

    # Switch based on user's choice
    switch ($choice) {
        1 {
            DisplayUsersOnScreen -Users $selectedUsers
            Write-Host "Total Enabled Users: $totalUserCount"
            Write-Log -Message "Displayed user information on screen."
        }
        2 {
            SaveUsersToCSV -Users $selectedUsers
            Write-Host "Total Enabled Users: $totalUserCount"
        }
        3 {
            DisplayUsersOnScreen -Users $selectedUsers
            SaveUsersToCSV -Users $selectedUsers
            Write-Host "Total Enabled Users: $totalUserCount"
            Write-Log -Message "Displayed user information on screen and saved to CSV file."
        }
        Default {
            Write-Host "Invalid option selected."
            Write-Log -Message "Invalid option selected."
        }
    }
} catch {
    Write-Host "An error occurred: $($_.Exception.Message)"
    Write-Log -Message "An error occurred: $($_.Exception.Message)"
}
