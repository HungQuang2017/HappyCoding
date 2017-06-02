function GetTextField([Microsoft.SharePoint.SPListItem]$listItem,[string]$fieldName)
{
    return $listItem[$fieldName].ToString(); 
}

function SetTextField([Microsoft.SharePoint.SPListItem]$listItem,[string]$fieldName, [string]$value)
{
    $listItem[$fieldName] = $value;            
}

function GetRichTextField([Microsoft.SharePoint.SPListItem]$listItem,[string]$fieldName)
{
    return $listItem[$fieldName].ToString(); 
}

function SetRichTextField([Microsoft.SharePoint.SPListItem]$listItem,[string]$fieldName, [string]$value)
{
    $listItem[$fieldName] = $value;            
}

function GetBooleanField([Microsoft.SharePoint.SPListItem]$listItem,[string]$fieldName)
{
    return $listItem[$fieldName]; 
}

function SetBooleanField([Microsoft.SharePoint.SPListItem]$listItem,[string]$fieldName, [boolean]$value)
{
    $listItem[$fieldName] = $value;            
}

function GetNumberField([Microsoft.SharePoint.SPListItem]$listItem,[string]$fieldName)
{
    return [Double]$listItem[$fieldName]; 
}

function SetNumberField([Microsoft.SharePoint.SPListItem]$listItem,[string]$fieldName, [Double]$value)
{
    $listItem[$fieldName] = $value;            
}

function GetDateField([Microsoft.SharePoint.SPListItem]$listItem,[string]$fieldName)
{
    return [DateTime]$listItem[$fieldName]; 
}

function SetDateField([Microsoft.SharePoint.SPListItem]$listItem,[string]$fieldName, [DateTime]$value)
{
    $listItem[$fieldName] = $value;            
}

function GetChoiceField([Microsoft.SharePoint.SPListItem]$listItem,[string]$fieldName)
{
    return $listItem[$fieldName].ToString();
}

function SetChoiceField([Microsoft.SharePoint.SPList]$list,[Microsoft.SharePoint.SPListItem]$listItem,[string]$fieldName, [string]$value)
{
    $listItem[$fieldName] = $list.Fields[$fieldName].GetFieldValue($value);            
}

function GetMultiChoiceField([Microsoft.SharePoint.SPListItem]$listItem,[string]$fieldName)
{
    $multichoicevalues = New-Object Microsoft.SharePoint.SPFieldMultiChoiceValue($listItem[$fieldName].ToString());            
    return $multichoicevalues;             
}

function SetMultiChoiceField([Microsoft.SharePoint.SPList]$list,[Microsoft.SharePoint.SPListItem]$listItem,[string]$fieldName, [Microsoft.SharePoint.SPFieldMultiChoiceValue]$choicevalues)
{
    $list.Fields[$fieldName].ParseAndSetValue($listItem,$choicevalues);             
}

function GetPersonField($destWeb, [Microsoft.SharePoint.SPListItem]$listItem,[string]$fieldName)
{
    $userfield = New-Object Microsoft.SharePoint.SPFieldUserValue($destWeb,$listItem[$fieldName].ToString());
    return $userfield;
}

function SetPersonField($destWeb,[Microsoft.SharePoint.SPListItem]$listItem,[string]$fieldName, [Microsoft.SharePoint.SPFieldUserValue]$value)
{
    $destUser = $destWeb.EnsureUser($value.User);
    $listItem[$fieldName] = $destUser;            
}

function GetMultiPersonField($destWeb, [Microsoft.SharePoint.SPListItem]$listItem,[string]$fieldName)
{
    $users = New-Object Microsoft.SharePoint.SPFieldUserValueCollection($destWeb, $listItem[$fieldName].ToString()); 
    return $users;
}

function SetMultiPersonField([Microsoft.SharePoint.SPList]$list,[Microsoft.SharePoint.SPListItem]$listItem,[string]$fieldName, [Microsoft.SharePoint.SPFieldUserValueCollection]$value)
{
    $list.Fields[$fieldName].ParseAndSetValue($listItem,$value);
}

function GetLookupField([Microsoft.SharePoint.SPListItem]$listItem,[string]$fieldName)
{
    $lookupfieldvalue = $listItem[$fieldName] -as [Microsoft.SharePoint.SPFieldLookupValue]          
    return $lookupfieldvalue.LookupValue;     
}

