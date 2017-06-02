function CreateSiteColumns([string]$dataFileName){
    #$fullPath = $gDataPath + $dataFileName
	$siteData = GetXmlStructure($dataFileName)
	$url = ExpandURI $siteData.Web.Url
	#if($spWeb -eq $null){
	$spWeb = Get-SPWeb $url
	#}
	if($spWeb -eq $null){
		Write-Host "Invalid web url $url"
		return
	}
	Write-Host "Creating site columns..."
	$siteData.Web.Data.Fields.Field | foreach {
		Create-Field $spWeb $_
	}
	$spWeb.Update()
	$spWeb.Dispose();
}

function Create-Field([Microsoft.SharePoint.SPWeb]$spWeb, $fieldData)
{
	trap {
        continue
    }
    
    $web = $spWeb
	$taxField = $spWeb.Fields.GetFieldByInternalName($fieldData.Name)
	
    $termGroup = GetTermGroup $fieldData.TermSet

	if($taxField -eq $null){
        # create column
		Write-Host "Creating column: " $fieldData.Name
		trap {
	        Write-Warning ('Failed to create column '+$fieldData.Name+'! "{0}" at {1}' -f $_.Exception.Message, $_.InvocationInfo.ScriptName)
	        continue
	    }
		if($fieldData.Type -eq "TaxonomyFieldType")
		{
            
            #Write-Host ($spWeb.Site.PortalName) -ForegroundColor yellow
			$termSet = Get-TermSet $web.Site $gManagedMetadataServiceTermStore $termGroup $fieldData.TermSet		
			$taxonomyField = $web.Fields.CreateNewField($fieldData.Type, $fieldData.DisplayName)
			$taxonomyField.StaticName = $fieldData.Name
			$taxonomyField.Description = $fieldData.Description
			$taxonomyField.Group = $fieldData.Group
            $taxonomyField.IsPathRendered = $true 
			$taxonomyField.SspId = $termSet.TermStore.ID
			$taxonomyField.TermSetId = $termSet.Id
            $required= $false;
            if($fieldData.Required-eq "TRUE")
            {
                $required=$true
            }
			$taxonomyField.Required = $required
            $allowMulti= $false;
            if($fieldData.AllowMultipleValues-eq "TRUE")
            {
                $allowMulti=$true
            }
            
			$taxonomyField.AllowMultipleValues = $allowMulti
			if(($fieldData.TermName -ne $null) -and ($fieldData.TermName -ne "")){
				$oTerm = FindTermByLabel $web.Site $fieldData.TermName $termSetName $termGroup $gManagedMetadataServiceTermStore
				#FindTerm $web.Site $gManagedMetadataServiceTermStore $termSet.Id $fieldData.TermName
				$taxonomyField.AnchorId = $oTerm.Id
			}
			if(($fieldData.DefaultValue -ne $null) -and ($fieldData.DefaultValue -ne "")){
				$EngTerm = FindTermByLabel $web.Site $fieldData.DefaultValue $termSetName $termGroup $gManagedMetadataServiceTermStore
				#FindTerm $web.Site $gManagedMetadataServiceTermStore $termSet.Id $fieldData.DefaultValue
				$taxonomyField.DefaultValue = "1033;#" + $EngTerm.Name + "|" + $EngTerm.Id
			}
			$web.Fields.Add($taxonomyField);
		}
		else{
				$fieldXML = $fieldData.OuterXMl
	 			$taxonomyField = $web.Fields.AddFieldAsXml($fieldXML)

                # update lookup field
                if (($fieldData.Type -eq "Lookup") -or ($fieldData.Type -eq "LookupMulti"))
                {
                    $listID = $spWeb.Lists[$fieldData.List].ID
                    
                    $field = $spWeb.Fields[$fieldData.DisplayName]

                    $field.SchemaXml = $field.SchemaXml.Replace("List='"+ $fieldData.List + "'", "List='{"+ $listID.ToString() + "}'")
                    
                    $field.SchemaXml = $field.SchemaXml.Replace('List="'+ $fieldData.List + '"', 'List="{'+ $listID.ToString() + '}"')
                    
                    $field.Update($true)
                }
		}
        $web.Update()
	}
	else{
        #todo: check the logic here
		Write-Host "Column " $fieldData.Name " is existed!"
		<#if($taxField.TypeAsString -eq "TaxonomyFieldType")
		{
			#Use termset in XML file
			$termSet = Get-TermSet $web.Site $gManagedMetadataServiceTermStore $termGroup $fieldData.TermSet
			$taxField.SspId = $termSet.TermStore.Id
			$taxField.TermSetId = $termSet.Id
			$taxField.Required = [System.Convert]::ToBoolean($fieldData.Required)
			$taxField.AllowMultipleValues = [System.Convert]::ToBoolean($fieldData.AllowMultipleValues)
			if(($fieldData.TermName -ne $null) -and ($fieldData.TermName -ne "")){
				$CountryTerm = FindTermByLabel $web.Site $fieldData.TermName $termSet.Name $gGSCTermGroup $gManagedMetadataServiceTermStore
				$taxField.AnchorId = $CountryTerm.Id
			}
			if(($fieldData.DefaultValue -ne $null) -and ($fieldData.DefaultValue -ne ""))
			{
				$EngTerm = FindTermByLabel $web.Site $fieldData.DefaultValue $termSet.Name $gGSCTermGroup $gManagedMetadataServiceTermStore
				$taxField.DefaultValue = "1033;#" + $EngTerm.Name + "|" + $EngTerm.Id
			}
		}
		$taxField.Title = $fieldData.DisplayName
		$taxField.Description = $fieldData.Description
		if(($fieldData.Validation -ne $null) -and ($fieldData.Validation -ne ""))
		{
			$taxField.ValidationFormula = $fieldData.Validation.InnerText
		}
		$taxField.Update($true)#>
	}
	$web.Update()

    
}

