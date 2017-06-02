function CreateSiteCollection([string]$dataFileName){
    #$fullPath = $gDataPath + $dataFileName
	$siteData = GetXmlStructure($dataFileName)
	    
	Write-Host "Creating site collection..."
	$siteData.Web.Data.Sites.Site | foreach {
		Provision-SiteCollection $_

        $siteUrl = $gSiteCollectionUrl
        if($_.RootSite -ne $true){
            $siteUrl = $gSiteCollectionUrl + $_.SiteUrl
        }
        CreateSubSites $_ $siteUrl
	}    
}

function Provision-SiteCollection($siteData)
{
	trap {
        continue
    }
    #$siteUrl = $gSiteCollectionUrl
    $siteUrl = $gWebAppUrl + $_.SiteUrl
    if($siteData.RootSite -ne $true){
        $siteUrl = $gSiteCollectionUrl + $siteData.SiteUrl
    }
    $exists = (Get-SPWeb $siteUrl -ErrorAction SilentlyContinue) -ne $null

    if(!$exists)
    {
        $template = Get-SPWebTemplate $siteData.SiteTemplate
	    
		#$siteUrl = $gSiteCollectionUrl + $siteData.SiteUrl
        
        Write-Host "Creating new site collection..." $siteUrl
        $contentDB = $siteData.ContentDatabase 
		if($contentDB -eq $null){
		    New-SPSite -Url $siteUrl -OwnerAlias $siteData.PrimaryLogin -Name $siteData.SiteTitle -Template $template
            ChangeRegionalSettings $siteUrl
		}
		else
		{
            Write-Host "...in content database " $contentDB
			New-SPSite -Url $siteUrl -OwnerAlias $siteData.PrimaryLogin -ContentDatabase $contentDB -Name $siteData.SiteTitle -Template $template
            ChangeRegionalSettings $siteUrl
		}
        Write-Host "Script complete!"        
    }
    else
    {
        Write-Host "The site: (" $siteUrl ")is already in use. Please use difference site url."
    }
}

function ChangeRegionalSettings([string]$siteUrl){    
	$spWeb = Get-SPWeb $siteUrl

	if($spWeb -eq $null){
		Write-Host "Invalid web url $url"
		return
	}

	Write-Host "Change Regionale Settings to Singapore locale ..."
	
    $spsite=[Microsoft.SharePoint.SPSite]($siteUrl)

    if($spsite -eq $null){
		Write-Host "Invalid web url $siteUrl"
		return
	}

    $rootWebSite=$spsite.RootWeb
    $website=$spsite.OpenWeb($rootWebSite.ID)
    $culture=[System.Globalization.CultureInfo]::CreateSpecificCulture(“en-SG”)
    $website.Locale=$culture
    $website.Update()
    $website.Dispose()
    $rootWebSite.Dispose()
    $spsite.Dispose()
}

function CreateSubSites($siteData, [string]$parentSiteUrl){
	$spWeb = Get-SPWeb $parentSiteUrl

	if($spWeb -eq $null){
		Write-Host "Invalid web url $parentSiteUrl"
		return
	}

	Write-Host "Creating sub site ..."
	if($siteData.SubSite -ne $null) {
	    $siteData.SubSite | foreach {
		    Provision-SubSite $parentSiteUrl $_
	    }
    }
	$spWeb.Update()
	$spWeb.Dispose();
}

function Provision-SubSite([string]$parentSiteUrl, $subSiteData)
{
	trap {
        Write-Host -ForegroundColor Red "SubSite Creation failed"
        Write-Host -ForegroundColor Red $error
        continue
    }
	$subSiteUrl = $parentSiteUrl + $subSiteData.SiteUrl
	Write-Host "Creating new subsite : $subSiteUrl"

    $template = Get-SPWebTemplate $subSiteData.SiteTemplate
    $newSubSite = New-SPWeb -Url $subSiteUrl -Template $template -Name $subSiteData.SiteTitle    
   
    ChangeRegionalSettings $subSiteUrl
    Write-Host "SubSite Created Successfully..!!"             
}