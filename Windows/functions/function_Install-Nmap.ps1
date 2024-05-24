# Function to install Nmap using Chocolatey if not installed

function Install-Nmap {
    if (-not (Get-Command nmap -ErrorAction SilentlyContinue)) {
        Write-Host "Nmap is not installed. Installing Nmap using Chocolatey..."
        try {
            choco install nmap -y
        } catch {
            Write-Error "Failed to install Nmap using Chocolatey."
            exit
        }
    }
}
