# Review of Concepts:

1..5

1..5 | ForEach { "Hello" } 

1..5 | ForEach { "Hello $_" } 

Get-Process | ForEach { $_.Path }


#######################################################


$Array = Get-Process | Where { $_.Path -like "*svc*" } 

$Array.Count

$Array

$Array[3]

$Array[-1].Id

$Array[3] 

ForEach ($Foo in $Array){ $Foo.Id }


#######################################################


function Rabbits ($Count = 2){ $Count * $Count }

Rabbits


1..5 | ForEach { Rabbits -Count $_ } 

ForEach ($Foo in $Array){ Rabbits -Count $Foo.Id }


#######################################################


ise $Profile.CurrentUserAllHosts


function Get-SystemLogProblem ($Count = 20)
{ 
    $Hashtable = @{ LogName = "System" ; Level = @(1,2,3) }
    
    Get-WinEvent -FilterHashtable $Hashtable -MaxEvents $Count | 
      Select TimeCreated,Message | Out-GridView
}


Get-SystemLogProblem -Count 5


dir function:\*systemlog*


