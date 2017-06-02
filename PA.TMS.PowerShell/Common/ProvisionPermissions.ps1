function AddorUpdatePermissionLevel($spSite, [string]$roleName, [string]$roleDescription, $permissions)
{
    $rootWeb = $spSite.RootWeb
    $role = $rootWeb.RoleDefinitions[$roleName]
    if ($role -ne $null)
    {
        $role.Description = $roleDescription
        $role.BasePermissions = $permissions
        $role.Update()
        #$rootWeb.RoleDefinitions.Delete($roleName)
        #$rootWeb.Update()
    }
    else
    {
        $newRoleDefinition = New-Object Microsoft.SharePoint.SPRoleDefinition
        $newRoleDefinition.Name = $roleName
        $newRoleDefinition.Description = $roleDescription
        $newRoleDefinition.BasePermissions = $permissions
        $rootWeb.RoleDefinitions.Add($newRoleDefinition)
    }
    Write-Host "Provisioned role '$roleName' at" $rootWeb.Url -foregroundcolor DarkGreen
}

function AddorUpdateSecurityGroup($spSite, [string]$groupName, [string]$groupOwner, $permissionLevels)
{
    $rootWeb = $spSite.RootWeb
    $group = $rootWeb.SiteGroups[$groupName]
    if ($group -eq $null)
    {
        $rootWeb.SiteGroups.Add($groupName,$rootWeb.AllUsers[$groupOwner], $null, $groupName)
        Write-Host "Created group '$groupName' at" $rootWeb.Url -foregroundcolor DarkGreen
        # Assigning new permission level to the group
        $newGroup = $rootWeb.SiteGroups[$groupName]
        $permissionLevels | foreach { 
            $rootWeb.Roles[$_].AddGroup($newGroup) 
            Write-Host "Assigned role '$_' to group '$groupName' at $($rootWeb.Url)" -foregroundcolor Gray
        }				
    }
}

function Remove-Role($spSite, [string]$roleName)
{
	$rootWeb = $spSite.RootWeb
    $role = $rootWeb.RoleDefinitions[$roleName]
    if ($role -ne $null)
    {
        $rootWeb.RoleDefinitions.Delete($roleName)
        $rootWeb.Update()
		Write-Host "Removed role '$roleName' at" $rootWeb.Url -foregroundcolor DarkGreen
    }
	$rootWeb.Dispose()
}

function Remove-SPGroup($web, [string]$groupName)
{
    $group = $web.SiteGroups[$groupName]
    if ($group -ne $null)
    {
        $web.SiteGroups.Remove($group)
		$web.Update()
		Write-Host "Removed group '$groupName' at" $web.Url -foregroundcolor DarkGreen
    }
	$web.Dispose()
}

function AddorUpdateSecurityGroupToWeb($web, [string]$groupName, [string]$groupOwner, $permissionLevels)
{
    $group = $web.SiteGroups[$groupName]
    if ($group -eq $null)
    {
		$userTe = $web.AllUsers[$groupOwner]
        $web.SiteGroups.Add($groupName,$userTe, $null, $groupName)
        $web.Update()
        Write-Host "Created group '$groupName' at" $web.Url -foregroundcolor DarkGreen
    }
    else
    {
        $ra = $group.ParentWeb.RoleAssignments.GetAssignmentByPrincipal($group)
        foreach ($permission in $web.RoleDefinitions) {
            $rd = $group.ParentWeb.RoleDefinitions[$permission.Name]
            $ra.RoleDefinitionBindings.Remove($rd)
        }
        $ra.Update()
        $group.Update()
    }
    if (!$web.IsRootWeb) {
        $web.BreakRoleInheritance($true)
    }
    # Assigning new permission level to the group
    $newGroup = $web.SiteGroups[$groupName]

    $permissionLevels.Split(",") | foreach { 
        $web.Roles[$_].AddGroup($newGroup) 
        Write-Host "Assigned role '$_' to group '$groupName' at $($web.Url)" -foregroundcolor Gray
    }
}

