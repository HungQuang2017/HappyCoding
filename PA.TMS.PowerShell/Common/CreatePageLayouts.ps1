
function CreateAllPageLayouts([string] $siteUrl, $metadataFile){
    
	#$dataFileName = ""
    #if($metadataFile -eq "") {
    #    $dataFileName = $gDataPath + "PageLayouts.xml"
    #} else {
    #    $dataFileName = $gDataPath + $metadataFile
    #}

    $siteData = GetXmlStructure($metadataFile)

    Write-Host "Creating page layouts..."
	$siteData.Web.Data.PageLayout| foreach {
		CreatePageLayout $_ $siteUrl
	}
}

function GetContentTypeId([string] $nameOfContentType, [string] $siteUrl)
{
    $spsite = new-object Microsoft.Sharepoint.SPSite($siteUrl)
	$web = $spsite.openweb() 
    
    $contentType = $web.ContentTypes["$nameOfContentType"]

	$web.dispose() 
	$spsite.dispose() 
    
    return $contentType.ID
}

function CreatePageLayout($fieldData ,[string] $siteUrl ){

	$pageLayoutName = $fieldData.Name + ".aspx"

	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Sharepoint")
	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Sharepoint.Administration")

	$checkInComment="Check In"
	$publishComment="published"
	$approveComment="Approved"
	try
	{
		$spsite = new-object Microsoft.Sharepoint.SPSite($siteUrl)
		$web = $spsite.openweb() 
 
		$masterPageList = $web.Lists["Master Page Gallery"] 
		$masterPageFolder = ($web).GetFolder("Master Page Gallery")
		# Get file system path
		#$filesfolde = Split-Path $script:MyInvocation.MyCommand.Path

		$pageLayoutLocalDir = $gBranding + "PageLayouts"
		#For upload all files in document library from file system

		Write-Host "$pageLayoutName is being applied" -foregroundcolor "Green"
		$web.AllowUnsafeUpdates=$true
		$destUrl = $web.Url + "/_catalogs/masterpage/" + $pageLayoutName
		$pageLayoutFile=$web.GetFile($destUrl)
		if(Test-Path ($pageLayoutLocalDir + "\" + $pageLayoutName)){
			$stream = [IO.File]::OpenRead($pageLayoutLocalDir + "\" + $pageLayoutName)
			#when current site Publishing Feature turned on.
			#In case turn on, then turn off
			if ($masterPageList.EnableMinorVersions -eq $true)
			{			
				if($pageLayoutFile.Exists)
				{
					if($pageLayoutFile.CheckOutStatus -ne "None")
					{
						$pageLayoutFile.UndoCheckOut() 
						$pageLayoutFile.Update() 
					}
					$pageLayoutFile.CheckOut()
					$masterPageFolder.files.Add($destUrl,$stream,$true) 
				}
				else
				{

					$masterPageFolder.files.Add($destUrl,$stream,$true) 
					$pageLayoutFile.CheckOut()
				}
				$stream.close()
			
				$contentTypeID = GetContentTypeId $fieldData.ContentType.Name $siteUrl
				$contentTypeName = $fieldData.ContentType.Name
            

				$pageLayoutFile.Item.Properties['vti_title'] = $fieldData.Name
				$pageLayoutFile.Item.Properties["ContentType"] = "Page Layout"
				$pageLayoutFile.Item.Properties["PublishingAssociatedContentType"] = ";#$contentTypeName;#$contentTypeID;#"


				$pageLayoutFile.Item.SystemUpdate()

				$pageLayoutFile.Update()
				$pageLayoutFile.CheckIn($checkInComment)
				$pageLayoutFile.Publish($publishComment) 			
			}
			else
			{
				if($pageLayoutFile.Exists)
				{
					$pageLayoutFile.CheckOut()
				}
				$masterPageFolder.files.Add($destUrl,$stream,$true)
				if($pageLayoutFile.CheckOutStatus -eq "None")
				{ 
					$pageLayoutFile.CheckOut() 
				}
			
				$contentTypeID = GetContentTypeId $fieldData.ContentType.Name $siteUrl            
				$contentTypeName = $fieldData.ContentType.Name
            

				$pageLayoutFile.Item.Properties['vti_title'] = $fieldData.Name
				$pageLayoutFile.Item.Properties["ContentType"] = "Page Layout"
				$pageLayoutFile.Item.Properties["PublishingAssociatedContentType"] = ";#$contentTypeName;#$contentTypeID;#"

				$pageLayoutFile.Item.SystemUpdate()
				$pageLayoutFile.Update()
				$pageLayoutFile.CheckIn($checkInComment)
			}
		
			if ( $masterPageList.EnableModeration -eq $true ) 
			{					
				$pageLayoutFile.Approve($approveComment) 	
			}

			$tempVar = $pageLayoutFile.Update() 
		}
	
  		$web.AllowUnsafeUpdates  = $false
		$web.dispose() 
		$spsite.dispose() 
	}
	catch
	{
		$outputText = $pageLayoutName + " can not be applied."
		Write-Host $outputText -foregroundcolor "Red"
		Write-Host "Detail error: " + $_ -foregroundcolor "Red"
	}

}