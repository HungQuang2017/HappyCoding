function CreateNavigations([string] $siteUrl, [string]$type, [string]$dataFilePath){
    
	#$dataFileName = $gDataPath + "NavigationsConfiguration.xml"
	$dataFileName = $dataFilePath + "\NavigationsConfiguration.xml"
    $siteData = GetXmlStructure($dataFileName)

    Write-Host "Creating navigations..."
	switch ($type) {
		"Division" { 
			ResetStructuralNavigation $siteUrl
			CreateNavigationsForPublishingWeb $siteUrl $siteData.Web.Data.DivisionNavigations
		}
		"MySite" { 
			ResetAllQuickLaunch $siteUrl
			CreateQuickLauchForMySite $siteUrl $siteData.Web.Data.MySiteNavigations
		}
		"Project" {
            ResetStructuralNavigation $siteUrl 
			CreateNavigationsForPublishingWeb $siteUrl $siteData.Web.Data.ProjectNavigations
		}            
	} 
}

function UpdateNavigations([string] $siteUrl, [string]$type, $siteData, $spWeb)
{    
	Write-Host "Creating navigations..."
	switch ($type) {
		"Apps" { 
			ResetStructuralNavigation $siteUrl
			CreateNavigationsForPublishingWeb $siteUrl $siteData.LeftNavigations $spWeb
		}
		"Project" {
            ResetStructuralNavigation $siteUrl 
			CreateNavigationsForPublishingWeb $siteUrl $siteData.LeftNavigations $spWeb
		}            
	} 
}

function DeleteAllNavigations($qlNav){
	for ($i = $qlNav.Count-1; $i -ge 0; $i--)
    {
	    if($qlNav[$i].Title -eq $null)
	    {
		    continue
	    }
	    else
	    {
		    $qlNav[$i].Delete()
	    }
    }
}

function ResetStructuralNavigation([string] $siteUrl){
	trap {
        continue
    }

    $spWeb = Get-SPWeb $siteUrl

    #Check if the #siteUrl exists
    if($spWeb -eq $null){
		Write-Host "Invalid web url $siteUrl"
		return
	}

	#Save the AllowUnsafeUpdatesStatus property value
	$AllowUnsafeUpdatesStatus = $SPWeb.AllowUnsafeUpdates
	$spWeb.AllowUnsafeUpdates = $true
	
	Write-Host "Creating navigations for" $siteUrl "..."
	$pubWeb = [Microsoft.SharePoint.Publishing.PublishingWeb]::GetPublishingWeb($spWeb)
    
    $WebNavigationSettings = New-Object Microsoft.SharePoint.Publishing.Navigation.WebNavigationSettings($spWeb)
    $WebNavigationSettings.GlobalNavigation.Source = "portalProvider"
    $WebNavigationSettings.CurrentNavigation.Source = "portalProvider"
    $WebNavigationSettings.Update()

	$qlNav = $pubWeb.Navigation.CurrentNavigationNodes
	DeleteAllNavigations($qlNav);

	#Revert the AllowUnsafeUpdatesStatus property value
	$spWeb.AllowUnsafeUpdates = $AllowUnsafeUpdatesStatus

	#Update the Publishing Web Navigation Settings
	$spWeb.Update()

	#Dispose the SPWeb object
	$spWeb.Dispose()
}

function ResetAllQuickLaunch([string] $siteUrl){
	trap {
        continue
    }

    $spWeb = Get-SPWeb $siteUrl

    #Check if the #siteUrl exists
    if($spWeb -eq $null){
		Write-Host "Invalid web url $siteUrl"
		return
	}

	#Save the AllowUnsafeUpdatesStatus property value
	$AllowUnsafeUpdatesStatus = $SPWeb.AllowUnsafeUpdates
	$spWeb.AllowUnsafeUpdates = $true

    $navquicklaunch = $spWeb.Navigation.QuickLaunch

    Write-Host "Deleting navigations for" $siteUrl "..."	
	DeleteAllNavigations($navquicklaunch);
}

