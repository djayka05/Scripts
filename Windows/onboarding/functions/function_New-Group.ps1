# Check if the Active Directory module is installed
try {
    $null = Import-Module ActiveDirectory -ErrorAction Stop
}
catch {
    Write-Host "The Active Directory module is not installed. This script requires the Active Directory module to run." -ForegroundColor Red
    exit
}

# Function to create a new AD security group
function CreateADGroup {
    param (
        [string]$GroupName,
        [string]$OU
    )

    try {
        # Check if the group already exists
        $existingGroup = Get-ADGroup -Filter {Name -eq $GroupName} -ErrorAction Stop
        if ($existingGroup) {
            Write-Host "Group '$GroupName' already exists." -ForegroundColor Red
            return
        }

        # Create the new group
        New-ADGroup -Name $GroupName -GroupCategory Security -GroupScope Global -Path $OU -ErrorAction Stop
        Write-Host "Group '$GroupName' created successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "Error creating the group '$GroupName': $_" -ForegroundColor Red
    }
}

# Get a list of available OUs
try {
    $OUs = Get-ADOrganizationalUnit -Filter * -ErrorAction Stop | Select-Object -Property Name, DistinguishedName
}
catch {
    Write-Host "Error retrieving Organizational Units: $_" -ForegroundColor Red
    exit
}

# Display the list of available OUs to the user
Write-Host "Available Organizational Units (OUs):"
$index = 1
foreach ($OU in $OUs) {
    Write-Host "$index. $($OU.Name)"
    $index++
}

# Prompt the user to select an OU
do {
    $selectedOUIndex = Read-Host "Enter the index of the OU where you want to place the group"
    $isValidSelection = $selectedOUIndex -ge 1 -and $selectedOUIndex -le $OUs.Count
    if (-not $isValidSelection) {
        Write-Host "Invalid selection. Please enter a valid index." -ForegroundColor Red
    }
} until ($isValidSelection)

# Retrieve the selected OU
$selectedOU = $OUs[$selectedOUIndex - 1].DistinguishedName

# Prompt the user for the group name
$groupName = Read-Host "Enter the name for the new AD security group"

# Create the AD security group
CreateADGroup -GroupName $groupName -OU $selectedOU
