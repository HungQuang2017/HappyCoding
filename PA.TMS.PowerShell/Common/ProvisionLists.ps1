function ProvisionListsForSpecificUrl([string]$dataFileName, $siteUrl)
{
	$siteData = GetXmlStructure($dataFileName)
	$isMigration = $false
    $noCrawl = $false
	if($spWeb -eq $null){
		$spWeb = Get-SPWeb -site $siteUrl
	}
	if($spWeb -eq $null){
		Write-Host "Invalid web url $siteUrl"
		return
	}    

	$siteData.Web.Data.Lists.List | foreach {
		Write-Host "Provision list: " $_.Name        
		ProvisionList $spWeb $_.Name $_.DisplayName $_.Existed $_.Description $_.ShowQuickLink $_.ContentType $_.View $_.Type $_.Field $_.SecurityBits $_.EnableEnterpriseKeywords $_.EnableRating $_.EnableLike $_.FolderCreation $_.RequireCheckOut $isMigration $noCrawl $_.inlineEdit $_.VersioningEnabled
	}
	$spWeb.Update()
	$spWeb.Dispose();
}

function ProvisionLists([string]$dataFileName, $siteUrl)
{
	$isMigration = $false    

	#$fullPath = $gDataPath + $dataFileName
	$siteData = GetXmlStructure($dataFileName)
    $url = ''
    if($siteUrl -eq $null){
        $url = ExpandURI $siteData.Web.Url
    }
    else{
        $url = $siteUrl 
    }

    $spWeb = Get-SPWeb $url
    
	if($spWeb -eq $null){
		Write-Host "Invalid web url $url"
		return
	}
    
    if($siteData.Web.Data.Lists.list.Length -eq 0) {
        return;
    }

	$siteData.Web.Data.Lists.List | foreach {
		Write-Host "Provision list: " $_.Name        
        
        #Write-Host "No Crawl: " $_.NoCrawl -ForegroundColor Cyan
        $noCrawl = $false
        if($_.NoCrawl -eq "TRUE"){
            $noCrawl = $true            
        }        

        ProvisionList $spWeb $_.Name $_.DisplayName $_.Existed $_.Description $_.ShowQuickLink $_.ContentType $_.View $_.Type $_.Field $_.SecurityBits $_.EnableEnterpriseKeywords $_.EnableRating $_.EnableLike $_.FolderCreation $_.RequireCheckOut $isMigration $noCrawl $_.inlineEdit $_.VersioningEnabled $_
	}
	$spWeb.Update()
	$spWeb.Dispose();
}

