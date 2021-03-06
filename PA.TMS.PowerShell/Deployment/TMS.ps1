function DoDeploymentForTMS_Part01(){
    
    Write-Host " "
    Write-Host -ForegroundColor Green "1. Create Site Collections ... "
    $siteStructureFileName = $gHomeDataPath + "\SiteStructure.xml"
    Write-Host '$siteStructureFileName = ' $siteStructureFileName
    CreateSiteCollection $siteStructureFileName
    Write-Host "===================================================================================="

    Write-Host " "
    Write-Host -ForegroundColor Green "2. Activate Features... "
    $featuresFileName = $gHomeDataPath + "\Features.xml"
    Write-Host '$featuresFileName = ' $featuresFileName
    ActivateFeaturesForSites $featuresFileName $gSiteCollectionUrl
    Write-Host "====================================================================================" 	
}

function DoDeploymentForTMS_Part02(){

    Write-Host " "
    Write-Host -ForegroundColor Green "1. Provisioning Site Columns... "
    $siteColumnsFileName = $gHomeDataPath + "\SiteColumns.xml"
    Write-Host '$siteColumnsFileName = ' $siteColumnsFileName
    #CreateSiteColumns $siteColumnsFileName
    Write-Host "===================================================================================="

    Write-Host " "
    Write-Host -ForegroundColor Green "2. Provisioning Lists... "
    $listFileName = $gHomeDataPath + "\ListDefinitions.xml"
    Write-Host '$listFileName = ' $listFileName
    #ProvisionLists $listFileName
    Write-Host "===================================================================================="
    
    Write-Host " "
    Write-Host -ForegroundColor Green "3. Deploying solutions... "
    $dataFarmSolutionsFileName = $gHomeDataPath +  "\FarmSolutions.xml"
    $farmSolutionsfolderPath = $gHomeDataPath +  "\FarmSolutions"
    DoDeploySolutions $farmSolutionsfolderPath $dataFarmSolutionsFileName
    Write-Host "===================================================================================="
    
    Write-Host " "
    Write-Host -ForegroundColor Green "4. Provisioning Report Data... "
    $reportDataPath = $gHomeDataPath + "\Reports"
    #ProvisioningReportData $reportDataPath
    Write-Host "===================================================================================="
    
    Write-Host " "
    Write-Host -ForegroundColor Green "5. Provisioning Site Branding... "
    ProvisioningSiteBranding
    Write-Host "===================================================================================="
    
    Write-Host " "
    Write-Host -ForegroundColor Green "6. Provisioning Permission... "
    $dataPermissionsFileName = $gHomeDataPath +  "\Permissions.xml"
    DoProvisioningPermission $dataPermissionsFileName
    Write-Host "===================================================================================="
    
	Write-Host " "
    Write-Host -ForegroundColor Green "7. Provisioning List data... "
    $listDataFileName = $gHomeDataPath + "\DataLists.xml"
    Write-Host '$listDataFileName = ' $listDataFileName
    #ProvisionListData $listDataFileName
    Write-Host "===================================================================================="
}

function ProvisionLeftNavigation([string]$leftNavDataPath){
    $leftNavData = GetXmlStructure($leftNavDataPath)
    UpdateNavigations $gSiteCollectionUrl "Apps" $leftNavData.Web.Data
}

function ProvisioningSiteBranding(){
    
    Write-Host " "
    Write-Host -ForegroundColor Yellow "a. Upload the Master page for root site"
    UploadMasterpage  $gSystemMasterPageName $gSiteCollectionUrl $true
    UploadMasterpage  $gPublishingMasterpageName $gSiteCollectionUrl $false

    Write-Host " "
    Write-Host -ForegroundColor Yellow "b. Import Folder to Site "
    Import-OSCFolder -siteurl $gSiteCollectionUrl -Library $gAssetLibraryName -path  $gAssetsFolderPath

    Write-Host " "
    Write-Host -ForegroundColor Yellow "c. Update site logo "
    UpdateSiteLogo  $gSiteLogoUrl

    Write-Host " "
    Write-Host -ForegroundColor Yellow "d. Create the Page Layouts for Site "
    $pageLayoutsPath = $gHomeDataPath + "\PageLayouts.xml"
    Write-Host '$pageLayoutsPath = ' $pageLayoutsPath
    CreateAllPageLayouts $gSiteCollectionUrl $pageLayoutsPath
    
    Write-Host " "
    Write-Host -ForegroundColor Yellow "d. Create Content Pages  " 
    $pagesPath = $gHomeDataPath + "\Pages.xml"
    Write-Host '$pagesPath = ' $pagesPath  
    DoPopulateDataForPages $gSiteCollectionUrl $pagesPath
}