function CreateNavigationsForPublishingWeb([string] $siteUrl, $navigations, $spWeb) {
	trap {
        continue
    }

    if($spWeb -eq $null) {
        $spWeb = Get-SPWeb $siteUrl
    }

    #Check if the #siteUrl exists
    if($spWeb -eq $null){
		Write-Host "Invalid web url $siteUrl"
		return
	}

	#Save the AllowUnsafeUpdatesStatus property value
	$AllowUnsafeUpdatesStatus = $SPWeb.AllowUnsafeUpdates
	$spWeb.AllowUnsafeUpdates = $true
	
	Write-Host "Creating navigations for" $siteUrl "..."
	$pubWeb = [Microsoft.SharePoint.Publishing.PublishingWeb]::GetPublishingWeb($spWeb)
    
    $WebNavigationSettings = New-Object Microsoft.SharePoint.Publishing.Navigation.WebNavigationSettings($spWeb)
    $WebNavigationSettings.GlobalNavigation.Source = "portalProvider"
    $WebNavigationSettings.CurrentNavigation.Source = "portalProvider"
    $WebNavigationSettings.Update()

	$qlNav = $pubWeb.Navigation.CurrentNavigationNodes

    $pubWeb.Navigation.InheritGlobal = $false
    $pubWeb.Navigation.GlobalIncludeSubSites = $false
    $pubWeb.Navigation.GlobalIncludePages = $false

	$pubWeb.Navigation.InheritCurrent = $false
	$pubWeb.Navigation.ShowSiblings = $false
	$pubWeb.Navigation.CurrentIncludeSubSites = $false
	$pubWeb.Navigation.CurrentIncludePages = $false
	    
	#assign the CreateSPNavigationNode method to a variable to make it easier to invoke later on in the script
	$CreateSPNavigationNode = [Microsoft.SharePoint.Publishing.Navigation.SPNavigationSiteMapNode]::CreateSPNavigationNode

	foreach($headingXmlNode in $navigations.ChildNodes){
		$qlHeading = $qlNav | where { $headingXmlNode.Title -eq $_.Title }
		if($qlHeading -eq $null) {
            #Write-Host "Heading Url = " $headingXmlNode.Url " - Target = " $headingXmlNode.Target
			$qlHeading = $CreateSPNavigationNode.Invoke($headingXmlNode.Title, $headingXmlNode.Url, [Microsoft.SharePoint.Publishing.NodeTypes]::Heading, $qlNav)
		}
        foreach($linkXmlNode in $headingXmlNode.Children.ChildNodes){            
            $link = $qlHeading.Children | where { $linkXmlNode.Title -eq $_.Title }
            if($link -eq $null) {
                Write-Host "Child Url = " $linkXmlNode.Url " - Target = " $linkXmlNode.Target
                if($linkXmlNode.Target -and ($linkXmlNode.Target -eq "Root")) {
                    $link = $CreateSPNavigationNode.Invoke($linkXmlNode.Title, $gSiteCollectionUrl + $linkXmlNode.Url, [Microsoft.SharePoint.Publishing.NodeTypes]::AuthoredLinkPlain, $qlHeading.Children)
                }
                else {
			        $link = $CreateSPNavigationNode.Invoke($linkXmlNode.Title, $linkXmlNode.Url, [Microsoft.SharePoint.Publishing.NodeTypes]::AuthoredLinkPlain, $qlHeading.Children)
                }
            }
		}
	}

	#Revert the AllowUnsafeUpdatesStatus property value
	$spWeb.AllowUnsafeUpdates = $AllowUnsafeUpdatesStatus

	#Update the Publishing Web Navigation Settings
	$spWeb.Update()
	Write-Host -ForegroundColor Green " Done"

	#Dispose the SPWeb object
	$spWeb.Dispose()
}

function CreateQuickLauchForMySite([string] $siteUrl, $navigations) {
	trap {
        continue
    }

    $spWeb = Get-SPWeb $siteUrl

    #Check if the #siteUrl exists
    if($spWeb -eq $null){
		Write-Host "Invalid web url $siteUrl"
		return
	}

	#Save the AllowUnsafeUpdatesStatus property value
	$AllowUnsafeUpdatesStatus = $SPWeb.AllowUnsafeUpdates
	$spWeb.AllowUnsafeUpdates = $true

    $navquicklaunch = $spWeb.Navigation.QuickLaunch
    
    Write-Host "Creating navigations for" $siteUrl "..."	
	foreach($headingXmlNode in $navigations.ChildNodes){
		$navheadnode = $navquicklaunch | where { $headingXmlNode.Title -eq $_.Title }
		if($navheadnode -eq $null) {
            $navUrl = $gMySiteUrl + $headingXmlNode.Url
			$navheadnode = New-Object Microsoft.SharePoint.Navigation.SPNavigationNode($headingXmlNode.Title, $navUrl, $true) 
            $navquicklaunch.addaslast($navheadnode) 
		}
	}

	#Revert the AllowUnsafeUpdatesStatus property value
	$spWeb.AllowUnsafeUpdates = $AllowUnsafeUpdatesStatus

	#Update the Publishing Web Navigation Settings
	$spWeb.Update()
	Write-Host -ForegroundColor Green " Done"

	#Dispose the SPWeb object
	$spWeb.Dispose()
}

function CreateNavigationsForNonePublishingWeb([string] $siteUrl, $navigations) {
    #TODO
}