function ProvisionList($spWeb, [string]$listName, [string]$listDisplayName, $isExisted, [string]$listDescription,[string]$showQuickLaunch,$cTypes,$view,[string]$Type, $fields, $securityBits, $enableEnterpriseKeywords, $enableRating, $enableLike, $folderCreation, $requireCheckOut, $isMigration, $noCrawl, $inlineEdit, $versioningEnabled, $listMetadata)
{
	if($isMigration -eq $null) {
        $isMigration = $false
    }

	$list = $null
    if ($listDisplayName) {
	    $list=$spWeb.Lists[$listDisplayName]
    }
    else{
        $list=$spWeb.Lists[$listName]
    }
    
    if ($listDisplayName -ne $null -and $list -eq $null -and $isExisted){
        $list=$spWeb.Lists[$listName]
    }

	if($list -ne $null)
	{
        if ($isExisted) {
            UpdateList $spWeb $list $cTypes $fields $view $securityBits $enableEnterpriseKeywords $enableRating $enableLike $listDisplayName $folderCreation $Type $requireCheckOut $isMigration $noCrawl $inlineEdit $versioningEnabled $listMetadata
        }
        else {
		    write-host "The $listName existed!" -ForegroundColor Yellow
        }
	}
	else
	{
		Write-Host "Creating list: "$listName
        trap {
	    	    Write-Warning ('Failed to Create List "{0}" : {1}' -f $_.Exception.Message, $_.InvocationInfo.ScriptName)
			    Write-Host "Delete the list!"
                        
			    $failedList = $spWeb.Lists[$listName]
                if ($failedList -ne $null)
                {
			        $failedList.Delete()
                }
	    	    continue
	    }        

		# Create SPList
        switch ($Type)
		{
			"GenericList" { $listTemplateType = $spWeb.ListTemplates | Where-Object {$_.Type -eq 100} }
            "DocumentLibrary" { $listTemplateType = $spWeb.ListTemplates | Where-Object {$_.Type -eq 101} }
            "Survey" { $listTemplateType = $spWeb.ListTemplates | Where-Object {$_.Type -eq 102} }
            "Links" { $listTemplateType = $spWeb.ListTemplates | Where-Object {$_.Type -eq 103} }
            "Announcements" { $listTemplateType = $spWeb.ListTemplates | Where-Object {$_.Type -eq 104} }
            "Contacts" { $listTemplateType = $spWeb.ListTemplates | Where-Object {$_.Type -eq 105} }
            "Events" { $listTemplateType = $spWeb.ListTemplates | Where-Object {$_.Type -eq 106} }
            "Tasks" { $listTemplateType = $spWeb.ListTemplates | Where-Object {$_.Type -eq 107} }
            "DiscussionBoard" { $listTemplateType = $spWeb.ListTemplates | Where-Object {$_.Type -eq 108} }

            "Picturelibrary" { $listTemplateType = $spWeb.ListTemplates | Where-Object {$_.Type -eq 109} }
            "WikiPagelibrary" { $listTemplateType = $spWeb.ListTemplates | Where-Object {$_.Type -eq 119} }
            "Issuetracking" { $listTemplateType = $spWeb.ListTemplates | Where-Object {$_.Type -eq 1100} }

			"AssetLibrary" { $listTemplateType = $spWeb.ListTemplates | Where-Object {$_.Type -eq 851} }
		}
        
        $tempList = $spWeb.Lists.Add($listName, $listDescription, $listTemplateType)

		#$list = $spWeb.GetList($listUrl)
        $list=$spWeb.Lists[$listName]


        if($cTypes) {
            $list.ContentTypesEnabled = $true
        }

		##if ($securityBits) {
	    ##    $list.ReadSecurity = $securityBits;		
        ##}

        if ($securityBits -and $securityBits.length -eq 1) {
	        $list.ReadSecurity = $securityBits;
        }
        elseif ($securityBits -and $securityBits.length -eq 2) {
	        $list.ReadSecurity = $securityBits[0].toString();
            $list.WriteSecurity = $securityBits[1].toString();
        }


        $list.Update()

		# Set Quick Launch attribute
		#$list.OnQuickLaunch=$true
             
        #if($showQuickLaunch -eq "FALSE")
        #{
        #    $list.OnQuickLaunch=$false
        #}

        UpdateList $spWeb $list $cTypes $fields $view $securityBits $enableEnterpriseKeywords $enableRating $enableLike $listDisplayName $folderCreation $Type $requireCheckOut $isMigration $noCrawl $inlineEdit $versioningEnabled $listMetadata
	}
}

