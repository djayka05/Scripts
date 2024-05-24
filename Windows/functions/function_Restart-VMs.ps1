function Restart-VMs {
    param (
        [string]$lab01Path,
        [string]$sandboxPath
    )

    # Function to restart VMs in a folder
    function Restart-VMsInFolder {
        param (
            [string]$Folder,
            [string]$DefaultPath
        )

        # Write-Host "`nRestarting $Folder`n" -ForegroundColor Green

        # Get VMX files in the folder
        $vmxFiles = Get-ChildItem -Path $DefaultPath -Filter "*.vmx" -Recurse

        # Restart VMs with "-FW" in the name first (in parallel)
        $fwJobs = @()
        $vmxFiles | Where-Object { $_.Name -match "-FW" } | ForEach-Object {
            $vmName = [System.IO.Path]::GetFileNameWithoutExtension($_.FullName)
            $job = Start-Job -Name "$($vmName)" -ScriptBlock {
                param($vmxPath, $vmName)
                & "C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe" stop "$vmxPath" soft
                Write-Host "Stopping $($vmName)" -ForegroundColor Yellow
                Start-Sleep -Seconds 2 # Pause for 2 seconds before starting the VM
                & "C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe" start "$vmxPath" nogui
                Write-Host "Starting $($vmName)" -ForegroundColor Green
            } -ArgumentList $_.FullName, $vmName
            $fwJobs += $job
        }

        # Wait for all "-FW" VMs to restart before continuing
        $fwJobs | Wait-Job

        # Wait for 30 seconds before restarting the remaining VMs
        Start-Sleep -Seconds 30

        # Restart the remaining VMs (in parallel)
        $otherJobs = @()
        $vmxFiles | Where-Object { $_.Name -notmatch "-FW" } | ForEach-Object {
            $vmName = [System.IO.Path]::GetFileNameWithoutExtension($_.FullName)
            $job = Start-Job -Name "$($vmName)" -ScriptBlock {
                param($vmxPath, $vmName)
                & "C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe" stop "$vmxPath" soft
                Write-Host "Stopping $($vmName)" -ForegroundColor Yellow
                Start-Sleep -Seconds 2 # Pause for 2 seconds before starting the VM
                & "C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe" start "$vmxPath" nogui
                Write-Host "Starting $($vmName)" -ForegroundColor Green
            } -ArgumentList $_.FullName, $vmName
            $otherJobs += $job
        }

        # Wait for all jobs to complete
        $otherJobs | Wait-Job
    }

    # Main script logic
    # Prompt user to select Lab01 or Sandbox folder
    Write-Host "`nHitting enter key defaults to restart all VMs.`n" -ForegroundColor Cyan
    $folderChoice = Read-Host "Select a folder:`n1. Lab01`n2. Sandbox `n `nOption"

    switch ($folderChoice) {
        1 {
            # Restart VMs from Lab01 folder
            Restart-VMsInFolder -Folder "Lab01" -DefaultPath $lab01Path
        }
        2 {
            # Restart VMs from Sandbox folder
            Restart-VMsInFolder -Folder "Sandbox" -DefaultPath $sandboxPath
        }
        default {
            # If no option selected, reboot all VMs
            Write-Host "`nDefaulting to restart all VMs...`n" -ForegroundColor Cyan
            Restart-VMsInFolder -Folder "All VMs" -DefaultPath $lab01Path
            Restart-VMsInFolder -Folder "All VMs" -DefaultPath $sandboxPath
        }
    }
}

# Paths to VM folders
$lab01Path = "D:\Virtual Machines\VMS\Lab01"
$sandboxPath = "D:\Virtual Machines\VMS\Sandbox"

# Restart VMs
Restart-VMs -lab01Path $lab01Path -sandboxPath $sandboxPath
