$checkInComment="Check In"
$publishComment="published"
$approveComment="Approved"

function UploadMasterpage([string]$masterpageName,[string] $siteUrl, [bool] $isSystem){

    [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Sharepoint")
    [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Sharepoint.Administration")
    
    try
    {
	    $spsite = new-object Microsoft.Sharepoint.SPSite($siteUrl)
	    $web = $spsite.openweb() 
 
	    $masterPageList = $web.Lists["Master Page Gallery"] 
	    $masterPageFolder = ($web).GetFolder("Master Page Gallery")
	    # Get file system path
	    #$filesfolde = Split-Path $script:MyInvocation.MyCommand.Path

	    $masterPageLocalDir = $gBranding + "MasterPages"
	    #For upload all files in document library from file system

	    Write-Host "$masterpageName is being applied" -foregroundcolor "Green"
	    $web.AllowUnsafeUpdates=$true
	    $destUrl = $web.Url + "/_catalogs/masterpage/" + $masterpageName
	    $masterPageFile=$web.GetFile($destUrl)
	    if(Test-Path ($masterPageLocalDir + "\" + $masterpageName)){
		    $stream = [IO.File]::OpenRead($masterPageLocalDir + "\" + $masterpageName)
		    #when current site Publishing Feature turned on.
		    #In case turn on, then turn off
		    if ($masterPageList.EnableMinorVersions -eq $true)
		    {			
			    if($masterPageFile.Exists)
			    {
				    if($masterPageFile.CheckOutStatus -ne "None")
				    {
					    $masterPageFile.UndoCheckOut() 
					    $masterPageFile.Update() 
				    }
				    $masterPageFile.CheckOut()
				    $masterPageFolder.files.Add($destUrl,$stream,$true) 
			    }
			    else
			    {
				    $masterPageFolder.files.Add($destUrl,$stream,$true) 
			    }
			    $stream.close()
			
			    $masterPageFile.Item.Properties["ContentTypeId"] = "0x010105"
			    $masterPageFile.Item.Update()
            
                if($masterPageFile.CheckOutStatus -eq "None")
		        {
				    $masterPageFile.CheckOut() 
				    $masterPageFile.Update() 
			    }

			    $masterPageFile.CheckIn($checkInComment)
			    $masterPageFile.Publish($publishComment) 			
		    }
		    else
		    {
			    if($masterPageFile.Exists)
			    {
				    $masterPageFile.CheckOut()
			    }
			    $masterPageFolder.files.Add($destUrl,$stream,$true)
			    if($masterPageFile.CheckOutStatus -eq "None")
			    { 
				    $masterPageFile.CheckOut() 
			    }
			
			    $masterPageFile.Item.Properties["ContentTypeId"] = "0x010105"
			    $masterPageFile.Item.Update()
			    $masterPageFile.CheckIn($checkInComment)
		    }
		
		    if ( $masterPageList.EnableModeration -eq $true ) 
		    {					
			    $masterPageFile.Approve($approveComment) 	
		    }

		    $tempVar = $masterPageFile.Update() 
	    }
	
	    if($masterPageFile.Exists)
	    {
		    #Set default master page.
		    $masterUri=New-Object System.Uri($destUrl)
            if($isSystem -eq $true) {
		        $web.MasterUrl=$masterUri.AbsolutePath
		        #$web.CustomMasterUrl=$masterUri.AbsolutePath
            }
            else {
		        $web.CustomMasterUrl=$masterUri.AbsolutePath
            }
		    $web.Update()
		    Write-Host "$masterpageName is set to default master page."
	    }
	    else{
		    Write-Host "$masterpageName doesn't exist!."
	    }
  	    $web.AllowUnsafeUpdates  = $false
	    $web.dispose() 
	    $spsite.dispose() 
    }
    catch
    {
	    $outputText = $masterpageName + " can not be applied."
	    Write-Host $outputText -foregroundcolor "Red"
	    Write-Host "Detail error: " + $_ -foregroundcolor "Red"
    }
}

function UploadPublishingImageRenditionsFile([string]$filePath,[string] $siteUrl){

    [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Sharepoint")
    [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Sharepoint.Administration")
    try
    {
	    $spsite = new-object Microsoft.Sharepoint.SPSite($siteUrl)
	    $web = $spsite.openweb() 
 
	    $masterPageList = $web.Lists["Master Page Gallery"] 
	    $masterPageFolder = ($web).GetFolder("Master Page Gallery")
	    
        $renditionFileName = "PublishingImageRenditions.xml"

	    $web.AllowUnsafeUpdates=$true
	    $destUrl = $web.Url + "/_catalogs/masterpage/" + $renditionFileName
	    $renditionFile=$web.GetFile($destUrl)
	    
		    $stream = [IO.File]::OpenRead($filePath)
		    #when current site Publishing Feature turned on.
		    #In case turn on, then turn off
		    if ($masterPageList.EnableMinorVersions -eq $true)
		    {			
			    if($renditionFile.Exists)
			    {
				    if($renditionFile.CheckOutStatus -ne "None")
				    {
					    $renditionFile.UndoCheckOut() 
					    $renditionFile.Update() 
				    }
				    $renditionFile.CheckOut()
				    $masterPageFolder.files.Add($destUrl,$stream,$true) 
			    }
			    else
			    {
				    $masterPageFolder.files.Add($destUrl,$stream,$true) 
			    }
			    $stream.close()
			
			    $renditionFile.Item.Update()
            
                if($renditionFile.CheckOutStatus -eq "None")
		        {
				    $renditionFile.CheckOut() 
				    $renditionFile.Update() 
			    }

			    $renditionFile.CheckIn($checkInComment)
			    $renditionFile.Publish($publishComment) 			
		    }
		    else
		    {
			    if($renditionFile.Exists)
			    {
				    $renditionFile.CheckOut()
			    }
			    $masterPageFolder.files.Add($destUrl,$stream,$true)
			    if($renditionFile.CheckOutStatus -eq "None")
			    { 
				    $renditionFile.CheckOut() 
			    }
			
			    $renditionFile.Item.Update()
			    $renditionFile.CheckIn($checkInComment)
		    }
		
		    if ( $masterPageList.EnableModeration -eq $true ) 
		    {					
			    $renditionFile.Approve($approveComment) 	
		    }

		    $tempVar = $renditionFile.Update() 
	    
		    
  	    $web.AllowUnsafeUpdates  = $false
	    $web.dispose() 
	    $spsite.dispose() 
        Write-Host "Upload Image Rendition File is successfully. " -foregroundcolor "Green"
    }
    catch
    {
	    Write-Host "Upload Image Rendition File - Detail error: " + $_ -foregroundcolor "Red"
    }

}