function SetLookupField($destWeb, [string]$lookUpListName,[Microsoft.SharePoint.SPListItem]$listItem,[string]$fieldName, [int]$value)
{
    $lookuplist = GetSPList $destWeb $lookUpListName
    $lookupitem = $lookuplist.GetItemById($value) 
    $lookupvalue = New-Object Microsoft.SharePoint.SPFieldLookupValue($lookupitem.ID,$lookupitem.ID.ToString());            
    $listItem[$fieldName] = $lookupvalue;  
}

function SetLookupFieldByValue($destWeb, [string]$lookUpListName,[Microsoft.SharePoint.SPListItem]$listItem,[string]$fieldName, [string]$value)
{
    $lookuplist = GetSPList $destWeb $lookUpListName
    
    if($lookuplist -ne $null) {
        $caml = '<Where>
                  <Eq>
                    <FieldRef Name="Title" />
                    <Value Type="Text">' +
                      $value +
                    '</Value>
                  </Eq>
                </Where>'
	
        #$listItems = $lookuplist.GetItems($spQuery)
        $listItems = GetItemsByCamlQuery $lookuplist $caml

        foreach($lookupitem in $listItems){ 
            $lookupvalue = New-Object Microsoft.SharePoint.SPFieldLookupValue($lookupitem.ID,$lookupitem.Name.ToString());            
            #$listItem[$fieldName] = $lookupitem.ID.ToString() + ";#" + $lookupitem.Name.ToString();  
            $listItem[$fieldName] = $lookupvalue;  
       
            break
        }
    }    

    #update multi values
    <#
        SPFieldLookupValueCollection itemValues = SPFieldLookupValueCollection();
itemValues.Add(new SPFieldLookupValue(1, "Title"));
item["FieldName"] = itemValues;
item.Update();
    #>
}

function GetHyperlinkField([Microsoft.SharePoint.SPListItem]$listItem,[string]$fieldName)
{
    $hyperlink = $listItem[$fieldName] -as [Microsoft.SharePoint.SPFieldUrlValue]; 
    return $hyperlink;
}

function SetHyperlinkField([Microsoft.SharePoint.SPListItem]$listItem,[string]$fieldName, [string]$value)
{
    $hyperlinkfield = $listItem.Fields[$fieldName] -as [Microsoft.SharePoint.SPFieldUrl];  
    $hyperlinkfield.ParseAndSetValue($listItem,$value);             
}

function GetManagedMetadataField($destWeb, [Microsoft.SharePoint.SPListItem]$listItem,[string]$fieldName)
{
    $taxFieldValue = $listItem[$fieldName] -as [Microsoft.SharePoint.Taxonomy.TaxonomyFieldValue]; 
    return $taxFieldValue;
}

function SetManagedMetadataField($destWeb,[Microsoft.SharePoint.SPList]$list,[Microsoft.SharePoint.SPListItem]$listItem,[string]$fieldName, [Microsoft.SharePoint.SPFieldUserValueCollection]$value)
{
    #$managedmetadataField = $l.Fields["managedmetadatafield"] -as [Microsoft.SharePoint.Taxonomy.TaxonomyField];            
    #$tsId = $managedmetadataField.TermSetId;            
    #$termStoreId = $managedmetadataField.SspId;            
    #$tsession = Get-SPTaxonomySession -Site $l.ParentWeb.Site;            
    #$tstore =  $tsession.TermStores[$termStoreId];              
    #$tset = $tstore.GetTermSet($tsId);                  
    #$termName = "Frog Catchers";            
    #$terms = $tset.GetTerms($termName,$false);            
    #$term = $null;            
    #if($terms.Count -eq 0)            
    #{            
     #Write-Host ([String]::Format("Creating Term, {0}",$termName)) -ForegroundColor DarkYellow;            
     #$term = $tset.CreateTerm($termName, $tstore.Languages[0]);            
     #$tstore.CommitAll();            
    #}             
    #else            
    #{            
     #$term = $terms[0];            
    #}            
    #$managedmetadataField.SetFieldValue($i,$term);            
    #$i.Update(); 
}

function GetPublishingImageField($listItem,[string]$fieldName)
{
    return $listItem[$fieldName] 
}

function SetPublishingImageField($listItem,[string]$fieldName, [Microsoft.SharePoint.Publishing.Fields.ImageFieldValue]$value,$sourceWebRelativeUrl,$destWebRelativeUrl)
{
    $imageUrl = $value.ImageUrl
    WriteLog("ImageUrl = " + $value.ImageUrl) 

    $imageUrl = FixUrl $sourceWebRelativeUrl $destWebRelativeUrl $imageUrl
    WriteLog("ImageUrl fixing = " + $imageUrl)

    $value.ImageUrl = $imageUrl

	$listItem[$fieldName]=$value 
}