function UpdateSiteLogo([string]$gSiteLogoUrl)
{
    $siteUrl = ExpandURI "~SiteCollection"
    $spSite = Get-SPSite $siteUrl
    $spWeb  = $spSite.OpenWeb()

    if($spWeb.SiteLogoUrl -eq $null -or $spWeb.SiteLogoUrl -eq "" -or $spWeb.SiteLogoUrl.ToLower() -ne $gSiteLogoUrl.ToLower()){

        Write-host "Old site logo url: " $spWeb.SiteLogoUrl -f Yellow
        $spWeb.SiteLogoUrl = $gSiteLogoUrl
        $spWeb.Update()
        Write-host "New site logo url: " $spWeb.SiteLogoUrl -f Yellow
    }
    $spWeb.Dispose();
    $spSite.Dispose();
}

function ProvisioningReportData([string]$reportDataPath)
{
    $siteUrl = ExpandURI "~SiteCollection"
    $spSite = Get-SPSite $siteUrl
    $spWeb  = $spSite.OpenWeb()

    $reportsFileName = $gHomeDataPath + "\Reports.xml"
    $reportData = GetXmlStructure($reportsFileName)
      
    $reportList = $spWeb.Lists["Reports"]
    if($reportList -ne $null){
        Get-ChildItem -Path $reportDataPath | Foreach-Object {
            
            $file = $_
            if($reportData.Web.Data.Reports.Report -ne $null){
                $reportData.Web.Data.Reports.Report | ForEach {
                    $fileToUpload = [System.IO.FileInfo]$file
                    $isUpdated = $false
                    $listID = ""
                    $textToBeUpdated = ""

                    try{            
                        if($_.Name.ToLower() -eq $fileToUpload.Name.ToLower()){
                            if($_.TextTobeUpdated -ne $null -and $_.TextTobeUpdated -ne "" -and $_.ListDataSource -ne $null -and $_.ListDataSource -ne "" ){
                                $listDataSource = $spWeb.Lists[$_.ListDataSource]
                                $listID = $listDataSource.ID
                                $textToBeUpdated = $_.TextTobeUpdated
                                (Get-Content $fileToUpload.FullName).replace($textToBeUpdated, $listID) | Set-Content $fileToUpload.FullName
                                $isUpdated = $true
                            }
                            $fileStream = $fileToUpload.OpenRead()
                            Write-Host "Adding " $fileToUpload.Name " to Reports Library" -ForegroundColor "yellow"
                            $spFile = $reportList.RootFolder.files.Add($fileToUpload.Name, [System.IO.Stream]$fileStream, $true)
                            $fileStream.Close()
                            #continue
                        }
                    }
                    catch{
                         $ErrorMessage = $_.Exception.Message
                         Write-Host $ErrorMessage
                         throw
                    }   
                    finally{
                        if($isUpdated -eq $true){
                            (Get-Content $fileToUpload.FullName).replace($listID, $textToBeUpdated) | Set-Content $fileToUpload.FullName
                        }
                    }      
                }
            }
        }
    }
    else{
        Write-Host "Could not find the list Reports"
    }
    $spWeb.Dispose();
    $spSite.Dispose();
}

function SetDefaultPageLayout([string]$siteUrl){
    $spSite = Get-SPSite $siteUrl
    $spWeb = Get-SPWeb $siteUrl
    $rWeb = $spWeb
    if($spWeb.IsRootWeb -eq $false){
        $rWeb = $spWeb.RootWeb
    }
       
    $pweb = [Microsoft.SharePoint.Publishing.PublishingWeb]::GetPublishingWeb($rWeb)     
    if($pweb -eq $null) {
        Write-Error "$($spWeb.Url) is not a publishing web"
	    return	
    }

    # This code (as an example) uses the first layout as the default.
    $currentLayOuts = $pweb.GetAvailablePageLayouts()

    #publishing site instance  
    [Microsoft.Sharepoint.Publishing.PublishingSite]$publishingSite = New-Object Microsoft.SharePoint.Publishing.PublishingSite($spSite)  
     
    #getting collection of all the page layouts in a Site collection  
    $allPageLayouts = $publishingSite.PageLayouts  
 
    #looping through all the page layouts  
    foreach($pageLayout in $allPageLayouts)  
    {  
      #checking for the page layout which we want to make available  
      if($pageLayout.Name -eq "HomeLayout.aspx")  
      {  
        #adding the new page layout to current webs available page layout collection  
        $currentLayOuts+=$pageLayout;  
        break;  
       } #if  
    } #for each 

    
    $pweb.SetAvailablePageLayouts($currentLayOuts,$false)  
    $pweb.Update()

    $rWeb.Dispose() 
}




