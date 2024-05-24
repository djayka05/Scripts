
function Test-SwitchParameter ( [Switch] $Foo ) 
{
	If ($Foo) 
     { '$Foo has a value of $TRUE'  }
	Else 
     { '$Foo has a value of $FALSE' }
}

# Call function with or without the switch parameter:
Test-SwitchParameter -Foo            #$Foo = $True
Test-SwitchParameter                 #$Foo = $False






function Test-CShare ($Computer, [Switch] $List) {
    $SharePath = "\\" + $Computer + "\C$"

    if ($List){ dir -Path $SharePath } 
    else { Test-Path -Path $SharePath } 
}

# Call function with or without the switch parameter:
Test-CShare -Computer Box47
Test-CShare -Computer Box47 -List 








function show-folder ([Switch] $list) {
	if ($list) {dir | format-list *}
	else {dir | format-table fullname,length -autosize}
}

# Call function with or without the switch parameter:
show-folder -list
show-folder -l
show-folder








function show-hkcu ([Switch] $list) {
	If ($list) {get-childitem hkcu:\ | format-list *}
	Else {dir hkcu:\ | ft name,subkeycount,valuecount}
}

# Call function with the switch parameter:
show-hkcu -list
show-hkcu -l