# add, delete content types
# add, update fields
function UpdateList($spWeb, $list, $cTypes, $fields, $view, $securityBits, $enableEnterpriseKeywords, $enableRating, $enableLike, $listDisplayName, $folderCreation, $Type, $requireCheckOut, $isMigration, $noCrawl, $inlineEdit, $versioningEnabled, $listMetadata) {
    if ($list) {
        
        # adjust list title
        UpdateListTitle $list $listDisplayName
        
        if($folderCreation -eq $true){
			$list.EnableFolderCreation = $true
			$list.Update();
		}

        if($inlineEdit -ne $null -and $inlineEdit -eq $false){
			$list.DisableGridEditing = $true
            $list.Update()
		}

        if(($list.BaseType -eq "DocumentLibrary") -and ($isMigration -eq $false) -and $versioningEnabled -ne $null) {
            try {
              $vEnabled = [System.Convert]::ToBoolean($versioningEnabled) 
            } catch [FormatException] {
              $vEnabled = $false
            }
            $list.EnableVersioning = $vEnabled
            $list.Update()
        }    

        if($requireCheckOut -eq $true){ 
            $list.ForceCheckOut = $true;
            $list.Update();
        }
        elseif($requireCheckOut -eq $false){
            $list.ForceCheckOut = $false; 
            $list.Update();
        }

        if ($listMetadata.NavigateForFormsPages -and $listMetadata.NavigateForFormsPages -eq $true) {
	        $list.NavigateForFormsPages = $true
            $list.Update();
        }
        elseif ($listMetadata.NavigateForFormsPages -and $listMetadata.NavigateForFormsPages -eq $false) {
	        $list.NavigateForFormsPages = $false
            $list.Update();
        }

        $isEnabled = $true

        #Add site content types to the list
        if($cTypes -eq $null)
        {
            write-host "This list does not allow content types"
            if ($fields) {
                $fields | foreach {
                    if( $list.Fields.ContainsField($_.Name) -eq $false){
                        $field = GetFieldByInternalName $spWeb.Fields $_.Name
                        if ($field) {
                            $list.Fields.Add($field)
                        }
                    }
                }
            }
        }
        else
        {
            write-host "Update content types of list"
            AddContentTypeToList $spWeb $list $cTypes $isMigration
        }

        # adjust field in list
        UpdateListField $list $fields        

        #Update list view
        UpdateListView $view $list $Type 

		#Update list Item-Level Permissions
        UpdateListItemLevelPermissions $spWeb $securityBits $list
        
        if($enableEnterpriseKeywords -eq $true) {
            Enable-EnterpriseKeyword $spWeb $list $isEnabled
        }

        if(($enableRating -eq $true) -or ($enableLike -eq $true)) {
            Enable-Rating $spWeb $list $isEnabled $enableRating $enableLike
        }

        #Write-Host "No Crawl:" $noCrawl -ForegroundColor Cyan
        if($noCrawl -eq $true){
            $list.NoCrawl = $true
            $list.Update()
        }
        
        if(($list.BaseType -eq "DocumentLibrary") -and ($isMigration -eq $true)) {
            $list.EnableVersioning = $true
            $list.Update()
        } 
		

		if($inlineEdit -ne $null -and $inlineEdit -eq $true){
			$list.DisableGridEditing = $false
            $list.Update()
		} 
		
    }
}

function GetFieldByInternalName([Microsoft.SharePoint.SPFieldCollection]$spListItemColl, $Name)   {
    try{
        return $spListItemColl.GetFieldByInternalName($Name);
    }
    catch { }

    return $null;
}

function UpdateListTitle($list, $listDisplayName){
    if ($list -and $listDisplayName) {
	    $list.Title = $listDisplayName;
        $list.Update();
    }
}

