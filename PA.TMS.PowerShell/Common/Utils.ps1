#Returns XML configuration data
function GetXmlStructure([string]$fileName)
{    
	if ($fileName.Length -gt 0) {
		try {		    			
			if (Test-Path $fileName -PathType Leaf)
			{
				#Get site structure from XML document
				[xml]$siteStructure = Get-Content $fileName -ErrorAction SilentlyContinue
				if (($siteStructure -eq $null) -or ($siteStructure -eq "")) {
					Write-Warning "Invalid XML file" 
				}			
			}
			else
			{
				Write-Warning "File '$fileName' does not exist" 
			}			
		}
		catch {
			Write-Warning "Invalid XML configuration file $fileName.Exception:" $_.exception 
		}
	}
	else {
		Write-Warning "XML file is required as parameter"
	}

	return $siteStructure
}


# replace tokens:
# '~SiteCollection' with the value of $gSiteCollectionUrl
# '~webapp' with the value of the web application in $gSiteCollectionUrl
# '~data' with the value of $gDataPath
# ~owneralias with the value of $gOwnerAlias; if $gOwnerAlias is $null then replace with the identity of the current user or process
# the variables (prefixed with g) are defined in Global.ps1
function ExpandURI([string]$urlWithToken, [bool]$returnServerRelativeUrl=$false)
{          
  $expanded = $urlWithToken
      
  if($expanded -like '*~SiteAnonymous*') {      
    if(($gSiteCollectionAnonUrl -eq $null) -or ($gSiteCollectionAnonUrl -eq "")) {
      Write-Warning "gSiteCollectionAnonUrl undefined"    
    } else {
	# do not try to return server-relative url
    $expanded = $expanded -replace('~SiteAnonymous', $gSiteCollectionAnonUrl)
	}
  }
  
  if($expanded -like '*~SiteCollection*') {  
    if(($gSiteCollectionUrl -eq $null) -or ($gSiteCollectionUrl -eq "")) {
      Write-Warning "gSiteCollectionUrl undefined"    
    } else {
    $url = $gSiteCollectionUrl
    if($returnServerRelativeUrl){
	  $url = GetServerRelativeUrl $url      
    }
    $expanded = $expanded -replace('~SiteCollection', $url)
	}
  }
  if($expanded -like '*~SubSiteCollection*') {  
    if(($gSubSiteCollectionUrl -eq $null) -or ($gSubSiteCollectionUrl -eq "")) {
      Write-Warning "gSubSiteCollectionUrl undefined"    
    } else {
    $url = $gSubSiteCollectionUrl
    if($returnServerRelativeUrl){
	  $url = GetServerRelativeUrl $url      
    }
    $expanded = $expanded -replace('~SubSiteCollection', $url)
	}
  }
  if($expanded -like '*~MySite*') {  
    if(($gMySiteUrl -eq $null) -or ($gMySiteUrl -eq "")) {
      Write-Warning "$gMySiteUrl undefined"    
    } else {
    $url = $gMySiteUrl
    if($returnServerRelativeUrl){
	  $url = GetServerRelativeUrl $url      
    }
    $expanded = $expanded -replace('~MySite', $url)
	}
  }
  
  if($expanded -like '*~webapp*') {  
    if(($gSiteCollectionUrl -eq $null) -or ($gSiteCollectionUrl -eq "")) {
      Write-Warning "gSiteCollectionUrl undefined"    
    } elseif(!$gSiteCollectionUrl.StartsWith("http://") -and !$gSiteCollectionUrl.StartsWith("https://")) {
	  Write-Warning "gSiteCollectionUrl must start with http(s)://"    
	} else {
	  $prefix = 7
	  if($gSiteCollectionUrl.StartsWith("https://")) {
	    $prefix = 8
	  } 
	  $url = $gSiteCollectionUrl.Substring($prefix)
	  $index = $url.IndexOf('/')
	  if($index -gt -1) {
	    $length = $prefix + $index
	  } else {
	    $length = $gSiteCollectionUrl.Length
	  }
	  
	  $expanded = $expanded -replace('~webapp', $gSiteCollectionUrl.Substring(0, $length))  
	}
  }
  if($expanded -like '*~data*') {      
    if(($gDataPath -eq $null) -or ($gDataPath -eq "")) {
      Write-Warning "gDataPath undefined"    
    } else {
      $expanded = $expanded -replace('~data', $gDataPath)
	}
  }
  if($expanded -like '*~owneralias*') {      
    $alias = $gOwnerAlias
    if(($gOwnerAlias -eq $null) -or ($gOwnerAlias -eq "")) {
      #Write-Warning "gOwnerAlias undefined. Using DOMAIN\USERNAME for current user instead"    
	  $alias = "$([Environment]::UserDomainName)\$([Environment]::UserName)"
    }
    $expanded = $expanded -replace('~owneralias', $alias)
  }
      
  return $expanded
}

