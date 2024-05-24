<#

This script can be useful for managing DHCP reservations in an environment where it's important to regularly clean up inactive reservations to free up IP addresses. Ensure that the script is run with appropriate permissions to manage DHCP reservations.

Get-DHCPServerIP: This function attempts to retrieve the DHCP server's IP address from the network settings. It does so by checking the network interface configuration to see if DHCP is being used and retrieves the DHCP server IP if found.

Discover-DHCPServerIP: If the DHCP server IP address is not obtained through network settings, this function sends a DHCP discover packet to the network and listens for a DHCP offer packet to obtain the DHCP server IP dynamically.

Get-InactiveDHCPReservations: This function takes the DHCP server IP address and a threshold of days as input parameters. It retrieves all DHCP reservations from the specified DHCP server and filters out those reservations that have been inactive for more than the specified number of days.

Purge-InactiveDHCPReservations: This function takes the DHCP server IP address and a threshold of days as input parameters. It uses the Get-InactiveDHCPReservations function to obtain inactive reservations older than the specified threshold and removes them from the DHCP server.

The script sets the $daysThreshold variable to 30 days by default, but you can modify it as needed.

It retrieves the DHCP server IP address either through Get-DHCPServerIP or Discover-DHCPServerIP functions.

If the DHCP server IP address is not obtained, it prints a message and exits.

Finally, it purges inactive DHCP reservations older than the specified threshold using the Purge-InactiveDHCPReservations function.

#>

# Function to get the DHCP server IP address from network settings
function Get-DHCPServerIP {
    $dhcpServerIP = $null

    # Check if the client machine is configured to use DHCP
    $dhcpInterface = Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet" | Where-Object {$_.AddressState -eq "Dhcp"}
    if ($null -ne $dhcpInterface) {
        $dhcpServerIP = $dhcpInterface.DHCPServer
    }

    return $dhcpServerIP
}

# Function to discover DHCP server IP address
function Get-DHCPServerIP {
    $dhcpDiscover = [byte[]]@(0x01,0x01,0x06,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00)
    $dhcpSocket = New-Object System.Net.Sockets.UdpClient
    $dhcpSocket.Client.Bind(([System.Net.IPEndPoint]::new([System.Net.IPAddress]::Any, 68)))
    $dhcpSocket.Send($dhcpDiscover, $dhcpDiscover.Length, "255.255.255.255", 67)
    $dhcpResponse = $dhcpSocket.Receive([ref][System.Net.IPEndPoint]::new())
    $dhcpSocket.Close()
    $dhcpServerIP = $dhcpResponse.Address.ToString()
    return $dhcpServerIP
}

# Function to get inactive DHCP reservations older than a specified number of days
function Get-InactiveDHCPReservations {
    param (
        [string]$DHCPServerIP,
        [int]$DaysThreshold
    )
    $inactiveReservations = @()
    $currentDate = Get-Date
    $allReservations = Get-DhcpServerv4Reservation -ComputerName $DHCPServerIP

    foreach ($reservation in $allReservations) {
        $lastSeen = $reservation.LastSeen
        $reservationAge = $currentDate - $lastSeen
        if ($reservationAge.Days -ge $DaysThreshold) {
            $inactiveReservations += $reservation
        }
    }

    return $inactiveReservations
}

# Function to purge inactive DHCP reservations
function Remove-InactiveDHCPReservations {
    param (
        [string]$DHCPServerIP,
        [int]$DaysThreshold
    )
    $inactiveReservations = Get-InactiveDHCPReservations -DHCPServerIP $DHCPServerIP -DaysThreshold $DaysThreshold

    foreach ($reservation in $inactiveReservations) {
        $reservationIPAddress = $reservation.IPAddress
        Remove-DhcpServerv4Reservation -ComputerName $DHCPServerIP -IPAddress $reservationIPAddress -Force
        Write-Output "Purged reservation for IP address $reservationIPAddress"
    }
}

# Specify days threshold for inactive reservations
$daysThreshold = 30  # Modify this value as needed

# Get DHCP server IP address dynamically based on network settings
$dhcpServerIP = Get-DHCPServerIP

# Check if DHCP server IP address is obtained
if ($null -eq $dhcpServerIP) {
    # If DHCP server IP address is not obtained, try discovering it
    $dhcpServerIP = Discover-DHCPServerIP
}

# Check if DHCP server IP address is obtained
if ($null -eq $dhcpServerIP) {
    Write-Host "Failed to retrieve DHCP server IP address."
    exit
}

# Purge inactive DHCP reservations older than specified days threshold
Remove-InactiveDHCPReservations -DHCPServerIP $dhcpServerIP -DaysThreshold $daysThreshold