function AddContentTypeToList($spWeb, $list, $cTypes, $isMigration) {
    $list.ContentTypesEnabled = $true
	$list.Update()

    if ($cTypes) {        
            #contentTypeList is used for change default content type
            $contentTypeList = New-Object 'System.Collections.Generic.List[Microsoft.SharePoint.SPContentType]'
	
	        #current list content type
	        $currentListCT = New-Object 'System.Collections.Generic.List[Microsoft.SharePoint.SPContentType]'
            $list.ContentTypes | foreach {
                $currentListCT += $_
            }
	
	        #new list content type
	        $notDefaultCT = New-Object 'System.Collections.Generic.List[Microsoft.SharePoint.SPContentType]'
            # [Cuc - 21/11/2014]
            $defaultCT = New-Object 'System.Collections.Generic.List[Microsoft.SharePoint.SPContentType]'
        
            $rootFolder = $list.RootFolder
        if($isMigration -and ($isMigration -eq $true)) {
            $ctName = $cTypes.Name
            $ct = $list.ContentTypes[$ctName]
                if($ct -eq $null) 
                {
                    $ct = $spWeb.ContentTypes[$ctName]
                    if($ct)
                    {
                        if (!$list.IsContentTypeAllowed($ct)){
                            Write-Host ("The {0} content type is not allowed on the {1} list" -f $ct.Name, $list.Title)
                        }
                        elseif ($list.ContentTypes[$ct.Name] -ne $null){
                            #content type will be deleted if the value of delete attribute = true
                            if($_.Delete){
                                $list.ContentTypes[$ctName].Delete()}
                            else {
                                Write-Host ("The content type name {0} is already in use on the {1} list" -f $ct.Name, $list.Title)
                            }
                        }
                        else{
                            $tempVar = $list.ContentTypes.Add($ct)
                            #first content type in contentTypeList will be set default content type
				            if ($_.Default -eq "TRUE") {
                                $contentTypeList += $list.ContentTypes[$ct.Name];
                                $defaultCT += $list.ContentTypes[$ct.Name];
				            }
				            else{
					            $notDefaultCT += $list.ContentTypes[$ct.Name];
				            }
                        }
                    }
                }
                else{
					#fixed issue #MIN-105
					$ct.ReadOnly = $false
                    if ($_.Default -eq "TRUE") {
                        $contentTypeList += $list.ContentTypes[$ct.Name];
                        $defaultCT += $list.ContentTypes[$ct.Name];
				    }
				    else{
					    $notDefaultCT += $list.ContentTypes[$ct.Name];
				    }
                    if ($_.EnableEnterpriseKeywords -eq "TRUE") {
                        $curListContentType = $list.ContentTypes[$ct.Name];
                        $ekfield = $list.ParentWeb.AvailableFields["Enterprise Keywords"]
                        if ($ekfield -ne $null -and $curListContentType -ne $null -and $curListContentType.Fields.ContainsField("Enterprise Keywords") -eq $false)
                        {
                            $curListContentType.FieldLinks.Add($ekfield)
                            $curListContentType.Update()
                        }
				    }
                }
        }
        else {
            $cTypes | foreach {
                $ct = $list.ContentTypes[$_.Name]
                if($ct -eq $null) 
                {
                    $ct = $spWeb.ContentTypes[$_.Name]
                    if($ct)
                    {
                        if (!$list.IsContentTypeAllowed($ct)){
                            Write-Host ("The {0} content type is not allowed on the {1} list" -f $ct.Name, $list.Title)
                        }
                        elseif ($list.ContentTypes[$ct.Name] -ne $null){
                            #content type will be deleted if the value of delete attribute = true
                            if($_.Delete){
                                $list.ContentTypes[$_.Name].Delete()}
                            else {
                                Write-Host ("The content type name {0} is already in use on the {1} list" -f $ct.Name, $list.Title)
                            }
                        }
                        else{
                            $tempVar = $list.ContentTypes.Add($ct)
                            #first content type in contentTypeList will be set default content type
				            if ($_.Default -eq "TRUE") {
                                $contentTypeList += $list.ContentTypes[$ct.Name];
                                # [Cuc - 21/11/2014]
                                $defaultCT += $list.ContentTypes[$ct.Name];
				            }
				            else{
					            $notDefaultCT += $list.ContentTypes[$ct.Name];
				            }
                        }
                    }
                }
                else{
					#fixed issue #MIN-105
					$ct.ReadOnly = $false
                    if ($_.Default -eq "TRUE") {
                        $contentTypeList += $list.ContentTypes[$ct.Name];
                        $defaultCT += $list.ContentTypes[$ct.Name];
				    }
				    else{
					    $notDefaultCT += $list.ContentTypes[$ct.Name];
				    }
                    if ($_.EnableEnterpriseKeywords -eq "TRUE") {
                        $curListContentType = $list.ContentTypes[$ct.Name];
                        $ekfield = $list.ParentWeb.AvailableFields["Enterprise Keywords"]
                        if ($ekfield -ne $null -and $curListContentType -ne $null -and $curListContentType.Fields.ContainsField("Enterprise Keywords") -eq $false)
                        {
                            $curListContentType.FieldLinks.Add($ekfield)
                            $curListContentType.Update()
                        }
				    }
                }
            }
        }        
        
	    $contentTypeList += $notDefaultCT
	    $contentTypeList += $currentListCT
        
        if($contentTypeList){
            if($defaultCT) {
                $rootFolder.UniqueContentTypeOrder = [Microsoft.SharePoint.SPContentType[]] $defaultCT

	            $rootFolder.Update();
            }
        }
        
    }
}

