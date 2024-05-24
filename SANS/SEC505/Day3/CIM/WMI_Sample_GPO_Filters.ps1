#*******************************************************************************
# Script Name: WMI_Sample_GPO_Filters.ps1
#     Version: 1.4
#      Author: Enclave Consulting LLC, Jason Fossen (www.sans.org/sec505)
#Last Updated: 9.Oct.2018
#     Purpose: The following are examples of WMI Filters for Group Policy Objects.
#       Legal: 0BSD.
return  #This is not an executable script, it just has sample queries.
#*******************************************************************************

 
#Applies if Windows Server 2019 Datacenter Edition is the operating system.
SELECT * FROM Win32_OperatingSystem WHERE Caption = 'Microsoft Windows Server 2019 Datacenter%'


#Applies if the OS is for a workstation or client (not a server OS or any other type of OS)
SELECT * FROM Win32_OperatingSystem WHERE ProductType = '1'


#Applies if the OS is NOT for a client OS (perhaps for a server or appliance)
SELECT * FROM Win32_OperatingSystem WHERE ProductType <> '1'


#Applies if the OS is Windows 7 or Server 2008 R2 (recall that "%" is a wildcard in WMI)
SELECT Version FROM Win32_OperatingSystem WHERE Version LIKE '6.1.%' 


#Applies if the computer is a Dell Latitude 
SELECT * FROM Win32_ComputerSystem WHERE Manufacturer LIKE '%Dell%' AND Model LIKE '%Latitude%' 


#Applies if the system has at least 16GB of physical memory (approximately)
SELECT * FROM Win32_ComputerSystem WHERE TotalPhysicalMemory >= 16000000000


#Applies if there is at least 500MB available on any drive (approximately) 
SELECT * FROM Win32_LogicalDisk WHERE FreeSpace > 500000000 AND Description = 'Local Fixed Disk'


#Applies if the ADMINPAK.MSI software package has been installed.
SELECT * FROM Win32_Product WHERE Name = 'ADMINPAK'

 
#Applies if located in the eastern time zone, i.e., five hours behind UTC "Zulu" time.
SELECT * FROM Win32_TimeZone WHERE bias =-300


#Applies if patch KB819696 or KB828026 has been applied.
SELECT * FROM Win32_QuickFixEngineering WHERE HotFixID = 'KB819696' OR HotFixID = 'KB828026'


#Applies if it is a Sunday (0=Sun, 1=Mon, 2=Tue, and so on)
SELECT * FROM Win32_LocalTime WHERE DayOfWeek = 0


