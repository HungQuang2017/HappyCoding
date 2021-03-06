#Load Microsoft.SharePoint.PowerShell
$snapin = Get-PSSnapin | Where-Object {$_.Name -eq 'Microsoft.SharePoint.Powershell'}
if ($snapin -eq $null) {
	Write-Host "Loading SharePoint Powershell Snapin"
	Add-PSSnapin "Microsoft.SharePoint.Powershell"
}

#Controls how informative messages are generated
$verbose = 0

#stop if error in script
$ErrorActionPreference = "Stop"

#SP Server
$gWebAppUrl = "http://sp2016:6868/"
$gSiteCollectionUrl = "http://sp2016:6868/apps/tms"

#Site logo
$gSiteLogoUrl ="/apps/tms/Style%20Library/SiteAssets/images/palogo.jpg"

#Name of Publishing Master page
$gPublishingMasterpageName = "pa.tms.intranet.master"

#Name of System Master page
$gSystemMasterPageName = "pa.tms.systemnoleftnav.master"


#The Asset library name of site
$gAssetLibraryName ="Style Library"