function UpdateGroupOwnerToWeb($web, [string]$groupName, [string]$groupOwner)
{
    $group = $web.SiteGroups[$groupName]
    if ($group -ne $null)
    {
		#Get the Group 
        $ownerGroup = $web.SiteGroups[$groupOwner]
        if ($ownerGroup -ne $null)
        {
            #Assign Group as the owner
            $group.Owner = $ownerGroup

            #Update the Group
            $group.Update()
        }
        else
        {
           Write-Host "Can not find group '$groupOwner' at " $web.Url -foregroundcolor Yellow 
        }
        Write-Host "Update group owner of '$groupName' to " $groupOwner " at " $web.Url -foregroundcolor DarkGreen
    }
    else
    {
       Write-Host "Can not find group '$groupName' at " $web.Url -foregroundcolor Yellow 
    }
}

function UpdateGroupSettingsAndMember($web, [string]$groupName, $defaultMember, $everyOneCanView)
{
    $group = $web.SiteGroups[$groupName]
    if ($group -ne $null)
    {
        if($_.EveryoneCanView -eq $true)
        {
		    $group.OnlyAllowMembersViewMembership = $false
            #Update the Group
            $group.Update()
            Write-Host "Update group setting of '$groupName' to everyone can view at " $web.Url -foregroundcolor DarkGreen
        }
        if($defaultMember -ne $null -and $defaultMember -ne "")
        {
            try
            {
                $spUser = $web.EnsureUser($defaultMember)
                Set-SPUser -Identity $spUser -Web $web -Group $group
                Write-Host "User '$defaultMember' has been added to group '$groupName' successfully at " $web.Url -foregroundcolor DarkGreen       
            }
            catch
            {
                Write-Host "Can not find user '$defaultMember' at " $web.Url -foregroundcolor Yellow 
            } 
        }
    }
    else
    {
       Write-Host "Can not find group '$groupName' at " $web.Url -foregroundcolor Yellow 
    }
}


function AddorUpdateSecurityGroupToList($web, $list, [string]$groupName, [string]$groupOwner, $permissionLevels, $toClearRoleBinding)
{              
	$list.BreakRoleInheritance($true)	

    if ($web.SiteGroups[$groupName] -ne $null)
    {
        $group = $web.SiteGroups[$groupName]
        $roleAssignment = new-object Microsoft.SharePoint.SPRoleAssignment($group)
        if($permissionLevels -eq "No Access"){
            $list.RoleAssignments.Remove($group)
            $list.Update();
            Write-Host "Removed '$groupName' group from '$list' list at $($web.Url)." -foregroundcolor Gray
        }
        else{
            $permissionLevels.Split(",") | foreach { 
                $roleDefinition = $web.RoleDefinitions[$_]
                if($toClearRoleBinding -ne $null -and $toClearRoleBinding -eq $true){
                    $list.RoleAssignments.Remove($group)
                    $list.Update();
                } 
                $roleAssignment.RoleDefinitionBindings.Add($roleDefinition)
            }
            $list.RoleAssignments.Add($roleAssignment)
            $list.Update();       
		    Write-Host "Added '$groupName' group to '$list' list at $($web.Url)." -foregroundcolor Gray
        }
    }
    else
    {
        Write-Host "Group '$groupName' does not exist." -foregroundcolor Red
    }        
}

function AddorUpdateUserPermissionToList($web, $list, [string]$userName, $permissionLevels)
{   
    #$userName = “lc\Administrator”
    $user = $web.EnsureUser($userName)           

    if ($user -ne $null)
    {
        $roleAssignment = New-Object Microsoft.SharePoint.SPRoleAssignment($user)
        $permissionLevels.Split(",") | foreach { 
            $roleDefinition = $web.RoleDefinitions[$_]
            $roleAssignment.RoleDefinitionBindings.Add($roleDefinition)
        }
        $list.RoleAssignments.Add($roleAssignment)
        $list.Update();       
		Write-Host "Added user'$userName' to '$list' list at $($web.Url)." -foregroundcolor Gray
    }
    else
    {
        Write-Host "User '$userName' does not exist." -foregroundcolor Red
    }        
}