function UpdateListField ($list, $fields) {
    if ($fields) {
        Write-Host "Updating list fields"
        $fields | foreach {
            $field = GetFieldByInternalName $list.Fields $_.Name
            if ($field) {
                if ($_.Required){
                    $field.Required = [System.Convert]::ToBoolean($_.Required)}
                if ($_.ShowInEditForm){
                    $field.ShowInEditForm = [System.Convert]::ToBoolean($_.ShowInEditForm)}
                if ($_.ShowInDisplayForm){
                    $field.ShowInDisplayForm = [System.Convert]::ToBoolean($_.ShowInDisplayForm)}
                if ($_.ShowInNewForm){
                    $field.ShowInNewForm = [System.Convert]::ToBoolean($_.ShowInNewForm)}
                if ($_.Hidden){
                    $field.Hidden = [System.Convert]::ToBoolean($_.Hidden)}
                if ($_.EnforceUniqueValues) {
                    $enforceUniqueValues = [System.Convert]::ToBoolean($_.EnforceUniqueValues)
                    if ($enforceUniqueValues -eq $true) {
                        $field.EnforceUniqueValues = $true
                        $field.Indexed = $true
                    }
                }
                if ($_.DisplayName -ne $null -and $_.DisplayName -ne $field.Title) {
                    $field.Title = $_.DisplayName
                }
                if ($_.Description -ne $null -and $_.Description -ne $field.Description) {
                    $field.Description = $_.Description
                }
                if($_.RelationshipBehavior -ne $null){
                    $rb = $null
                    if($_.RelationshipBehavior -eq 'Cascade'){
                        $rb = [Microsoft.SharePoint.SPRelationshipDeleteBehavior]::Cascade
                    }
                    elseif($_.RelationshipBehavior -eq 'Restrict'){
                        $rb = [Microsoft.SharePoint.SPRelationshipDeleteBehavior]::Restrict
                    }
                    if($rb -ne $null){
                        $fieldLookup=[Microsoft.SharePoint.SPFieldLookup]$field
                        $fieldLookup.Indexed=$true
                        $fieldLookup.RelationshipDeleteBehavior = $rb
                        $fieldLookup.Update()
                    }
                }
                if ($_.MaxLength -ne $null -and $field.MaxLength -ne $null -and $_.MaxLength -ne $field.MaxLength) {
                    $field.MaxLength = $_.MaxLength
                }
                $field.Update()
            }
        }
    }
}

function UpdateListView($views,[Microsoft.SharePoint.SPList]$list, $Type){
    if ($views) {
        Write-Host "Adding/Updating list views"
        $views | foreach {
            $view = $_
	        #Retrieve view information
	        $viewName=$view.Name

            $isDefault=$false
            if($view.Default -eq $true)
            {
                $isDefault=$true
            }
	
            #Create view
            if($view.Existed -eq $false){
                if ($list.Views[$viewName]) {
                    Write-Host "View" $view.Name "is already existed."
                    return
                }
                Write-Host "Creating list view" $view.Name
	            $viewQuery= $null
            
	            #Create view fields
	            $spViewFields = New-Object System.Collections.Specialized.StringCollection    #Create string collection object
                if ($view.ViewField) {
	                $view.ViewField | foreach {
					    if($spViewFields.Contains($_) -eq $false){
							$spViewFields.Add($_)
						}
	                }
                }

	            #Provisioning the View
                if($Type -ne "Events") {            
                    $rowLimit = 100;
                    if($view.RowLimit){
                        $rowLimit = $view.RowLimit;
                    }
	                $spListView = $list.Views.Add($viewName, $spViewFields, $viewQuery, $rowLimit, $true, $isDefault)
                    if ($view.Query) {
                        $spListView.Query = $view.Query.InnerXml
                        $spListView.Update() 
                        #$list.Update()
                    }
                }
                else {
                    $querystring = $view.Query.InnerXml
                    $spListView = $list.Views.Add($viewName, $null, $querystring, 3, $false, $false, "CALENDAR", $false)
                }
            }

            #Update existing view
            else{
                Write-Host "Updating list view" $view.Name
                $spListView = $list.Views[$viewName]
                if($spListView -eq $null){
                    return;
                }
				if($view.NewName){
					$spListView.Title = $view.NewName;
				}
                if ($view.ViewField) {
                    if ($spListView.ViewFields) {
                        $spListView.ViewFields.DeleteAll()    
                    }                    
                    $view.ViewField| foreach {
	                    $spListView.ViewFields.Add($_)
	                }
                }
                if($Type -ne "Events") {
                    $spListView.DefaultView = $isDefault
                }
                if ($view.Query) {
                    $spListView.Query = $view.Query.InnerXml
                }
                if($view.RowLimit){
					$spListView.RowLimit = $view.RowLimit;
				}
            }

            $spListView.Update()
        }
    }
}