function Get-TermSet([Microsoft.SharePoint.SPSite]$spSite,[string]$termStoreName=$null, [string]$groupName, [string]$termSetName)
{	
    $session = New-Object Microsoft.SharePoint.Taxonomy.TaxonomySession($spSite)
	#$serviceApp = Get-SPServiceApplication | Where {$_.TypeName -like "*Metadata*"}
  	#Write-Host "Getting Service Application " $serviceApp.Name
	
	$termStore = $null
	if(($termStoreName -eq $null) -or ($termStoreName -eq ""))
	{
	    $termStore = $session.DefaultKeywordsTermStore
	}
	else
	{
	    $termStore = $session.TermStores[$termStoreName] 
	}
	
  	#$termStore = $session.TermStores[$serviceApp.Name]
  	Write-Host "Get Term Store " $termStore.Name
  	Write-Host "Getting term set $termSetName from group" $groupName
  	$termSet =  $termStore.Groups[$groupName].TermSets[$termSetName]
  	return $termSet
}

function FindTermByLabel([Microsoft.SharePoint.SPSite]$spSite, [string]$termLabel, [string]$termSetName, [string]$groupName, [string]$termStoreName=$null, [int]$lcid=1033)
{
  $termSet = FindTermSet $spSite $termSetName $groupName $termStoreName $lcid
  $term = $null
  $termSet.GetAllTerms() | foreach { if($_.Name -eq $termLabel) {$term = $_} }
  return $term
}

function FindTermSet([Microsoft.SharePoint.SPSite]$spSite, [string]$termSetName, [string]$groupName, [string]$termStoreName=$null, [int]$lcid=1033)
{
  $session = New-Object Microsoft.SharePoint.Taxonomy.TaxonomySession($spSite)
  $termStore = $null
  if(($termStoreName -eq $null) -or ($termStoreName -eq ""))
  {
    $termStore = $session.DefaultKeywordsTermStore
  }
  else
  {
    $termStore = $session.TermStores[$termStoreName]
  }
  $termSets = $termStore.GetTermSets($termSetName, $lcid)
  $termSet = $null
  $termSets | foreach { if($_.Group.Name -eq $groupName) { $termSet = $_ } }
  
  return $termSet
}

function CreateFieldByXml($destList, $fieldXML, $fieldName)
{
    WriteLog("Create Field Name = " + $fieldName)

	trap {
        Write-Warning ('CreateFieldByXml() ERROR "{0}" : {1}' -f $_.Exception.Message, $_.InvocationInfo.ScriptName)

        $message = "CreateFieldByXml() - Failed to create column: " + $fieldName
        LogErrorForMigration $message $_.Exception.Message $_.InvocationInfo.ScriptName $gErrorFilePath
        continue
    }

    $testField = $destList.Fields.GetFieldByInternalName($fieldName)
    if(($testField -eq $null) -and ($testField.Type -ne "Lookup")) {        
        $field = $destList.Fields.AddFieldAsXml($fieldXML)
        $destList.Update()
    }

    $field = $destList.Fields.GetFieldByInternalName($fieldName)
    return $field
}