#Include functions

$currentFolder = Split-Path $script:MyInvocation.MyCommand.Path
$parentFolder = Split-Path $currentFolder -Parent
$filesfolder =  Split-Path $script:MyInvocation.MyCommand.Path

# token ~data will be replaced by this variable value
if ($parentFolder.EndsWith("\PA.TMS.PowerShell")) 
{
    $gSourcePath = $parentFolder.Replace("\PA.TMS.PowerShell", "")
    $gDataPath = $gSourcePath + "\PA.TMS.Metadata\"

	$gAssembliesPath = $gSourcePath + "\Assemblies\"
    
    $gBranding = $gSourcePath + "\PA.TMS.Branding\"    
	$gAssetsFolderPath = $gBranding + "SiteAssets"
}

Write-Host '$parentFolder = ' $parentFolder
Write-Host '$gSourcePath = ' $gSourcePath
Write-Host '$gDataPath = ' $gDataPath
Write-Host '$gBranding = ' $gBranding
Write-Host '$gAssetsFolderPath = ' $gAssetsFolderPath
Write-Host '$gAssembliesPath = ' $gAssembliesPath

$gCommonPath = $parentFolder + '\Common'
$gDeploymentPath = $parentFolder + "\Deployment"
$gHomeDataPath = $gDataPath + "Home"

# Load COMMON Scripts
$pGlobalSettings = $gCommonPath + "\GlobalSettings.ps1"
Write-Host '$pGlobalSettings = ' $pGlobalSettings

$pUtils = $gCommonPath + "\Utils.ps1"
Write-Host '$pUtils = ' $pUtils

$pProvisionLists = $gCommonPath + "\ProvisionLists.ps1"
Write-Host '$pProvisionLists = ' $pProvisionLists

$pUploadMasterPages = $gCommonPath + "\UploadMasterPages.ps1"
Write-Host '$pUploadMasterPages = ' $pUploadMasterPages

$pImportFolderToSite = $gCommonPath + "\ImportFolderToSite.ps1"
Write-Host '$pImportFolderToSite = ' $pImportFolderToSite

$pCreatePageLayouts = $gCommonPath + "\CreatePageLayouts.ps1"
Write-Host '$pCreatePageLayouts = ' $pCreatePageLayouts

$pCreateContentForPages = $gCommonPath + "\CreateContentForPages.ps1"
Write-Host '$pCreateContentForPages = ' $pCreateContentForPages

##$pProvisionSiteColumns = $gCommonPath + "\ProvisionSiteColumns.ps1"
##Write-Host '$pProvisionSiteColumns = ' $pProvisionSiteColumns
##
##$pProvisionContentTypes = $gCommonPath + "\ProvisionContentTypes.ps1"
##Write-Host '$pProvisionContentTypes = ' $pProvisionContentTypes

$pProvisionSiteCollection = $gCommonPath + "\ProvisionSites.ps1"
Write-Host '$pProvisionSiteCollection = ' $pProvisionSiteCollection

##$CreateNavigations = $gCommonPath + "\CreateNavigations.ps1"
##Write-Host '$CreateNavigations = ' $CreateNavigations

$pProvisionPermissions = $gCommonPath + "\ProvisionPermissions.ps1"
Write-Host '$pProvisionPermissions = ' $pProvisionPermissions

##$pProvisionFoldersInPage = $gCommonPath + "\CreateFolderForPages.ps1"
##Write-Host '$pProvisionFoldersInPage = ' $pProvisionFoldersInPage

$pDoDeploymentForTMS = $gDeploymentPath + "\TMS.ps1"
Write-Host '$pDoDeploymentForTMS = ' $pDoDeploymentForTMS

$pCRUDScripts = $gCommonPath + "\CRUDScripts.ps1"
Write-Host '$pCRUDScripts  = ' $pCRUDScripts

$pGetAndSetFields = $gCommonPath + "\GetAndSetFields.ps1"
Write-Host '$pGetAndSetFields  = ' $pGetAndSetFields

$gDeploySolution = $gCommonPath + "\DeploySolution.ps1"
Write-Host '$gDeploySolution = ' $gDeploySolution

. $pGlobalSettings
. $pUtils
. $pProvisionLists
##. $pProvisionSiteColumns
##. $pProvisionContentTypes
. $pProvisionPermissions
##. $pProvisionFoldersInPage
. $pUploadMasterPages
. $pImportFolderToSite 
. $pCreatePageLayouts
. $pCreateContentForPages
. $pProvisionSiteCollection
##. $CreateNavigations
. $pDoDeploymentForTMS
. $pCRUDScripts
. $pGetAndSetFields
. $gDeploySolution

#====================================================================================
Write-Host " "
Write-Host " "
Write-Host -ForegroundColor magenta "START DEPLOYMENT PROCESS FOR TMS"

Write-Host " "
DoDeploymentForTMS_Part01
Write-Host "===================================================================================="

Write-Host " "
#Write-Host "DEPLOYMENT PROCESS FOR TMS IS COMPLETED SUCCESSFULLY ..."
Write-Host -ForegroundColor magenta "DEPLOYMENT FOR TMS 'PART 1' IS COMPLETED... "