function UpdateListItemLevelPermissions($spWeb, $securityBits ,[Microsoft.SharePoint.SPList]$list){
    if ($securityBits -and $securityBits.length -eq 1) {
	    $list.ReadSecurity = $securityBits;
        $list.Update()
    }
    elseif ($securityBits -and $securityBits.length -eq 2) {
	    $list.ReadSecurity = $securityBits[0].toString();
        $list.WriteSecurity = $securityBits[1].toString();
        $list.Update()
    }
    
}

function Enable-EnterpriseKeyword([Microsoft.SharePoint.SPWeb]$spWeb, [string]$listName, [boolean]$isEnabled){
    #$list=$spWeb.Lists[$listName];

    if($list -ne $null)
    {
        $field = $list.ParentWeb.AvailableFields["Enterprise Keywords"]
        if ($list.Fields.ContainsField("Enterprise Keywords") -eq $false)
        {
            $list.Fields.Add($field)
            $list.Update()
            write-host $field.Title " added successfully to the list"
        }
        else
        {
            write-host $field.Title  " column already exists in the list"
        }
    }
    else
    {
       write-host $list.Title  " does not exists in the site"
    }
}

function Enable-Rating([Microsoft.SharePoint.SPWeb]$spWeb, [string]$listName, [boolean]$isEnabled, $enableRating, $enableLike){
    #$list=$spWeb.Lists[$listName];

    if($list -ne $null)
    {    
        $assembly=[System.Reflection.Assembly]::Load("Microsoft.SharePoint.Portal, Version=15.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c")

        $reputationHelper =$assembly.GetType("Microsoft.SharePoint.Portal.ReputationHelper");

        [System.Reflection.BindingFlags]$flags = [System.Reflection.BindingFlags]::Static -bor [System.Reflection.BindingFlags]::NonPublic;
 
        $methodInfo = $reputationHelper.GetMethod("EnableReputation", $flags);
 

        $currRatingSetting = $list.RootFolder.Properties["Ratings_VotingExperience"];

        if($currRatingSetting -ne 'Likes' -and $currRatingSetting -ne 'Ratings'){
            if($isEnabled -eq $true)
            {
                Write-Host "Enabling rating column in list : "$listName
            
            
                if($enableRating -eq $true){
                    #For enabling Ratings
                    $values = @($list, "Ratings", $false);
                }
                elseif($enableLike -eq $true){
                    #For enabling Likes
                    $values = @($list, "Likes", $false);
                }
 
                $methodInfo.Invoke($null, @($values));
            }
            else
            {
                Write-Host "Disabling rating column in list : "$listName
            
                #For disable Rating or Likes
                $methodInfo = $reputationHelper.GetMethod("DisableReputation", $flags);

                $disableValues = @($list);
            
                $methodInfo.Invoke($null, @($disableValues));
            }
        }
        else 
        {
            Write-Host "List" $listName "is already enable rating."
        }
    }
 } 

