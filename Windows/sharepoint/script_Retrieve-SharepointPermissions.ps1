# Connect to SharePoint Online
Connect-PnPOnline -Url "https://yoursharepointsite.sharepoint.com/sites/YourSiteName" -UseWebLogin

# Get all lists and libraries
$lists = Get-PnPList

# Loop through each list and library
foreach ($list in $lists) {
    Write-Host "Permissions for $($list.Title):"

    # Get permissions for the list or library
    $permissions = Get-PnPProperty -ClientObject $list -Property RoleAssignments.Include(Principal, RoleDefinitionBindings)

    # Loop through each role assignment
    foreach ($permission in $permissions.RoleAssignments) {
        $principal = $permission.Member
        $roleBindings = $permission.RoleDefinitionBindings

        Write-Host "Principal: $($principal.Title)"
        
        # Loop through each role definition
        foreach ($role in $roleBindings) {
            Write-Host "Role: $($role.Name)"
        }
    }

    Write-Host ""
}