function RemoveSecurityGroupFromList($web, $list, [string]$groupName)
{              
	$list.BreakRoleInheritance($true)	
	
    if ($web.SiteGroups[$groupName] -ne $null)
    {
        $group = $web.SiteGroups[$groupName]
		if($group -ne $null) {
          $list.RoleAssignments.Remove($group)
          $list.Update();       
		}
		Write-Host "Removed $GroupName' group from '$list' list at $($web.Url)." -foregroundcolor Gray
    }
    else
    {
        Write-Host "Group '$GroupName' does not exist." -foregroundcolor Red
    }        
}

function RemoveAllSecurityGroupFromList($web, $list)
{              
	$list.BreakRoleInheritance($true)	
	
    foreach ($group in $web.SiteGroups){
		if($group -ne $null) {
          $list.RoleAssignments.Remove($group)
          $list.Update();       
		}
		Write-Host "Removed '$group' group from '$list' list at $($web.Url)." -foregroundcolor Gray
     }
}

function DoAddUserToSecurityGroup([string]$siteUrl, [string]$identity, [string]$groupName)
{
  Set-SPUser -Identity $identity –Web $siteUrl –Group $groupName
}

function DoSetUserAsSiteCollectionAdministrator([string]$siteUrl, [string]$identity, [string]$email=$null, [string]$name=$null, [string]$notes=$null)
{
  $spSite = Get-SPSite $siteUrl
  $rootWeb = $spSite.RootWeb
  $user = $null
  $rootWeb.AllUsers | foreach { if ($_.UserLogin.ToLower() -eq $identity.ToLower()) { $user = $_ } }
  if($user -eq $null) {
    $rootWeb.Add($identity, $email, $name, $notes)
  }
  $rootWeb.AllUsers | foreach { if ($_.UserLogin.ToLower() -eq $identity.ToLower()) { $_.IsSiteAdmin = $true; $_.Update() } }
}

function RemoveUnusableGroupsFromWeb($web, $usaableGroups){
    $groups = $web.SiteGroups
    for ($i = $groups.Count-1; $i -ge 0; $i--){
	    if($groups[$i] -ne $null -and $useableGroups.Contains($groups[$i].Name) -ne $true) {
            $groupName = $groups[$i].Name
            $web.SiteGroups.Remove($groups[$i])
		    $web.Update()
		    Write-Host "Removed group '$groupName' at" $web.Url -foregroundcolor DarkGreen       
	    }
    }
}

