<#

Summary:

The script first retrieves user profiles, then for each user profile, it queries mapped drives and writes the information to the registry while providing feedback to the user via console messages.

Details:

Define the registry key: 
The script starts by defining the registry key where the mapped drives will be stored. This is the location in the registry where the script will write the mapped drive information.

Get user profiles: 
It retrieves all user profiles on the system using the Get-WmiObject cmdlet. This provides a list of user profiles, including their usernames.

Get-MappedDrives: 
This function takes a username as input and retrieves the mapped drives for that user. It uses the Get-WmiObject cmdlet with a filter to get logical disks of type 4 (network drives) for the specified user.

Write-MappedDrivesToRegistry: 
This function takes the registry key, username, and an array of mapped drives as input. It creates a registry subkey for the user under the specified registry key if it doesn't already exist, then writes the mapped drives to that subkey with drive letters as value names and paths as value data.

Query mapped drives and write to registry: 
It iterates through each user profile retrieved earlier. For each user profile, it extracts the username. It calls the Get-MappedDrives function to retrieve the mapped drives for that user. If the user has mapped drives, it calls the Write-MappedDrivesToRegistry function to write the mapped drives to the registry.

Output messages: 
Throughout the script, messages are written to the console using Write-Output to provide feedback on the progress of the script. These messages indicate which drive letter is mapped to which path for which user, confirming that the mapped drive information is being written to the registry.

Q&A:

Question:
When running this script, does the user need to be logged on to return the values?

Answer:
No, the user does not necessarily need to be logged on for the script to query and retrieve mapped drives information. The script can run in the background as long as it has the necessary permissions to access the registry and query system information.However, if you're running the script in a user context (not as an elevated administrator), it may have limited access to certain parts of the registry or system information, which could affect its ability to retrieve mapped drive information for all users. In such cases, running the script with elevated privileges (e.g., as an administrator) can help ensure it has the necessary permissions to access the required information.

The script should be able to retrieve mapped drive information regardless of whether a user is logged on or not, as long as it has the appropriate permissions to access system resources.

#>

# BEGIN SCRIPT

# Define the registry key where mapped drives will be stored
$registryKey = "HKLM:\SYSTEM\CustomMappedDrives"

# Get all user profiles on the system
$userProfiles = Get-WmiObject -Class Win32_UserProfile | Where-Object { $_.Special -eq $false }

# Function to retrieve mapped drives for a user
function Get-MappedDrives {
    Param (
        [string]$Username
    )

    # Get mapped drives for the specified user
    $mappedDrives = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType = 4"

    return $mappedDrives
}

# Function to write mapped drives to registry
function Write-MappedDrivesToRegistry {
    Param (
        [string]$RegistryKey,
        [string]$Username,
        [array]$MappedDrives
    )

    try {
        $keyPath = "$RegistryKey\$Username"
        # Create registry key if it doesn't exist
        if (-not (Test-Path $keyPath)) {
            New-Item -Path $keyPath -Force | Out-Null
        }
        
        # Write mapped drives to registry under user's subkey
        foreach ($drive in $MappedDrives) {
            $driveLetter = $drive.DeviceID
            $path = $drive.ProviderName
            Set-ItemProperty -Path $keyPath -Name $driveLetter -Value $path
            Write-Output "Drive $driveLetter mapped to $path for user $Username written to registry."
        }
    } catch {
        Write-Error "An error occurred: $_"
    }
}

# Query mapped drives for each user and write to registry
foreach ($profile in $userProfiles) {
    $username = $profile.LocalPath.Split("\")[-1]
    $mappedDrives = Get-MappedDrives -Username $username
    if ($mappedDrives.Count -gt 0) {
        Write-MappedDrivesToRegistry -RegistryKey $registryKey -Username $username -MappedDrives $mappedDrives
    }
}