<# 

This script automates the process of fixing WSUS client issues on a list of specified computers by performing a series of steps including service management, folder manipulation, Group Policy update, and Windows Update actions. 

#>

function Repair-WSUSClient {
    param(
        [string]$ComputerListPath = "C:\computers.txt"
    )

    $computers = Get-Content $ComputerListPath

    foreach ($computer in $computers) {
        Write-Host "Fixing WSUS client on $computer" -ForegroundColor Yellow
        Invoke-Command -ComputerName $computer -ScriptBlock {
            Write-Host "Stopping bits and wuauserv services." -ForegroundColor Green
            Stop-Service bits
            Stop-Service wuauserv
            Start-Sleep -Seconds 10

            Write-Host "Renaming the SoftwareDistribution folder to SoftwareDistribution.old" -ForegroundColor Green
            Rename-Item -Path C:\Windows\SoftwareDistribution -NewName C:\Windows\SoftwareDistribution.old
            Start-Sleep -Seconds 10

            Write-Host "Starting bits and wuauserv services." -ForegroundColor Green
            Start-Service bits
            Start-Service wuauserv
            Start-Sleep -Seconds 10

            Write-Host "Running gpupdate." -ForegroundColor Green
            Invoke-GPUpdate -Force -Target "Computer"
            Start-Sleep -Seconds 10

            Write-Host "Running Windows Update reset, detect and reporting now." -ForegroundColor Green
            Start-Process -FilePath C:\Windows\System32\wuauclt.exe /resetauthorization
            Start-Process -FilePath C:\Windows\System32\wuauclt.exe /detectnow
            Start-Process -FilePath C:\Windows\System32\wuauclt.exe /reportnow
        }
    }
}