function DoProvisioningPermission([string]$fullPath, $siteUrl)
{
	$config = GetXmlStructure($fullPath)
    
    $siteCollectionUrl = ExpandURI $config.Web.Url $false
    $site = $null;
    if($siteUrl -ne $null){
        $site = Get-SPSite $siteUrl
    }
    else{
        $site = Get-SPSite $siteCollectionUrl
    }
    if($site -eq $null){
		Write-Host "Invalid web url $siteCollectionUrl"
		return
	}
    
    $config = $config.Web.Data
    
    if ($config.Security.Roles -ne $null -and $config.Security.Roles.Role -ne $null) {
        $config.Security.Roles.Role | ForEach-Object {
            $basePermissions = ($_.permission | % { $_.Name }) -join ','
            AddorUpdatePermissionLevel $site $_.Name $_.Description $basePermissions
        }
    }
    else {
        #Write-Host "Roles are not defined" -foregroundcolor Yellow
    }
    
    
    if ($config.Security.Sites -ne $null -and $config.Security.Sites.Site -ne $null) {
	    $owner = ExpandURI $config.Security.OwnerAlias
        $config.Security.Sites.Site | ForEach-Object {		    
                      
            if($siteUrl -ne $null){
                $web = Get-SPWeb ($siteUrl + $_.SubSiteUrl)
            }
            else{
                $web = Get-SPWeb ($siteCollectionUrl + $_.SubSiteUrl)
            }

            $useableGroups = @();
            if($_.Group -ne $null){
                $_.Group | ForEach-Object {
                    $groupName = $web.Title + " " + $_.Name 
                    Write-Host $groupName
                    $useableGroups+= $groupName
				    AddorUpdateSecurityGroupToWeb $web $groupName $owner $_.Role
			    }
    

                $_.Group | ForEach-Object {
				    if($_.GroupOwner -ne $null)
				    {
	                    $groupName = $web.Title + " " + $_.Name 
	                    $groupOwner = $web.Title + " " + $_.GroupOwner 
	                    Write-Host $groupName
					    UpdateGroupOwnerToWeb $web $groupName $groupOwner

                        UpdateGroupSettingsAndMember $web $groupName $_.DefaultMember $_.EveryoneCanView
				    }	
			    }
            

                Write-Host -ForegroundColor Green "Deleting unusable groups for" $web.Url "..."
                RemoveUnusableGroupsFromWeb $web $useableGroups
			}		
			#Process lists in the site.
			if($_.Lists -ne $null -and $_.Lists.List -ne $null)
			{					
				$_.Lists.List | ForEach-Object{							
					$list = $web.Lists.TryGetList($_.Name);
					if($list -ne $null)
					{					
    
						if($_.Group -ne $null)
						{		
                            if($_.RemoveAllGroup -ne $null -and $_.RemoveAllGroup -eq $true){
                                RemoveAllSecurityGroupFromList $web $list					
                            }
							$_.Group | ForEach-Object {							
                                #code follow as flow of UI
								#if($_.Delete -eq $true) {
								#  RemoveSecurityGroupFromList $web $list $_.Name 
								#}
								#else { #add groups to a list
                                    $groupName = $_.Name
                                    if($_.IsFullName -ne $null -and $_.IsFullName -eq $false){
                                        $groupName = $web.Title + " " + $_.Name 	
                                    }							
									AddorUpdateSecurityGroupToList $web $list $groupName $config.Security.OwnerAlias $_.Role $_.ToClearRoleBinding										
								#}  
							}
						}
                        if($_.User -ne $null)
						{
                            $_.User | ForEach-Object {							
                                $userName = $_.Name 								
                                AddorUpdateUserPermissionToList $web $list $userName $_.Role										  
							}
                        }	
					}
					else
					{
						Write-Host "There is no '$($_.Name)' list in the site '$web'." -foregroundcolor Yellow							
					}											
				}
			}
            
        }        
    }
    else {
        Write-Host "Sites are not defined" -foregroundcolor Yellow
    }	
    
}

function DoRollbackSecurity([string]$configFileName)
{
	$config = GetXmlStructure($configFileName)
    
    $siteCollectionUrl = ExpandURI $config.Security.SiteCollectionUrl $false
    $site = Get-SPSite $siteCollectionUrl
	if ($config.Security.Sites -ne $null -and $config.Security.Sites.Site -ne $null) {
	    $owner = ExpandURI $config.Security.OwnerAlias		
        $config.Security.Sites.Site | ForEach-Object {		    
                      
			$web = Get-SPWeb ($siteCollectionUrl + $_.SubSiteUrl)
			$_.Group | ForEach-Object {
				#AddorUpdateSecurityGroupToWeb $web $_.Name $owner $_.Role
				Remove-SPGroup $web $_.Name
			}
        }
        
    }else {
        Write-Host "Sites are not defined" -foregroundcolor Yellow
    }
	
    if ($config.Security.Roles -ne $null -and $config.Security.Roles.Role -ne $null) {
        $config.Security.Roles.Role | ForEach-Object {
            #AddorUpdatePermissionLevel $site $_.Name $_.Description $_.BasePermissions
			Remove-Role $site $_.Name
        }
    }else {
        Write-Host "Roles are not defined" -foregroundcolor Yellow
    } 	
}