function Get-ScriptDirectory
{
	$invocation = (Get-Variable MyInvocation -Scope 1).Value
	Split-Path $invocation.MyCommand.Path
}

# Upload and activate sandboxed solution
function UploadAndActivateSandboxedSolution([string]$folderPath, [string]$dataFileFullPath, [string]$gSiteCollectionUrl)
{
    $site = Get-SPSite $gSiteCollectionUrl
	$siteData = GetXmlStructure($dataFileFullPath)
	$siteUrl = ExpandURI $siteData.Web.Url
    $siteData.Web.Data.Solutions.Solution | ForEach {
        $solutionName = $_.Name
        $solutionFullPath = $folderPath + "\" + $solutionName
        
        if(![bool]($solutionIS = $site | Get-SPUserSolution | where-object {$_.Name -eq $solutionName})){
	        Add-SPUserSolution -LiteralPath $solutionFullPath -Site $siteUrl
            Install-SPUserSolution -Identity $solutionName -Site $siteUrl
        }
    }
}

# Activate site,web features
function ActivateFeatures([string]$dataFileName)
{
    #$fullPath = $gDataPath + $dataFileName
	$siteData = GetXmlStructure($dataFileName)
    $siteUrl = ExpandURI $siteData.Web.Url
    $siteData.Web.Data.Features.Feature | ForEach {
        $webUrl = $_.Url
        if ($webUrl -eq $null)
        {
            Enable-SPFeature -Identity $_.ID -Url $siteUrl
        }
        else
        {
            Enable-SPFeature -Identity $_.ID -Url $webUrl
        }
    }
}

function ActivateFeaturesForSites($dataFileName, $siteUrl)
{
    #$fullPath = $gDataPath + $dataFileName
	$siteData = GetXmlStructure($dataFileName)
    #$web = Get-spsite $siteUrl
    $siteData.Web.Data.Features.Feature | ForEach {
		if($_.Deactivate -ne $null -and $_.Deactivate -eq $true)
		{
			Write-Host "Deactivate Feature: " $_.Name $_.Scope		
		}
		else
		{
			Write-Host "Activate Feature: " $_.Name $_.Scope
		}

        try
        {
            switch ($_.Scope)
		    {
			    "Site" { 
                    $web = Get-spsite $siteUrl 
                }
			    "Web" { 
                    $web = Get-spWeb $siteUrl 
                }			               
		    }
            
            $feature = $web.Features[$_.ID]
			if($_.Deactivate -eq $null -or $_.Deactivate -eq $false)
			{
				if ($feature -eq $null) { 
					Enable-SPFeature -Identity $_.ID -Url $siteUrl 
					Write-Host "Feature is activated"
				} 
				else { 
					Write-Host "This feature is activated already" 
				}
			}
			elseif($_.Deactivate -eq $true)
			{
				if ($feature -ne $null) { 
					Disable-SPFeature -Identity $_.ID -Url $siteUrl -Confirm:$false 
					Write-Host "Feature is deactivated"
				} 
				else { 
					Write-Host "This feature is deactivated already" 
				}
			}
        }
        catch{
             $ErrorMessage = $_.Exception.Message
             Write-Host $web.Title  $ErrorMessage
             throw
        }        
    }    
}

function GetServerRelativeUrl([string]$url)
{
	$web = get-spweb $url 

    return $web.ServerRelativeURL
}

function Select-FileDialog() 
{
	param([string]$Title,[string]$Directory,[string]$Filter="CSV Files (*.csv)|*.csv")
	[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
	$objForm = New-Object System.Windows.Forms.OpenFileDialog
	$objForm.InitialDirectory = $Directory
	$objForm.Filter = $Filter
	$objForm.Title = $Title
	$objForm.ShowHelp = $true
	
	$Show = $objForm.ShowDialog()
	
	If ($Show -eq "OK")
	{
		Return $objForm.FileName
	}
	Else
	{
		Exit
	}
}

function LogErrorForMigration($fileOrFunction, $message, $scriptFile, $errorfilePath)
{
    $errorProperties = @{
                        FileOrFunction = $fileOrFunction;
                        ErrorMessage = $message;
                        ScriptFile = $scriptFile;                        
                    }

    $errorInfo = New-Object PSObject -Property $errorProperties
    $errorInfo | Export-Csv $errorfilePath -NoTypeInformation -Append
}

function WriteLog([string]$logstring)
{
    Write-Host $logstring 
    Add-content $gLogfile -value $logstring
}

function WriteLogWithColor([string]$logstring, [string]$fColor)
{	
    Write-Host $logstring -Foreground $fColor
    Add-content $gLogfile -value $logstring
}

function RemoveAllFilesInFolder($folder)
{    
    Get-ChildItem -Path $folder -Include *.* -Recurse | foreach { $_.Delete()}
}

function CalculateDuration($startTime, $endTime)
{
    return ($endTime - $startTime)
}
