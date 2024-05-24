# Function to gracefully shut down running VMs in the specified folder
function Stop-RunningVMs {
    param (
        [string]$vmxPath
    )

    # Check if VMware Workstation services are running
    $workstationServices = Get-Service -Name "VMware*"
    if ($null -eq $workstationServices) {
        Write-Host "VMware Workstation services are not running. Ensure VMware Workstation is installed and running." -ForegroundColor Yellow
        Exit
    }

    # Get a list of running VMs
    $runningVMs = & "C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe" list

    # Get a list of all VMX files in the specified directory
    $vmxFiles = Get-ChildItem -Path $vmxPath -Filter "*.vmx" -Recurse

    # Create array to store background jobs
    $jobs = @()

    # Shut down each running VM gracefully in parallel
    foreach ($vmxFile in $vmxFiles) {
        $vmName = [System.IO.Path]::GetFileNameWithoutExtension($vmxFile.FullName)
        if ($runningVMs -match "$vmName.vmx") {
            # Start the VM shutdown as a background job with VM name as job name
            $job = Start-Job -ScriptBlock {
                param ($vmxFile, $vmName)
                & "C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe" stop "$($vmxFile.FullName)" soft
            } -ArgumentList $vmxFile, $vmName -Name "$vmName"

            # Add the job to the jobs array
            $jobs += $job
            # Display the status of started job
            Write-Host "Started shutting down VM: $vmName" -ForegroundColor Green
        } else {
            Write-Host "VM $vmName is not running." -ForegroundColor Yellow
        }
    }

    # Return the array of background jobs
    return $jobs
}

# Main script
function Stop-VMs {
    param (
        [string]$lab01Path,
        [string]$sandboxPath
    )

    # Create arrays to store background jobs for Lab01 and Sandbox VMs
    $lab01Jobs = @()
    $sandboxJobs = @()

    # Prompt user to select which folder to shut down VMs from
    $choice = Read-Host "Select which VMs to shut down:`n1. Lab01`n2. Sandbox`n[Leave blank for both]"

    if ($choice -eq "1") {
        $lab01Jobs = Stop-RunningVMs -vmxPath $lab01Path
    }
    elseif ($choice -eq "2") {
        $sandboxJobs = Stop-RunningVMs -vmxPath $sandboxPath
    }
    else {
        $lab01Jobs = Stop-RunningVMs -vmxPath $lab01Path
        $sandboxJobs = Stop-RunningVMs -vmxPath $sandboxPath
    }

    # Wait for all Lab01 and Sandbox jobs to complete
    $allJobs = $lab01Jobs + $sandboxJobs
    Wait-Job -Job $allJobs | Out-Null
}

# Define paths to VM folders
$lab01Path = "D:\Virtual Machines\VMS\Lab01"
$sandboxPath = "D:\Virtual Machines\VMS\Sandbox"

# Call Stop-VMs function with folder paths as arguments
Stop-VMs -lab01Path $lab01Path -sandboxPath $sandboxPath
