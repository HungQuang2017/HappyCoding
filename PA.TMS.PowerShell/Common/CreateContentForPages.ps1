function DoPopulateDataForPages([string]$siteUrl, $metadataFile)
{
    Start-SPAssignment -Global    # This cmdlet takes care of the disposable objects  

	$siteData = GetXmlStructure($metadataFile)

	$url = $siteUrl

    if($siteData.Web.RootWeb.Data.Pages.Page -ne $null) {	
        $spWeb = Get-SPWeb $siteUrl
        try{   
		    PopulateWebparts $spWeb $siteUrl $siteData.Web.RootWeb
        }
        finally{
            $spWeb.Dispose()
        }		
	}
    
    
    if($siteData.Web.SubWeb -ne $null) {
       $siteData.Web.SubWeb | foreach{
            $subSiteUrl = $url + $_.Url
            $spSubWeb = Get-SPWeb $subSiteUrl
            try{	
                PopulateWebparts $spSubWeb $subSiteUrl $_
            }
            finally{
                $spSubWeb.Dispose()
            }
       }
    } 
       	
	Stop-SPAssignment -Global
}


function PopulateWebparts($spSubWeb, $subSiteUrl, $data)
{
    Write-Host "Populating pages for site $($subSiteUrl) ..." -ForegroundColor "Yellow"
    if($data.Data.Pages -ne $null) {
        $data.Data.Pages | foreach{
            $libName = $_.LibraryName
            if($libName -ne $null -and $libName -ne ""){
                $lib = GetList $spSubWeb $libName
                if($libName -eq "Page"){
	                if($lib -ne $null -and $_.Page -ne $null){
                        $_.Page | foreach{
                            $pageData = $_
                            $pageFileName = $_.FileName
                            Write-Host "Configuring page $($_.FileName) in site $($spSubWeb.Url) ..." -ForegroundColor "Yellow"
                            if($pageData.AllUsersWebPart -ne $null){
				                $pageData.AllUsersWebPart | foreach {
					                ImportWebParts $spSubWeb $pageFileName $_ $libName
					            }
				            } 
                            if($_.WelcomePage -ne $null -and $_.WelcomePage -eq $true) { 
                                $pageUrl = $subSiteUrl + "/" + $libName + "/" + $pageFileName
                                SetNormalWelcomePage $spSubWeb $pageUrl
                            }
                        }                        
                    }
                }
                else{
                    if($lib -ne $null -and $_.Page -ne $null){
                        $_.Page | foreach{
                            $pageData = $_
                            $pageFileUrl = $_.PageUrl
                            Write-Host "Configuring page $($_.PageUrl) in site $($spSubWeb.Url) ..." -ForegroundColor "Yellow"
                            if($pageData.AllUsersWebPart -ne $null){
				                $pageData.AllUsersWebPart | foreach {				                            
                                    ImportWebParts $spSubWeb $null $_ $libName $pageFileUrl
					            }
				            } 
                        }                        
                    }
                }
            }
            else{
                $_.Page | foreach{
                    Write-Host "Configuring publishing page $($_.FileName) in site $($spSubWeb.Url) ..." -ForegroundColor "Yellow"
		            if($_.Delete -eq $true) {
			            DeletePage $spSubWeb $_.FileName
			        }
			        else  {
                        if($_.Delete -eq "ReCreate"){
                            DeletePage $spSubWeb $_.FileName
                        }
                        if($_.ToUpload -eq $null -or $_.ToUpload -eq ""){
                            AddOrUpdatePage $spSubWeb $_
                            if($_.WelcomePage -ne $null -and $_.WelcomePage -eq $true) { 
                                SetWelcomePage $spSubWeb $_.FileName 
                            }
                        }
                        elseif($_.ToUpload -eq $true){
                            $pageLayoutLocalDir = $gPageLayoutsFolderPath + "\SubSites"

                            if(Test-Path ($pageLayoutLocalDir + "\" + $_.FileName)){
                                $pubWeb = [Microsoft.SharePoint.Publishing.PublishingWeb]::GetPublishingWeb($spSubWeb)
                                $page = GetPublishingPage $pubWeb $_.FileName
			                    if($page -ne $null)
			                    {							
    				                Write-Host "Page $($pageLayoutLocalDir + "\" + $_.FileName) already exists!" -ForegroundColor "Yellow" 
                                    return
			                    }

                                $fileStream = [IO.File]::OpenRead($pageLayoutLocalDir + "\" + $_.FileName) 
                                $pagesList = $spSubWeb.Lists["Pages"]
                                if($pagesList -ne $null){
                                    $spFile = $pagesList.RootFolder.files.Add($_.FileName, $fileStream, $true)
                                    $pageData = $_
                                    $pageFileName = $_.FileName
                                    if($pageData.AllUsersWebPart -ne $null){
				                        $pageData.AllUsersWebPart | foreach {				                            
                                            ImportWebParts $spSubWeb $pageFileName $_ $pagesList.Title
					                    }
				                    }
                                               
                                    $page = GetPublishingPage $pubWeb $_.FileName
                                    if($page -ne $null){
                                        if($page.ListItem.File.CheckOutStatus -ne "None" )
                                        {
	                                        $page.CheckIn("Checked in by PowerShell script")
                                        }

                                        $page.listItem.File.Publish("Published by PowerShell script")
                                    }
                                }
                            }
                            else{
                                Write-Host "Cound not find $($pageLayoutLocalDir + "\" + $_.Search.aspx)" -ForegroundColor "Yellow"
                            }
                        }
			        }
                }  
            }
        } 
    }
}


function SetNormalWelcomePage($spWeb, [string]$pageUrl)
{
  $page = $spWeb.GetFile($pageUrl)
  if($page -eq $null) {
    Write-Error "$pageUrl does not exist in $($spWeb.Url)"
	return
  }
  $oFolder = $spWeb.RootFolder;
  $oFolder.WelcomePage = $page.Url
  $oFolder.Update();
}

function DoPopulateData([string]$siteUrl, $metadataFile)
{
    Start-SPAssignment -Global    # This cmdlet takes care of the disposable objects
	

	$siteData = GetXmlStructure($metadataFile)
	
	$url = $siteUrl
	$spWeb = Get-SPWeb $url	
    

	#adding page data		
	if($siteData.Web.Data.Pages.Page -ne $null) {	    
		$siteData.Web.Data.Pages.Page | foreach{
		    Write-Host "Configuring publishing page $($_.FileName) in site $($spWeb.Url) ..." -ForegroundColor "Yellow"
		    if($_.Delete -eq $true) {
			  DeletePage $spWeb $_.FileName
			}
			else  {
                if($_.Delete -eq "ReCreate"){
                    DeletePage $spWeb $_.FileName
                }
                AddOrUpdatePage $spWeb $_
                if($_.WelcomePage -ne $null -and $_.WelcomePage -eq $true) { 
                    SetWelcomePage $spWeb $_.FileName 
                }
			}
		}		
	}
	
	Stop-SPAssignment -Global
}

function SetWelcomePage($spWeb, [string]$fileName)
{
  $pubWeb = [Microsoft.SharePoint.Publishing.PublishingWeb]::GetPublishingWeb($spWeb)		
  if($pubWeb -eq $null) {
    Write-Error "$($spWeb.Url) is not a publishing web"
	return	
  }
  $page = GetPublishingPage $pubWeb $fileName
  if($page -eq $null) {
    Write-Error "$fileName does not exist in $($spWeb.Url)"
	return
  }
  $pubWeb.DefaultPage = $page.ListItem.File
  $pubWeb.Update()
}

function DeletePage($spWeb, [string]$fileName)
{
  $pubWeb = [Microsoft.SharePoint.Publishing.PublishingWeb]::GetPublishingWeb($spWeb)		
  if($pubWeb -eq $null) {
    Write-Error "$($spWeb.Url) is not a publishing web"
	return	
  }
  $page = GetPublishingPage $pubWeb $fileName
  if($page -eq $null) {    
	return
  }
  Write-Host "Deleting $fileName in $($spWeb.Url)"
  $page.ListItem.Delete()
}

function GetList($spWeb,[string]$title)
{
	$list = $spWeb.Lists[$title]
	if($list -ne $null)
	{
	  return $list	  
	}
	return $null
}

function EnableMajorAndMinorVersioning($spList)
{
	if($spList -eq $null) { 
		Write-Host "Invalid list"
		return
	}
	
    if(!$spList.EnableVersioning) { $spList.EnableVersioning = $true }
    if(!$spList.EnableMinorVersions) { $spList.EnableMinorVersions = $true }
	$spList.Update()
}

function ConfigureWorkflows($spList, $listData)
{             
    if($spList -eq $null) {
	  Write-Host "Invalid list"
	  return
	}
	
	if($listData.RemoveWorkflows){	  
	  $allWfs = @()
	  $spList.WorkflowAssociations | foreach { $allWfs += $_.Name }				
      $allWfs | foreach { 					
		$wa = $spList.WorkflowAssociations.GetAssociationByName($_, [System.Globalization.CultureInfo]::CurrentCulture)    
		Write-Host "Removing workflow $_ from $($spList.Title)" 
		$spList.WorkflowAssociations.Remove($wa)
     }
	} 
}

function ConfigureListSettings($spList, $listData)
{
	if($spList -eq $null) { 
		Write-Host "Invalid list"
		return
	}
	
	$updated = $false
        
        if($spList.ExcludeFromOfflineClient -ne (-not $syncToSharePointWorkspace)) {
          $spList.ExcludeFromOfflineClient = (-not $syncToSharePointWorkspace)
	  $updated = $true
        } 
		
	if($listData.ContentApproval -ne $null) {
	  $spList.EnableModeration = ($listData.ContentApproval -eq $true)
	  $updated = $true
	}
	if($listData.EnableVersioning -ne $null) {
	  $spList.EnableVersioning = $listData.EnableVersioning
	  $updated = $true
	}
	if($listData.EnableMinorVersions -ne $null) {
 	  $spList.EnableMinorVersions = $listData.EnableMinorVersions
	  $updated = $true
	}
	if($listData.DraftItemSecurity -ne $null) {
      $spList.DraftVersionVisibility = $listData.DraftItemSecurity
	  $updated = $true
	}
	if($listData.ForceCheckout -ne $null) {
	  $spList.ForceCheckout = $listData.ForceCheckout
	  $updated = $true
	}
	if($listData.ContentTypesEnabled -ne $null) {
	  $spList.ContentTypesEnabled = $listData.ContentTypesEnabled 
	  $updated = $true
	}
		
	if($updated) {	          
	  $spList.Update()	
	}		
}

function AddList($spWeb,$listData)
{
	if($listData -eq $null) { return }
	
    $title = $listData.Title
	$listTemplateName = $listData.TemplateName
	
    $list = GetList $spWeb $title
	if($list -ne $null)
	{
		Write-Host "List $title already exists"
		return 
	}
	Write-Host "Creating list $title in $($spWeb.Url) ..."
	$listTemplate = $spWeb.ListTemplates[$listTemplateName]
	if($listTemplate -eq $null)
	{
	    Write-Host "Invalid list template $listTemplateName"
		return 
	}
	$description = $listData.Description
	$spWeb.Lists.Add($title,$description,$listTemplate)			
}

function ConfigureViews($spList,$listData)
{    
	if($listData -eq $null) { return }
	
	if($listData.View -ne $null) {	    
		$listData.View | foreach {				        
				$view = $spList.Views[$_.Title]
				if($view -eq $null) { # add a new view by cloning the default view and then adjusting settings
				  Write-Host "Adding new view $($_.Title) ..."
				  $viewFields = New-Object System.Collections.Specialized.StringCollection
				  if($_.Title -like "My submissions") { # my submissions view is special because SP deletes/(re-)creates it everytime Content Approval is turned off/on
				    # create a view with Title="my-sub" so that the view will have url = my-sub.aspx				    
					@("DocIcon", "LinkFilename", "Modified", "Editor", "_ModerationStatus", "_ModerationComments") | foreach { $viewFields.Add($_) > $null}					
				    $view = $spList.Views.Add("my-sub", $viewFields, $_.Query.InnerText, 30, $true, $false) 					
					$theViewID = $view.ID
					# SP will remove '-' in file name so we need to fix that
					$title = $_.Title
					$default = $_.Default
					$spList.RootFolder.SubFolders["Forms"].Files | foreach {
					  if($_.ServerRelativeUrl.Contains("mysub.aspx")) {					    
					    $url = $_.ServerRelativeUrl.Replace("mysub.aspx", "my-sub.aspx")
						$_.CopyTo($url, $true)
						# removing the other view
						$spList.Views.Delete($theViewID)
						# now setting the new view's title and default status
						$view = $spList.Views["my-sub"]
						if($view -ne $null) {
						  $view.Title = $title
						  $view.DefaultView = $default
						  $view.Update()
						}						
					  }
					}
				  } else {
				  $defaultView = $spList.DefaultView                                  
				  if($_.ViewFields -ne $null) {
				    $_.ViewFields.Split(',') | foreach { $viewFields.Add($_.Trim()) > $null }
				  } else { 
                                      $defaultView.ViewFields | foreach { $viewFields.Add($_) > $null }
                                  }
				  if($_.Query -ne $null) {
				    $query = $_.Query.InnerText
				  } else { $query = $defaultView.Query }
				  if($_.RowLimit -ne $null) {
				    $rowLimit = $_.RowLimit
				  } else { $rowLimit = $defaultView.RowLimit }
				  if($_.Paged -ne $null) {
				    $paged = $_.Paged
				  } else { $paged = $defaultView.Paged }				  
				  $view = $spList.Views.Add($_.Title, $viewFields, $query, $rowLimit, $paged, $_.Default) 
				  }
				} else { # view exists; updating query conditions
				  if($view.Query -ne $_.Query.InnerText) {
				    Write-Host "Updating view $($_.Title) ..."
					$view.Query = $_.Query.InnerText
					$view.Update()
				  }
				}		 	    				
		}	
	}	    	
}

function GetAllowedContentTypes($listData)
{
    $contenttypes = @()
	$listData.AllowedContentTypes.Split(',') | foreach {
	  $contenttypes += $_.Trim()	  
	}
	return $contenttypes
}

function ConfigureContentTypes($spWeb,$listData)
{
    if(($listData.AllowedContentTypes -eq $null) -or ($listData.AllowedContentTypes -eq "")) { return }
    $contenttypes = GetAllowedContentTypes $listData
		
	SetAvailableContenttypes $spWeb $listData.Title $contenttypes
}

function ConfigureContentTypesForPages($spWeb,$listData)
{
    if(($listData.AllowedContentTypes -eq $null) -or ($listData.AllowedContentTypes -eq "")) { return }
    $contenttypes = GetAllowedContentTypes $listData
	
	$pubWeb = [Microsoft.SharePoint.Publishing.PublishingWeb]::GetPublishingWeb($spWeb)				
	SetAvailableContenttypes $spWeb $pubWeb.PagesListName $contenttypes
	
	$deletePageLayouts = @()
	if(-not(($listData.DeletePageLayouts -eq $null) -or ($listData.DeletePageLayouts -eq ""))) {
	  $listData.DeletePageLayouts.Split(',') | foreach { $deletePageLayouts += $_.Trim() }
	}
	
	#Configuring allowed page layouts, associated with the content types
	$rootWeb = [Microsoft.SharePoint.Publishing.PublishingWeb]::GetPublishingWeb($spWeb.Site.RootWeb)   
	$allowedLayouts = $rootWeb.GetAvailablePageLayouts() | Where-Object {($contenttypes -contains $_.AssociatedContentType.Name) -and (-not ($deletePageLayouts -contains $_.Title))}	   
	   
    $pubWeb.SetAvailablePageLayouts($allowedLayouts, $false)   
    $pubWeb.Update()
}


function ConfigurePageLayouts($spWeb,$listData, [array]$contenttypes)
{
    if(($listData.AllowedPageLayouts -eq $null) -or ($listData.AllowedPageLayouts -eq "")) { return }												
   
	$layouts = @()				  
    $listData.AllowedPageLayouts.Split(',') | foreach { $layouts += $_.Trim() }
    if($layouts.Count -gt 0) {
		SetAvailablePageLayouts $spWeb $layouts 
    }				
}

function GetPublishingPage([Microsoft.SharePoint.Publishing.PublishingWeb]$pubWeb, [string]$pageFileName)
{
	if($pubWeb -ne $null)
	{
		return $pubWeb.GetPublishingPages() | Where-Object {$_.Name -eq $pageFileName}
	}
	Write-Host "Invalid web"
	return $null
}

function AddPublishingPage([Microsoft.SharePoint.Publishing.PublishingWeb]$pubWeb, [string]$pageLayoutTitle, [string]$pageFileName)
{
	if($pubWeb -ne $null)
	{
		$pageLayout = $pubWeb.GetAvailablePageLayouts() | Where-Object {$_.Title -eq $pageLayoutTitle }	
		if($pageLayout -ne $null)
		{
			return $pubWeb.GetPublishingPages().Add($pageFileName, $pageLayout)				
		}
	}
	Write-Host "Invalid web or pagelayout $pageLayoutTitle doesn't exist"
	return $null
}

function SetFieldValue($pageItem, $fieldName, $value)
{
   $fieldType = $pageItem.Fields[$fieldName].TypeAsString
   if(($fieldType -eq "TaxonomyFieldType") -or ($fieldType -eq "TaxonomyFieldTypeMulti"))
					{
						$taxonomyField = [Microsoft.SharePoint.Taxonomy.TaxonomyField]$pageItem.Fields[$fieldName]						
						
						if($value.Contains(";")) {
						
						$values = @()
						$value.Split(';') | foreach {						  
						  $values += $_.Trim()
						}
												
						$spSite = $taxonomyField.ParentList.ParentWeb.Site
                        $session = New-Object Microsoft.SharePoint.Taxonomy.TaxonomySession($spSite)
                        $termStore = $session.TermStores[$taxonomyField.SspId]
                        $termSet = $termStore.GetTermSet($taxonomyField.TermSetId)
                        [Microsoft.SharePoint.Taxonomy.TaxonomyFieldValueCollection]$fieldValues = new-object Microsoft.SharePoint.Taxonomy.TaxonomyFieldValueCollection($taxonomyField)
    
  $termSet.GetAllTerms() | foreach {    
    if ($values -contains $_.Name) {
            [Microsoft.SharePoint.Taxonomy.TaxonomyFieldValue] $fieldValue = New-Object Microsoft.SharePoint.Taxonomy.TaxonomyFieldValue($taxonomyField);
            $fieldValue.TermGuid = $_.Id.ToString()
            $fieldValue.Label = $_.Name;
            $fieldValues.Add($fieldValue)
     }
    }  
						$taxonomyField.SetFieldValue($pageItem, [Microsoft.SharePoint.Taxonomy.TaxonomyFieldValueCollection]$fieldValues);
						}
						else {
						$term = FindTerm $pageItem.Web.Site $gManagedMetadataServiceTermStore $taxonomyField.TermSetId $value
						if($term -ne $null) {
							$taxonomyField.SetFieldValue($pageItem,$term)
						}
						else
						{
							Write-Warning "Invalid term $value for $fieldName"
						}	
						}
					}
					elseif($fieldType -eq "Image")
					{
					    $value = ExpandURI $value $true
					    $newImage = new-object Microsoft.SharePoint.Publishing.Fields.ImageFieldValue
                        $newImage.ImageUrl = $value
						$pageItem[$fieldName]=$newImage
					}
					elseif($fieldType -eq "Boolean")
					{
					    if($value -eq "Yes") {
						  $pageItem[$fieldName]=$true
						} elseif($value -eq "No") {
						  $pageItem[$fieldName]=$false
						} else {
						  Write-Warning "Invalid value: $value for $fieldName"
						}
					}
					else
					{
					    $value = ExpandURI $value $true
					    $pageItem[$fieldName]=$value					
					}  
}

function AddXsltListViewWebPart($spWeb, [string]$pageFileName, [string]$pageFileUrl, $ZoneIndex, $data){    
	
    $listName = $data.ListName
    $ViewName = $data.ViewName
    $ZoneID = $data.WebPartZoneID

    if($wpMgr -eq $null){
        if($pageFileName -ne $null -and $pageFileName -ne ""){ 		
	        #$pubWeb = [Microsoft.SharePoint.Publishing.PublishingWeb]::GetPublishingWeb($spWeb)									   		
	        #$wpMgr = $spWeb.GetLimitedWebPartManager("$($pubWeb.PagesListName)/$pageFileName", [System.Web.UI.WebControls.WebParts.PersonalizationScope]::Shared) 
            $wpMgr = $spWeb.GetLimitedWebPartManager("$pagesListName/$pageFileName", [System.Web.UI.WebControls.WebParts.PersonalizationScope]::Shared) 
        } 
        elseif($pageFileUrl -ne $null -and $pageFileUrl -ne ""){
            $wpMgr = $spWeb.GetLimitedWebPartManager($pageFileUrl, [System.Web.UI.WebControls.WebParts.PersonalizationScope]::Shared)
        } 
    }  
	
    RemoveWebpart $wpMgr $ZoneID $ZoneIndex

    $wp = FindWebpart $wpMgr $ZoneID $ZoneIndex

	if($wp -eq $null)
	{
        $list = $spWeb.Lists[$listName]

        $ListViewWebPart = New-Object Microsoft.SharePoint.WebPartPages.XsltListViewWebPart
        $ListViewWebPart.ListName = ($list.ID).ToString("B").ToUpper()
        $ListViewWebPart.ViewGuid = $list.Views[$ViewName].ID.ToString("B")
        $ListViewWebPart.ZoneID = $ZoneID

        if($data.ChromeType -eq $null){ 
            $ListViewWebPart.ChromeType = "Default"
        }
        else{
            $ListViewWebPart.ChromeType = $data.ChromeType
        }
        if($data.Title -ne $null){ 
            $ListViewWebPart.Title  = $data.Title   
        }   
		if($data.TitleUrl -ne $null){ 
            $ListViewWebPart.TitleUrl  = $data.TitleUrl 
        }  
		else{
			$ListViewWebPart.TitleUrl = $list.DefaultViewUrl
		}
        $ListViewWebPart.WebId = $list.ParentWeb.ID 
        $ListViewWebPart.InplaceSearchEnabled = $false         
        $wpMgr.AddWebPart($ListViewWebPart, $ZoneID, $ZoneIndex)

        UpdateListViewWebpart $wpMgr $ZoneID $ZoneIndex $data
	}
}


function UpdateListViewWebpart($wpMgr, [string]$ZoneID, [int]$ZoneIndex, $data)
{
    if ($data.ViewFields -or $data.ViewQuery -or $data.RowLimit) {
        $wp = FindWebpart $wpMgr $ZoneID $ZoneIndex	
	    if($wp -ne $null)
	    {	
            if ($data.ViewFields){
                $wp.View.ViewFields.DeleteAll()                      
                $data.ViewFields -split ";" | ForEach {
                    $wp.View.ViewFields.Add($_)
                }
            }
            if ($data.ViewQuery){
                $wp.View.Query = $data.ViewQuery
            }
            if ($data.RowLimit){
                $wp.View.RowLimit = $data.RowLimit
            }
            $wp.View.Update()
            #$wpMgr.SaveChanges($wp)
	    }
    }	
    if($data.ToolbarType -ne $null){ 
        $wp = FindWebpart $wpMgr $ZoneID $ZoneIndex	
        if($wp -ne $null)
	    {	
            $nodeProp = $wp.View.GetType().GetProperty("Node", [Reflection.BindingFlags] "NonPublic, Instance");
            [System.XML.XMLNode]$node = $nodeProp.GetValue($wp.View, $null);
            [System.XML.XMLNode]$toolbarNode = $node.SelectSingleNode("Toolbar");
            $toolbarNode.Type = "None" # or Standard, Full, Freeform           
            $wp.View.Update();
	    }
    }
}

function AddOrUpdatePage($spWeb, $pageData)
{        
    if($pageData -eq $null) { return }
	
	$pageLayoutTitle = $pageData.PageLayout
	$pageFileName = $pageData.FileName
	
	#try
	#{		 
		$pubWeb = [Microsoft.SharePoint.Publishing.PublishingWeb]::GetPublishingWeb($spWeb)		
		if($pubWeb -ne $null)
		{
		    $page = GetPublishingPage $pubWeb $pageFileName
			# add a new page if page doesn't exist
			if($page -eq $null)
			{							
				$page = AddPublishingPage $pubWeb $pageLayoutTitle $pageFileName
			}
			elseif($page.ListItem.File.CheckOutStatus -eq "None" )
			{
				$page.Checkout()
			}
            elseif($page.ListItem.File.CheckedOutByUser.ID -ne $spWeb.CurrentUser.ID) #current user should be System account (ID = 1073741823)
            {
                $page.ListItem.File.UndoCheckOut() 
                $page.ListItem.File.Update()
                $page.Checkout()
            }
			if($page -ne $null)
			{
				$pageItem = $page.ListItem		
				if($pageData.Field -ne $null) {
			 	  foreach ($field in $pageData.Field){
				    SetFieldValue $pageItem $field.Name $field.InnerText
				  }
				  $page.Update()
				}
				
				#configuring web parts
				if($pageData.AllUsersWebPart -ne $null)
				{
				    $pageData.AllUsersWebPart | foreach {
					  ImportWebParts $spWeb $pageFileName $_
					}
				}
				
                if($page.ListItem.File.CheckOutStatus -ne "None" )
                {
				    $page.CheckIn("Checked in by PowerShell script")
                }

				$page.listItem.File.Publish("Published by PowerShell script")				
			}
                        # try to approve page if necessary
			# gain access to the page again
			$page=$pubWeb.GetPublishingPages() | Where-Object {$_.Name -eq $pageFileName}
			if($page -ne $null)
			{
                           if($page.listItem.ParentList.EnableModeration) {
				$page.listItem.File.Approve("Approved by PowerShell script")
                           }
			}
		}
}

function ImportWebParts($spWeb, $pageFileName, $webpartData, $pagesListName, $pageFileUrl)
{
    trap {
        Write-Host "$($_.Exception.Message)" -ForegroundColor "Red"
        continue
    }

	if($webpartData -eq $null) { return }

    Write-Host "Importing Web Parts..." -foregroundcolor "Yellow"  
	
    #$pubWeb = [Microsoft.SharePoint.Publishing.PublishingWeb]::GetPublishingWeb($spWeb)	
    if($pagesListName -eq $null -or $pagesListName -eq ""){	
        $pagesListName = $pubWeb.PagesListName
    }
			
    
    if($pageFileName -ne $null){ 		
	    $wpMgr = $spWeb.GetLimitedWebPartManager("$pagesListName/$pageFileName", [System.Web.UI.WebControls.WebParts.PersonalizationScope]::Shared) 
    } 
    elseif($pageFileUrl -ne $null){
        $wpMgr = $spWeb.GetLimitedWebPartManager($pageFileUrl, [System.Web.UI.WebControls.WebParts.PersonalizationScope]::Shared)
    }

    if($wpMgr -eq $null) {
        return
    }

    if($webpartData.ClearZoneID -ne $null){
        $webpartData.ClearZoneID -split ";" | ForEach {
            Write-Host "`tRemoving all webparts from $($_)..." 
            if($wpMgr.WebParts.Count -gt 0){
                for($i=$wpMgr.WebParts.Count - 1; $i -ge 0; $i--) {	  	  	  
	                #Write-Host "`tDeleting web part $($webpartData.ClearZoneID)"
                    if($_ -eq $wpMgr.GetZoneID($wpMgr.WebParts[$i]))
                    {
	                    $wpMgr.DeleteWebPart($wpMgr.WebParts[$i])
                    }
	            }
            }
        }
    }

				
	foreach ($webPartDefinition in $webpartData.WebPartDefinition) {   
        if($webPartDefinition.Type -eq "ReportViewerWebPart"){
            Write-Host "`tImporting report viewer web part to $($webPartDefinition.WebPartZoneID) $($webPartDefinition.WebPartOrder)"
            $webAllowUnsafeUpdate = $spWeb.AllowUnsafeUpdates;
            try
            {
                [Reflection.Assembly]::LoadWithPartialName("Microsoft.ReportingServices.SharePoint.UI.WebParts")
                [Reflection.Assembly]::LoadWithPartialName("System.Web")
                [Reflection.Assembly]::LoadWithPartialName("System.IO")
                [Reflection.Assembly]::LoadWithPartialName("System.Collections.Generic")
                [System.Web.HttpRequest] $request = new-object System.Web.HttpRequest("",$spWeb.Url,"")
                $response = new-object System.Web.HttpResponse([System.IO.TextWriter]::Null);
                [System.Web.HttpContext]::Current = new-object System.Web.HttpContext($request,$response)
                [System.Web.HttpContext]::Current.Request.Browser = new-object System.Web.HttpBrowserCapabilities
                [System.Web.HttpContext]::Current.Request.Browser.Capabilities = new-object 'System.Collections.Generic.Dictionary[string,string]'
                [System.Web.HttpContext]::Current.Request.Browser.Capabilities["type"] = "IE7";
                [System.Web.HttpContext]::Current.Request.Browser.Capabilities["majorversion"] = "7";
                [System.Web.HttpContext]::Current.Request.Browser.Capabilities["minorversion"] = "0"
                [System.Web.HttpContext]::Current.Items["HttpHandlerSPWeb"] = [Microsoft.SharePoint.SPWeb]$spWeb;
                $wp = new-object Microsoft.ReportingServices.SharePoint.UI.WebParts.ReportViewerWebPart
                $spWeb.AllowUnsafeUpdates = $true
                $page = $spWeb.GetFile("$pagesListName/$pageFileName")
                $wpm = $page.GetLimitedWebPartManager([System.Web.UI.WebControls.WebParts.PersonalizationScope]::Shared)
                $wp.ReportPath = $webPartDefinition.ReportPath
                $wp.ChromeType = "None"
                $wp.Height = ""
                [int]$zoneIndex = $webPartDefinition.WebPartOrder -as [int]
                RemoveWebpart $wpMgr $webPartDefinition.WebPartZoneID $zoneIndex
                $wpm.AddWebPart($wp,$webPartDefinition.WebPartZoneID, $zoneIndex)
                $wpm.SaveChanges($wp)
            }
            finally
            {
                $spWeb.AllowUnsafeUpdates = $webAllowUnsafeUpdate
            }

        }
        elseif ($webPartDefinition.Type -eq "XsltListViewWebPart"){
            $zoneIndex = 0 + $webPartDefinition.WebPartOrder
		    AddXsltListViewWebPart $spWeb $pageFileName $pageFileUrl $zoneIndex $webPartDefinition
        }
        ##elseif($webPartDefinition.Type -eq "DateFilterWebPart"){
        ##    Write-Host "`tImporting Date Filter web part to $($webPartDefinition.WebPartZoneID) $($webPartDefinition.WebPartOrder)"
        ##    $wp = New-Object Microsoft.SharePoint.Portal.WebControls.QueryStringFilterWebPart;
        ##    #$wp.FilterName="<Filter Name>";
        ##    #$wp.QueryStringParameterName = "<query string parameter name>"; 
        ##    #$wp.ChromeType = [System.Web.UI.WebControls.WebParts.PartChromeType]::None; 
        ##
        ##    [int]$zoneIndex = $webPartDefinition.WebPartOrder -as [int]
        ##    RemoveWebpart $wpMgr $webPartDefinition.WebPartZoneID $zoneIndex
        ##    $wpMgr.AddWebPart($wp,$webPartDefinition.WebPartZoneID, $zoneIndex)
        ##    $wpMgr.SaveChanges($wp)
        ##}
        else{
		    $err = $null  
		    $wpstr = ExpandURI $webPartDefinition.InnerText $true
		    $wpstr = ExpandTokens $wpstr
		    $sr = New-Object System.IO.StringReader($wpstr)            
		    $xtr = New-Object System.Xml.XmlTextReader($sr);
			
		    [int]$zoneIndex = $webPartDefinition.WebPartOrder -as [int]
            if($webPartDefinition.Hide -eq $null -or $webPartDefinition.Hide -eq "" -or $webPartDefinition.Hide -eq $false){
		        RemoveWebpart $wpMgr $webPartDefinition.WebPartZoneID $zoneIndex		
		        Write-Host "`tImporting web part to $($webPartDefinition.WebPartZoneID) $zoneIndex"
		        $wp = $wpMgr.ImportWebPart($xtr, [ref]$err)             
			
		        $wpMgr.AddWebPart($wp, $webPartDefinition.WebPartZoneID, $zoneIndex)  
                if($webPartDefinition.Type -eq "RefinementScriptWebPart"){
                    $swp = FindWebpart $wpMgr $webPartDefinition.WebPartZoneID $zoneIndex	
	                if($swp -ne $null)
	                {
                        $j = $swp.SelectedRefinementControlsJson | ConvertFrom-Json
                        $j.refinerConfigurations | % { if ($_.propertyName -eq 'DisplayAuthor') { 
                            $_.propertyName = 'RefinableString90000'; 
                        }}
                    
                        $swp.SelectedRefinementControlsJson = ConvertTo-Json $j -Compress
                        $wpMgr.SaveChanges($swp)                     
                    }
                } 
                elseif($webPartDefinition.Type -eq "ResultScriptWebPart"){  
                    $swp = FindWebpart $wpMgr $webPartDefinition.WebPartZoneID $zoneIndex	
	                if($swp -ne $null)
	                {
                        $j = $swp.DataProviderJSON | ConvertFrom-Json
                        $j.QueryTemplate = "{searchboxquery} Author={User.Name}"
                        $swp.DataProviderJSON = ConvertTo-Json $j -Compress
                        $wpMgr.SaveChanges($swp)                  
                    }
                }   
            } 
            else{
                HideWebpart $wpMgr $webPartDefinition.WebPartZoneID $zoneIndex
            } 
		    Write-Host "." -NoNewline 
        }       
	}           	
	Write-Host "`nWeb Parts are successfully imported"   -ForegroundColor "Green" 	     	   
}

function HideWebpart($wpMgr, [string]$ZoneID, [int]$ZoneIndex)
{
    $wp = FindWebpart $wpMgr $ZoneID $ZoneIndex	
	if($wp -ne $null)
	{	
	    $wp.Hidden = $true
        $wpMgr.SaveChanges($wp)
	}	
}

function RemoveWebpart($wpMgr, [string]$ZoneID, [int]$ZoneIndex)
{
    $wp = FindWebpart $wpMgr $ZoneID $ZoneIndex	
	if($wp -ne $null)
	{	
	    Write-Host "`tDeleting web part $ZoneID $ZoneIndex"
	    $wpMgr.DeleteWebPart($wp)
	}	
}

function FindWebpart($wpMgr, [string]$ZoneID, [int]$ZoneIndex)
{    
	for($i=0; $i -lt $wpMgr.WebParts.Count; $i++) {	  	 
      
 	  
	  if(($wpMgr.WebParts[$i].ZoneIndex -eq $ZoneIndex) -and ($ZoneID -eq $wpMgr.GetZoneID($wpMgr.WebParts[$i]))){	    		
	    return $wpMgr.WebParts[$i]		
	  }
	}
	return $null
}



function GeneratePageData([array]$files, [array]$zones, [array]$indexes, [string]$pageLayout, [string]$url, [string]$pageFileName, [string]$path, [array]$valueToBeReplaced=$null, [array]$valueToReplaceWith=$null)
{
$subsiteUrl = ReplaceServerRelativeUrlWithToken $url
$pageData = [xml]@"
<Web Url="$subsiteUrl">
  <Data>
    <Pages>
      <Page PageLayout = "$pageLayout" FileName="$pageFileName">        
      </Page>
    </Pages>
  </Data>
</Web>
"@

$serverRelativeUrl = GetServerRelativeUrl $gSiteCollectionUrl

for($i=0; $i -lt $files.Count; $i++) {
  [string]$str = Get-Content "$path\$($files[$i])"    
  # case-insensitive replacement
  $str = [System.Text.RegularExpressions.Regex]::Replace($str, $serverRelativeUrl, "~SiteCollection", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

  if($valueToBeReplaced.Count -gt 0) {
    for($j=0; $j -lt $valueToBeReplaced.Count; $j++) {
      # case-sensitive replacement
      $str = $str.Replace($valueToBeReplaced[$j], $valueToReplaceWith[$j])
    }
  }
  
  $xmlElt = $pageData.CreateElement("AllUsersWebPart")
  $xmlText = $pageData.CreateCDataSection($str)
  $node = $xmlElt.AppendChild($xmlText)
  
  $xmlAtt = $pageData.CreateAttribute("WebPartZoneID")
  $xmlAtt.Value = $zones[$i]
  $att = $xmlElt.Attributes.Append($xmlAtt)
  
  $xmlAtt2 = $pageData.CreateAttribute("WebPartOrder")
  $xmlAtt2.Value = $indexes[$i]
  $att = $xmlElt.Attributes.Append($xmlAtt2)
  
  $node = $pageData.Web.Data.Pages.Page.AppendChild($xmlElt)  
}

$pageData.Save("$path\$pageFileName.xml")
}

function DoUpload([string]$url, [string]$listName, [string]$fullFilePath, [bool]$overwrite=$true)
{		
	#Upload data here
	$uploaded = Upload $spList $fullFilePath $overwrite
	CheckInPublishApproveListItem $uploaded.Item
}

function CheckInPublishApproveListItem($uploaded)
{    
    if($uploaded.CheckOutStatus -ne 'None'){
	    $listItem = $uploaded.Item
		$listItem.Update()	
		$id = $listItem.ID
	
		$uploaded.CheckIn("checked in by scripts")
		$uploaded.Publish("published by scripts")
	
		#regain the list item to avoid concurrency issues
		$theListItem = $spList.GetItemByID($id)
                if($spList.EnableModeration) {
		  $theListItem.File.Approve("approve by scripts")		
                }
	}
}

function Upload([string]$url, [string]$listName, [string]$fullFilePath, [bool]$overwrite=$true)
{
	$file = Get-ChildItem $fullFilePath
	if($file -eq $null)
	{
		Write-Host "Invalid file path $fullFilePath"
		return
	}
	$fileName = $file.Name

	$spWeb = Get-SPWeb $url 
	$spList = $spWeb.Lists[$listName]
	if($spList -eq $null)
	{
		Write-Host "Invalid list name $listName"
		return
	}		
	$spFolder = $spList.RootFolder	
	$spFileCollection = $spFolder.Files		
    $uploaded = $spFileCollection.Add("$($spFolder.Url)/$fileName",$file.OpenRead(),$overwrite)
	
	$listItem = $uploaded.Item	
	$listItem.Update()	
	$id = $listItem.ID

	$uploaded.CheckIn("checked in by scripts")
	$uploaded.Publish("published by scripts")
	
	#regain the list item to avoid concurrency issues
	$theListItem = $spList.GetItemByID($id)
        if($spList.EnableModeration) {
	  $theListItem.File.Approve("approve by scripts") 
        }
}

#limit content types in a list; remove all content types not listed in $contenttypes
# $contenttypes is an array of content type names
function DoSetAvailableContenttypes([string]$url, [string]$listName, $contenttypes)
{
   $spWeb = Get-SPWeb $url   
   SetAvailableContenttypes $spWeb $listName $contenttypes
}

function SetAvailableContenttypes($spWeb, [string]$listName, $contenttypes)
{  
   $list = GetList $spWeb $listName
   if($list -eq $null) {
     Write-Error "Invalid list name $listName in $($spWeb.Url)"
	 return
   }  
   if($contenttypes.Count -eq 0) {
     Write-Error "List of content types must not be empty"
	 return
   }
   $ctToRemove = @()
   $list.ContentTypes | foreach {
     if(!(($contenttypes -contains $_.Name) -or ($_.Name -eq "Folder")))
	 {
	   Write-Host "Removing content type $($_.Name) from list $($list.Title)"
	   $ctToRemove += $_.Id
	 }
   }
   if($ctToRemove.Count -gt 0) {
     $ctToRemove | foreach {	   
	   $list.ContentTypes.Delete($_)	   
	   $list.Update()
	 }
   }
   # adding content type to list if not exists
   $remainingContentTypes = @()
   if($list.ContentTypes -ne $null) {
     $list.ContentTypes | foreach { $remainingContentTypes += $_.Name }
   }      
   $contenttypes | foreach { 
     if(!($remainingContentTypes -contains $_)) {
	    #Add site content types to the list
        $ctToAdd = $spWeb.Site.RootWeb.ContentTypes[$_]
        $ct = $list.ContentTypes.Add($ctToAdd)
        write-host "Content type" $_ "added to list" $list.Title        
        $list.Update()
	 }
   }
 if($contenttypes.Count -gt 1) {
   # now reodering the content types - the first one in $contenttypes becomes the default 
   $list = GetList $spWeb $listName
   $currentOrder = $list.ContentTypes
   $newOrder=New-Object System.Collections.Generic.List[Microsoft.SharePoint.SPContentType]
   $list.ContentTypes | foreach {
     if($_.Name -eq $contenttypes[0]) {
	   $newOrder.Insert(0, $_)
	 }
	 elseif($_.Name -ne "Folder") {
	   $newOrder.Add($_)
	 }
   }
   $newOrder | foreach { $_.Name }
   
   $list.RootFolder.UniqueContentTypeOrder = $newOrder
   $list.RootFolder.Update() 
  }
}

function ExpandTokens([string]$textWithToken)
{          
  $expanded = $textWithToken
  
  # ~termStore
  if($expanded -like '*~termStore*') {      
    if(($gManagedMetadataServiceTermStore -eq $null) -or ($gManagedMetadataServiceTermStore -eq "")) {
      Write-Warning "gManagedMetadataServiceTermStore undefined"    
    } else {
      $expanded = $expanded -replace('~termStore', $gManagedMetadataServiceTermStore)
	}
  }
  # ~termGroup
  if($expanded -like '*~termGroup*') {      
    if(($gZurichTermGroup -eq $null) -or ($gZurichTermGroup -eq "")) {
      Write-Warning "gZurichTermGroup undefined"    
    } else {
      $expanded = $expanded -replace('~termGroup', $gZurichTermGroup)
	}
  }
 
  #~businessAreaTermSet
  if($expanded -like '*~businessAreaTermSet*') {      
    if(($gBusinessAreaTermSet -eq $null) -or ($gBusinessAreaTermSet -eq "")) {
      Write-Warning "gBusinessAreaTermSet undefined"    
    } else {
      $expanded = $expanded -replace('~businessAreaTermSet', $gBusinessAreaTermSet)
	}
  }
 
  #~contentPurposeTermSet
  if($expanded -like '*~contentPurposeTermSet*') {      
    if(($gContentPurposeTermSet -eq $null) -or ($gContentPurposeTermSet -eq "")) {
      Write-Warning "gContentPurposeTermSet undefined"    
    } else {
      $expanded = $expanded -replace('~contentPurposeTermSet', $gContentPurposeTermSet)
	}
  }
 
  # ~languageTermSet
  if($expanded -like '*~languageTermSet*') {      
    if(($gLanguageTermSet -eq $null) -or ($gLanguageTermSet -eq "")) {
      Write-Warning "gLanguageTermSet undefined"    
    } else {
      $expanded = $expanded -replace('~languageTermSet', $gLanguageTermSet)
	}
  }

  # ~functionTermSet
  if($expanded -like '*~functionTermSet*') {      
    if(($gFunctionTermSet -eq $null) -or ($gFunctionTermSet -eq "")) {
      Write-Warning "gFunctionTermSet undefined"    
    } else {
      $expanded = $expanded -replace('~functionTermSet', $gFunctionTermSet)
	}
  }
 
  # ~placeTermSet
  if($expanded -like '*~placeTermSet*') {      
    if(($gPlaceTermSet -eq $null) -or ($gPlaceTermSet -eq "")) {
      Write-Warning "gPlaceTermSet undefined"    
    } else {
      $expanded = $expanded -replace('~placeTermSet', $gPlaceTermSet)
	}
  }
 
  # ~topicTermSet
  if($expanded -like '*~topicTermSet*') {      
    if(($gTopicTermSet -eq $null) -or ($gTopicTermSet -eq "")) {
      Write-Warning "gTopicTermSet undefined"    
    } else {
      $expanded = $expanded -replace('~topicTermSet', $gTopicTermSet)
	}
  }

  # ~dataClassificationTermSet
  if($expanded -like '*~classificationTermSet*') {      
    if(($gClassificationTermSet -eq $null) -or ($gClassificationTermSet -eq "")) {
      Write-Warning "gClassificationTermSet undefined"    
    } else {
      $expanded = $expanded -replace('~classificationTermSet', $gClassificationTermSet)
	}
  }
  
  return $expanded
}