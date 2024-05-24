function Start-VMs {
    param (
        [string]$vmrunPath = "C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe"
    )

    try {
        # Default path to virtual machines directory
        $defaultPath = "D:\Virtual Machines\VMs\"

        # Get a list of all VMs under Lab01 and Sandbox folders
        $lab01Path = Join-Path -Path $defaultPath -ChildPath "Lab01"
        $sandboxPath = Join-Path -Path $defaultPath -ChildPath "Sandbox"

        # Get a list of all pfsense VMs under Lab01
        $lab01PfsenseVMs = Get-ChildItem -Path $lab01Path -Filter "*-FW*.vmx" -Recurse

        # Get a list of all pfsense VMs under Sandbox
        $sandboxPfsenseVMs = Get-ChildItem -Path $sandboxPath -Filter "*-FW*.vmx" -Recurse

        # Combine pfsense VMs from Lab01 and Sandbox
        $pfsenseVMs = New-Object System.Collections.ArrayList

        $pfsenseVMs.Add($lab01PfsenseVMs)
        $pfsenseVMs.Add($sandboxPfsenseVMs)

        # Start pfsense VMs
        foreach ($vmxFile in $pfsenseVMs) {
            # Start the virtual machine in headless mode without opening the GUI
            & $vmrunPath -T ws start "$($vmxFile.FullName)" nogui
            Write-Host "Starting $($vmxFile.Name)"
        }
    } catch {
        Write-Host "Error occurred: $_"
    }
}

# Start-Sleep -Seconds 60  # Delay for 60 seconds after computer bootup
Start-VMs
