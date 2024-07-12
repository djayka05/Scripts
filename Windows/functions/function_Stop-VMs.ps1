# Function to gracefully shut down running VMs in the specified folder
function Stop-RunningVMs {
    param (
        [string]$vmxPath
    )

    # Check if VMware Workstation services are running
    $workstationServices = Get-Service -Name "VMware*" -ErrorAction SilentlyContinue
    if ($null -eq $workstationServices) {
        Write-Host "VMware Workstation services are not running. Ensure VMware Workstation is installed and running." -ForegroundColor Yellow
        return @()  # Return an empty array
    }

    # Get a list of running VMs
    $runningVMs = & "C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe" list

    # Check if there are running VMs
    if ($runningVMs -match "Total running VMs: 0") {
        Write-Host "No VMs are currently running." -ForegroundColor Yellow
        return @()  # Return an empty array
    }

    # Get a list of all VMX files in the specified directory
    $vmxFiles = Get-ChildItem -Path $vmxPath -Filter "*.vmx" -Recurse

    # Create array to store background jobs
    $jobs = @()

    # Shut down each running VM gracefully in parallel
    foreach ($vmxFile in $vmxFiles) {
        $vmName = [System.IO.Path]::GetFileNameWithoutExtension($vmxFile.FullName)
        if ($runningVMs -match "$vmName.vmx") {
            try {
                # Start the VM shutdown as a background job with VM name as job name
                $job = Start-Job -ScriptBlock {
                    param ($vmxFile, $vmName)
                    & "C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe" stop "$($vmxFile.FullName)" soft
                } -ArgumentList $vmxFile, $vmName -Name "$vmName"

                # Add the job to the jobs array
                $jobs += $job
                # Display the status of started job
                Write-Host "Started shutting down VM: $vmName" -ForegroundColor Green
            } catch {
                Write-Host "Failed to start job for VM: $vmName. Error: $_" -ForegroundColor Red
            }
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

    # Prompt user to select which folder to shut down VMs from
    $choice = Read-Host "Select which VMs to shut down:`n1. Lab01`n2. Sandbox`n[Leave blank for both]"

    # Initialize array for all jobs
    $allJobs = @()

    if ($choice -eq "1") {
        $allJobs = Stop-RunningVMs -vmxPath $lab01Path
    } elseif ($choice -eq "2") {
        $allJobs = Stop-RunningVMs -vmxPath $sandboxPath
    } else {
        $allJobs += Stop-RunningVMs -vmxPath $lab01Path
        $allJobs += Stop-RunningVMs -vmxPath $sandboxPath
    }

    if ($allJobs.Count -eq 0) {
        Write-Host "No jobs were created. Exiting." -ForegroundColor Yellow
        return
    }

    # Wait for all jobs to complete
    Wait-Job -Job $allJobs | Out-Null
}

# Define paths to VM folders
$lab01Path = "D:\Virtual Machines\VMS\Lab01"
$sandboxPath = "D:\Virtual Machines\VMS\Sandbox"

# Call Stop-VMs function with folder paths as arguments
Stop-VMs -lab01Path $lab01Path -sandboxPath $sandboxPath

$confirmation = Read-Host "Do you want to shut down the PC? (y/n)"

if ($confirmation -eq 'y') {
    Stop-Computer
} elseif ($confirmation -eq 'n') {
    Write-Host "Shutdown canceled."
} else {
    Write-Host "Invalid input. Please enter 'y' or 'n'."
}
