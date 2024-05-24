# Function to get the DHCP server IP address from network settings
function Get-DHCPServerIP {
    $dhcpInterface = Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet" | Where-Object {$_.AddressState -eq "Dhcp"}
    if ($dhcpInterface) {
        $dhcpServerIP = $dhcpInterface.DHCPServer
        return $dhcpServerIP
    } else {
        Write-Host "No DHCP server found on the network."
        return $null
    }
}

# Function to get the IP address of a specific network interface
function Get-IPAddress {
    param (
        [string]$InterfaceName
    )
    $ipConfig = Get-NetIPAddress -InterfaceAlias $InterfaceName -AddressFamily IPv4
    return $ipConfig.IPAddress
}

# Function to request DHCP reservation for the given IP address
function Request-DHCPReservation {
    param (
        [string]$IPAddress
    )
    $dhcpServerIP = Get-DHCPServerIP
    if ($dhcpServerIP) {
        $macAddress = (Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }).MacAddress
        $dhcpCmd = "Add-DhcpServerv4Reservation -IPAddress $IPAddress -ClientId $macAddress -Server $dhcpServerIP -Description 'Reserved for my machine'"
        Invoke-Expression $dhcpCmd
    } else {
        Write-Host "Failed to determine DHCP server IP address."
    }
}

# Get the IP address of the network interface
$interfaceName = "Ethernet"  # Change this to match your network interface name
$ipAddress = Get-IPAddress -InterfaceName $interfaceName

# If IP address is not null, request DHCP reservation
if ($null -ne $ipAddress) {
    Request-DHCPReservation -IPAddress $ipAddress
}