function FixUrl($sourceWebRelativeUrl,$destWebRelativeUrl, $value)
{
    return $value.Replace($sourceWebRelativeUrl, $destWebRelativeUrl)
}

function SetStringField($listItem, [string]$fieldName,$value,$sourceWebRelativeUrl,$destWebRelativeUrl, $destWeb)
{
    $value = FixUrl $sourceWebRelativeUrl $destWebRelativeUrl $value
    $listItem[$fieldName]=$value
}

function SetSummaryLinkField($listItem, [string]$fieldName,[Microsoft.SharePoint.Publishing.Fields.SummaryLinkFieldValue]$value,$sourceWebRelativeUrl,$destWebRelativeUrl, $destWeb)
{
    $summaryLinkFieldValue = New-Object Microsoft.SharePoint.Publishing.Fields.SummaryLinkFieldValue
        
    $summaryLinks = $value.SummaryLinks
    foreach($link in $summaryLinks) 
    {
        $linkValue = FixUrl $sourceWebRelativeUrl $destWebRelativeUrl $link.LinkUrl
        $link.LinkUrl = $linkValue
        WriteLog("Link = " + $linkValue)

        $summaryLinkFieldValue.SummaryLinks.Add($link)

        if($linkValue.Contains($destWebRelativeUrl)) {
            $message = "List Name = Pages" + ", Item ID = " + $listItem.ID + ", URL =" + $linkValue
            $existedValue = CheckLinkIsExistedInSite $destWeb $linkValue $message
        }
    }
		
	$listItem[$fieldName]=$summaryLinkFieldValue
}

function GetAndSetFieldToListItem($fieldName, [Microsoft.SharePoint.SPFieldType]$fType, [Microsoft.SharePoint.SPListItem]$newItem, 
                                    [Microsoft.SharePoint.SPListItem]$item, $destList, $destWeb)
{
    trap {
        WriteLog("GetAndSetFieldToListItem() - ERROR " + $_.Exception.Message + " : " + $_.InvocationInfo.ScriptName)
        LogErrorForMigration "GetAndSetFieldToListItem()" $_.Exception.Message $_.InvocationInfo.ScriptName $gErrorFilePath
        continue
    }        

    switch ($fType)
	{
	    "Text" { 
            $value = GetTextField $item $fieldName            
            $value = CheckHyperLinkInText $value

            WriteLog("Text Fixing Value = " + $value)

            SetTextField $newItem $fieldName $value
        }
		"Note" { 
            $value = GetRichTextField $item $fieldName
            #GetAllLinksInText $value

            $value = CheckHyperLinkInText $value
            WriteLog("Text Fixing Value = " + $value)            

            SetRichTextField $newItem $fieldName $value 
        }
		"DateTime" { 
            $value = GetDateField $item $fieldName
            SetDateField $newItem $fieldName $value 
        }
        "Choice" { 
            $value = GetChoiceField $item $fieldName
            $newItem[$fieldName] = $value;
            #SetChoiceField $destList $newItem $fieldName $value 
        }
        "Boolean" { 
            $value = GetBooleanField $item $fieldName
            SetBooleanField $newItem $fieldName $value  
        }
        "Number" { 
            $value = GetNumberField $item $fieldName
            SetNumberField $newItem $fieldName $value  
        }
        "URL" { 
            $value = GetHyperlinkField $item $fieldName

            $itemValue = $value.URL
            $itemValue = CheckHyperLinkInText $itemValue            

            WriteLog("Link Fixing Value = " + $itemValue)
            $value.URL = $itemValue

            SetHyperlinkField $newItem $fieldName $value 
        }
        "MultiChoice" { 
            $value = GetMultiChoiceField $item $fieldName
            SetMultiChoiceField $destList $newItem $fieldName $value 
        }			
        "User" { 
            $value = GetPersonField $destWeb $item $fieldName
            SetPersonField $destWeb $newItem $fieldName $value 
        }
        "MultiUser" { 
            $value = GetMultiPersonField $destWeb $item $fieldName
            SetMultiPersonField $destList $newItem $fieldName $value 
        }    
        "Lookup" { 
            $value = GetLookupField $item $fieldName
            SetLookupField $destWeb "" $newItem $fieldName $value 
        }
	}
}
