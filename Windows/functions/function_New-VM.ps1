# Function to clone a VM and import it into VMware Workstation
function New-VM {
    param (
        [string]$vmPath,
        [string]$newVmName,
        [string]$destinationFolder
    )

    # Check if destination folder is empty
    if ([string]::IsNullOrEmpty($destinationFolder)) {
        Write-Host "Destination folder is empty or invalid."
        return
    }

    # Construct the destination path for the cloned VM
    $destinationPath = Join-Path -Path $destinationFolder -ChildPath "$newVmName\$newVmName.vmx"
    
    # Clone the VM with the "full" clone type
    & "vmrun.exe" -T ws clone "$vmPath" "$destinationPath" full

    # Read the content of the .vmx file
    $vmxContent = Get-Content $destinationPath
    
    # Update the displayName property in the .vmx file
    $vmxContent | ForEach-Object {
        if ($_ -match "displayName") {
            $_ -replace 'displayName = ".+"', "displayName = `"$newVmName`""
        } else {
            $_
        }
    } | Set-Content $destinationPath -Encoding UTF8

    # Start the cloned VM
    & "vmrun.exe" -T ws start "$destinationPath"
}

# Function to select a folder to save the cloned VM
function Select-Folder {
    param (
        [string]$rootFolder
    )

    # Get list of folders
    $folders = Get-ChildItem -Path $rootFolder | Where-Object {$_.PSIsContainer}

    # Display folders and prompt user for selection
    Write-Host "Select a folder to save the cloned VM:"
    for ($i = 0; $i -lt $folders.Count; $i++) {
        Write-Host "$($i + 1). $($folders[$i].Name)"
    }

    $choice = Read-Host "Enter the number corresponding to your choice"
    $selectedFolder = $folders[$choice - 1]
    Write-Host "Selected folder: $($selectedFolder.FullName)"  # Debugging output
    return $selectedFolder.FullName
}

# Main script
$rootFolder = "D:\Virtual Machines\VMs"  # Specify the root folder where VMs are stored
$selectedFolder = Select-Folder -rootFolder $rootFolder
if ([string]::IsNullOrEmpty($selectedFolder)) {
    Write-Host "No folder selected. Exiting script."
    Exit
}

$vmDirectory = "D:\Virtual Machines\Templates"
$vmName = "Template-Windows10-21H2"
$newVmName = Read-Host "Enter the name for the cloned VM"

# Combine folder name and VM name
$folderName = Split-Path -Path $selectedFolder -Leaf
$modifiedVmName = "$folderName-$newVmName"

# Create a new folder for the VM
$newVmFolder = Join-Path -Path $selectedFolder -ChildPath "$modifiedVmName"
New-Item -ItemType Directory -Path $newVmFolder -ErrorAction SilentlyContinue

$vmPath = Join-Path -Path $vmDirectory -ChildPath "$vmName\${vmName}.vmx"
New-VM -vmPath $vmPath -newVmName $modifiedVmName -destinationFolder $selectedFolder

Write-Host "VM '$vmName' cloned successfully as '$modifiedVmName' in folder '$selectedFolder'"
