function Start-VMs {
    param (
        [string]$vmrunPath = "C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe"
    )

    # Default path to virtual machines directory
    $defaultPath = "D:\Virtual Machines\VMs\"

    # Define folders and their corresponding numerical values
    $folders = @{
        1 = "Lab01"
        2 = "Sandbox"
    }

    # Display menu for choosing a folder
    Write-Host "Select a folder:"
    foreach ($folder in $folders.Keys | Sort-Object) {
        Write-Host "$folder. $($folders[$folder])"
    }

    # Prompt user to choose a folder
    $selectedFolderNumber = Read-Host "Enter the numerical value corresponding to the folder"

    # If no folder number is provided, start all VMs under all folders
    if (-not $selectedFolderNumber) {
        $selectedFolderNumber = "All"
    }

    # If the selected folder number is "All", start VMs from all folders
    if ($selectedFolderNumber -eq "All") {
        foreach ($folderValue in $folders.Values) {
            Start-VMsInFolder -Folder $folderValue -DefaultPath $defaultPath
        }
        return
    }

    # If the selected folder number is valid, start VMs from that folder
    if ($folders.ContainsKey([int]$selectedFolderNumber)) {
        $selectedFolder = $folders[[int]$selectedFolderNumber]
        Start-VMsInFolder -Folder $selectedFolder -DefaultPath $defaultPath
    } 
    else {
        Write-Host "Invalid folder number. Exiting script." -ForegroundColor Red
        return
    }
}

function Start-VMsInFolder {
    param (
        [string]$Folder,
        [string]$DefaultPath
    )

    # Define subfolders and their corresponding indexes
    $subfolders = @{
        "Lab01" = @{
            "01 Firewalls" = 1
            "02 Domain Controllers" = 2
            "03 Servers" = 3
            "04 Workstations" = 4
        }
        "Sandbox" = @{
            "01 Firewalls" = 1
            "02 Workstations" = 2
        }
    }

    # Start VMs in specific order with delays
    foreach ($subfolder in $subfolders[$Folder].Keys | Sort-Object) {
        $folderIndex = $subfolders[$Folder][$subfolder]
        $folderPath = Join-Path -Path $DefaultPath -ChildPath "$Folder\$subfolder"
        
        # Check if the folder exists
        if (-not (Test-Path $folderPath)) {
            Write-Host "Folder '$folderPath' not found. Skipping to the next subfolder." -ForegroundColor 
            continue
        }

        # Get a list of all VMs within the chosen subfolder
        $vmxFiles = Get-ChildItem -Path $folderPath -Filter "*.vmx" -Recurse

        # Start VMs in this subfolder
        foreach ($vmxFile in $vmxFiles) {
            # Start the virtual machine in headless mode without opening the GUI
            & $vmrunPath -T ws start "$($vmxFile.FullName)" nogui
            Write-Host "Starting $($vmxFile.Name)" -ForegroundColor Green
        }

        # Add delay based on the folder index
        switch ($folderIndex) {
            1 {
                Start-Sleep -Seconds 15
            }
            2 {
                Start-Sleep -Seconds 90
            }
            Default {
                # No delay for other folders
            }
        }
    }
}

Start-VMs