function EnableVersioning($spList){
    $spList.EnableVersioning = $true

    #$spList.EnableMinorVersions = $true
    #$list.MajorVersionLimit = 2
    #$list.MajorWithMinorVersionsLimit = 5

    $spList.Update()
}

function CreateListView($sourceList, $destList) {
    try {
        foreach($view in $sourceList.Views) {
            if($view.DefaultView -eq $true) {
                $viewName = $view.Title
                WriteLog("View Name: " + $viewName)

                $viewfields = $view.ViewFields.ToStringCollection()
                $viewRowLimit = $view.RowLimit
                $viewPaged = $view.Paged
                $viewQuery = $view.Query

                $testView = $destList.Views[$viewName]
                if($testView -eq $null) {                                
                    $newListView = $destList.Views.Add($viewName, $viewFields, $viewQuery, $viewRowLimit, $viewPaged, $False, "HTML", $False)
                    $newListView.DefaultView = $True

                    $newListView.Update()
                }
                else 
                {
                    foreach($column in $viewfields) {
                        if(!$testView.ViewFields.ToStringCollection().Contains($column)) {
                            $testView.ViewFields.Add($column)
                        }                        
                    }

                    $testView.Query = $view.Query
                    $testView.Paged = $view.Paged
                    $testView.RowLimit = $view.RowLimit
                    $testView.Update()
                }

                $destList.Update()
                break
            }
       }
   }
   catch [Exception]
   {
       WriteLog("CreateListView() - ERROR " + $_.Exception.Message + " : " + $_.InvocationInfo.ScriptName)
       LogErrorForMigration "CreateListView()" $_.Exception.Message $_.InvocationInfo.ScriptName $gErrorFilePath
       continue
   }
}

function ProvisionListData($dataFileName)
{
	$siteData = GetXmlStructure($dataFileName)
    $url = ''
    if($siteUrl -eq $null){
        $url = ExpandURI $siteData.Web.Url
    }
    else{
        $url = $siteUrl 
    }

    $spWeb = Get-SPWeb $url
    
	if($spWeb -eq $null){
		Write-Host "Invalid web url $url"
		return
	}
    
    if($siteData.Web.Data.Lists.list.Length -eq 0) {
        return;
    }

	$siteData.Web.Data.Lists.List | foreach {
        $spList = GetSPList $spWeb $_.Name
        if($spList -ne $null) {
            $addNew = $_.AddNew 
            $caml = $null
            if($addNew -eq $null -or ($addNew -ne $null -and $addNew.trim() -eq "false"))
            {
                
                DeleteAllListItems $spList
            }
            
		    $_.Item | foreach {
                
                $newItem = $null
                if($_.Field.Name -eq "Title" -or $_.Field[0].Name -eq "Title"){
                    $title
                    if($_.Field.Count -eq $null){
                       $title =  $_.Field.InnerText
                    }
                    else{
                        $title =  $_.Field[0].InnerText
                    }

                    if($addNew -eq $null -or $addNew -eq "true"){
                        $spQuery = new-object Microsoft.SharePoint.SPQuery
                        $caml = "<Where><Eq><FieldRef Name='Title'/><Value Type='Text'>" + $title + "</Value></Eq></Where>";
	                    $spQuery.Query = $caml
                        $spQuery.RowLimit = 1
                        $spListItemCollection = $spList.GetItems($spQuery)
                        if($spListItemCollection.Count -ne 1) {
                            $newItem = CreateListItemAtRoot $spList $title
                        }
                    }
		            
                }
                if($newItem -ne $null){
                    foreach($field in $_.Field) {
                        if($newItem -ne $null -and $field.Name -ne "Title"){
                            $newItem[$field.Name] = $field.InnerText
                            $newItem.Update()
                            $spList.Update();
                        }
                    }
                }
	        }
        }
	}
	$spWeb.Dispose();
}

function DeleteAllListItems($spList)
{
    $listItems = GetItemsByCamlQuery $spList $caml
	DeleteMultipleItems $spList $listItems
}