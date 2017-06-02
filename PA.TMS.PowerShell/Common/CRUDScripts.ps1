############################## GET LIST ITEM
function GetSPList($spWeb, $listName)
{
    $lstObj = $spWeb.Lists[$listName]     
    return $lstObj
}

function GetSPListByUrl($spWeb, $listUrl)
{
    $lstObj = $spWeb.GetList($listUrl)
    return $lstObj
}

function GetItemById($spList, [int]$itemId)
{
    $spListItem = $spList.GetItemById($itemId)
    return $spListItem
}

function GetItemsByCamlQuery($spList, [string] $camlQuery) {
    $spQuery = new-object Microsoft.SharePoint.SPQuery

    $spQuery.Query = $camlQuery
    $spQuery.RowLimit = 100
    $spListItemCollection = $spList.GetItems($spQuery)

    return $spListItemCollection
}

function GetContentType($spWeb,$spList,$ctName)    
{
    $ct = $spWeb.ContentTypes[$ctName]
    if($ct -eq $null) 
    {
        $ct = $spList.ContentTypes[$ctName]       
    }

    return $ct
}

function CheckAndEnsureUser($destWeb, $logonName, $championUser, $fieldValue)
{
    try
    {
        $spUser = $destWeb.EnsureUser($logonName)
        WriteLog("Adding " + $spUser)        
    }
    catch
    {
        $spUser = $championUser
        WriteLog($fieldValue + " does not exists. Replaced it by Champion User")
    } 

    return $spUser
}


function CheckFieldIsExistedInList($destList, $fieldName)
{
    try
    {
        $testField = $destList.Fields.GetFieldByInternalName($fieldName)  
        return $true      
    }
    catch
    {
        return $false
    } 
}

function CheckIllegalCharacters ($folderName)
{
    WriteLog("Checking illegal charaters in: " + $folderName)
    $newFileName = $folderName
           
    #Check if item name is 128 characters or more in length
    if ($folderName.Length -gt 127)
    {
        #Write-Host $type $item.Name is 128 characters or over and will need to be truncated -ForegroundColor Red
        WriteLog($folderName + " is 128 characters or over and will need to be truncated")
    }
    else
    {
            #Got this from http://powershell.com/cs/blogs/tips/archive/2011/05/20/finding-multiple-regex-matches.aspx
            $illegalChars = "[&{}~#%]"
            filter Matches($illegalChars)
            {
                $folderName | Select-String -AllMatches $illegalChars |
                Select-Object -ExpandProperty Matches
                Select-Object -ExpandProperty Values
            }
               
            #Replace illegal characters with legal characters where found            
            Matches $illegalChars | ForEach-Object {
                #Write-Host $type $item.FullName has the illegal character $_.Value -ForegroundColor Red
                #These characters may be used on the file system but not SharePoint
                if ($_.Value -match "&") { $newFileName = ($newFileName -replace "&", "and") }
                if ($_.Value -match "{") { $newFileName = ($newFileName -replace "{", "(") }
                if ($_.Value -match "}") { $newFileName = ($newFileName -replace "}", ")") }
                if ($_.Value -match "~") { $newFileName = ($newFileName -replace "~", "-") }
                if ($_.Value -match "#") { $newFileName = ($newFileName -replace "#", "") }
                if ($_.Value -match "%") { $newFileName = ($newFileName -replace "%", "") }                
            }
               
            #Check for start, end and double periods
            if ($newFileName.StartsWith(".")) {  WriteLog($folderName + " starts with a period") }
            while ($newFileName.StartsWith(".")) { $newFileName = $newFileName.TrimStart(".") }
            if ($newFileName.EndsWith(".")) { WriteLog($folderName + " ends with a period") }
            while ($newFileName.EndsWith("."))   { $newFileName = $newFileName.TrimEnd(".") }
            if ($newFileName.Contains("..")) { WriteLog($folderName + " contains double periods") }
            while ($newFileName.Contains(".."))  { $newFileName = $newFileName.Replace("..", ".") }
            if ($newFileName.Contains("'")) { WriteLog($folderName + " contains single quote") }
            while ($newFileName.Contains("'"))  { $newFileName = $newFileName.Replace("'", "") }                           
    } 
    
    return $newFileName       
}

function CreateFolderByName($folderName, $parentFolder, $rootFolder)
{
    $newFolder = $null
    if($folderName -and ($folderName -ne $rootFolder)) {
        $targetFolder = $destList.RootFolder.ServerRelativeUrl + $parentFolder
        $testFolder = $destList.ParentWeb.GetFolder($targetFolder + "/" + $folderName);
        if(!$testFolder -or ($testFolder.Exists -eq $false)) {
            $newFolder = $destList.Folders.Add($targetFolder, [Microsoft.SharePoint.SPFileSystemObjectType]::Folder, $folderName)
            $newFolder.Update(); 

            WriteLog("1st. Create new folder = " + $newFolder.url)
        }
    }

    return $newFolder
}

function CreateFoldersInLibrary($spList, $destList,[string]$destWebUrl, $migrationMode, $sourceFolderPath, $folderList, $sourceFolderLevel, $targetFolderLevel, $targetFolderPath, $migrateAll)
{     
    trap {
        WriteLog("CreateFoldersInLibrary() - ERROR " + $_.Exception.Message + " : " + $_.InvocationInfo.ScriptName)
        LogErrorForMigration "CreateFoldersInLibrary()" $_.Exception.Message $_.InvocationInfo.ScriptName $gErrorFilePath
        continue
    }

    $allFolders = $spList.Folders

    WriteLog("Total folders = " + $allFolders.Count.ToString())
    $folderCount = 0
    if($migrationMode -eq "Library") {
        foreach($folder in $allFolders) 
        { 
            WriteLog("......................................................................................")
            WriteLog("Folder Url = " + $folder.Url + ", Folder Name = " + $folder.Name)

            $parentFolderURL = ''
            $i = 0 
     
            $folderURL = $folder.url.Split("/") 
                 
            while($i -lt ($folderURL.count)) 
            {             
                if(($folderURL[$i] -ne $spList.Title) -and ($folderURL[$i] -ne $spList.RootFolder)) {                
                    $newFolder = CreateFolderByName $folderURL[$i] $parentFolderURL $spList.RootFolder.Url
                    if($newFolder) {
                        $folderCount++         
                        WriteLog("Folder Count = " + $folderCount.ToString())
                    }
                    $parentFolderURL = "$parentFolderURL/" + $folderURL[$i]
                }
                $i++ 
            }                              
        }
    }
    elseif($migrationMode -eq "ChangingFolder"){
        if($folderList -ne $null){
            foreach($folder in $allFolders) 
            { 
                WriteLog("......................................................................................")
                WriteLog("Folder Url = " + $folder.Url + ", Folder Name = " + $folder.Name)

                $parentFolderURL = ''
                $i = 0 
     
                $folderURL = $folder.url.Split("/") 
                 
                while($i -lt ($folderURL.count)) 
                {        
                    #if($folderURL.count -gt 0 -and $folderURL[1] -eq "Management"){
                    #    Write-Host "abc"
                    #}   
                    if(($folderURL[$i] -ne $spList.Title) -and ($folderURL[$i] -ne $spList.RootFolder)) { 
                        $isConfiguredFolder = $false
                        foreach ($folder in $folderList){
                            $sourceFolderLevel = $folder.SourceFolderUrl.Split("/").count - 1
                            $targetFolderLevel = $null
                            if($folder.TargetFolderUrl -ne $null){
                                $targetFolderLevel = $folder.TargetFolderUrl.Split("/").count - 1
                            }
                            
                            #if($folder.SourceFolderUrl.Split("/").count -gt 0 -and $i -eq 1 -and $folderURL[1] -eq $folder.SourceFolderUrl.Split("/")[1]){ 
                            #    $isConfiguredFolder = $true 
                            #}
                            if($folder.Type -eq "Discard" -and  $folderURL[$sourceFolderLevel] -eq $folder.SourceFolderUrl.Split("/")[$sourceFolderLevel]){
                                $isConfiguredFolder = $true
                                break
                            }
                            elseif($folder.Type -eq "Rename" -and  $folderURL[$sourceFolderLevel] -eq $folder.SourceFolderUrl.Split("/")[$sourceFolderLevel]){
                                $isConfiguredFolder = $true
                                #if($folderURL.count -gt 0 -and $folderURL[1] -eq "Management"){
                                #    $ab = ""
                                #    Write-Host "for debuging"
                                #}
                                if(!$parentFolderURL.Contains($folder.TargetFolderUrl)){
                                    $parentFolderURL = $parentFolderURL.Replace($folder.SourceFolderUrl, $folder.TargetFolderUrl)
                                }
                                #WriteLog("Create the target folder " + $folder.TargetFolderUrl + " for the source " + $folder.SourceFolderUrl)
                                $url = $folder.SourceFolderUrl.Split("/")
                                if($url.length -gt 0){
                                    $targetFolderName =  $folderURL[$i]
                                    if($url[$i] -eq $folderURL[$i]){
                                        $targetFolderName = $folder.TargetFolderUrl.split("/")[$i] 
                                    }
                                    $newFolder = CreateFolderByName $targetFolderName $parentFolderURL $spList.RootFolder.Url
                                    if($newFolder) {
                                        $folderCount++         
                                        WriteLog("Folder Count = " + $folderCount.ToString())
                                    }
                                    break
                                }  
                            }
                            elseif($folder.Type -eq "ChangingLevel"  -and  ($folderURL[$sourceFolderLevel] -eq $folder.SourceFolderUrl.Split("/")[$sourceFolderLevel]) -or $folder.SourceFolderUrl.split("/",[System.StringSplitOptions]::RemoveEmptyEntries).count -eq 0){
                                $isConfiguredFolder = $true
                                #if($folderURL.count -gt 0 -and $folderURL[1] -eq "Management"){
                                #    $ab = ""
                                #    Write-Host "for debuging"
                                #}
                                $sourceFolderArr = $folder.SourceFolderUrl.Split("/")
                                $targetFolderArr = $folder.TargetFolderUrl.Split("/")
                                
                                #increate level
                                if($targetFolderLevel -ne $null -and $targetFolderLevel -gt $sourceFolderLevel){
                                    $pfURL = ''
                                    foreach ($f in $targetFolderArr){
                                        $f = $f.Trim()
                                        if($f -eq '') { continue }
                                        CreateFolderByName $f $pfURL $spList.RootFolder.Url
                                        $pfURL = "$pfURL/" + $f
                                    }
                                } 
                                #decrease level
                                #elseif($targetFolderLevel -ne $null -and $targetFolderLevel -lt $sourceFolderLevel){
                                #    
                                #}
                                #decrease level from level 0 to level 1
                                #Because this is the mode changing level, so there is only one case that $targetFolderLevel equal $sourceFolderLevel
                                elseif($targetFolderLevel -ne $null -and $targetFolderLevel -eq $sourceFolderLevel){
                                    $pfURL = ''
                                    foreach ($f in $targetFolderArr){
                                        $f = $f.Trim()
                                        if($f -eq '') { continue }
                                        CreateFolderByName $f $pfURL $destList.RootFolder.Url
                                        $pfURL = "$pfURL/" + $f
                                    }
                                }
                                #WriteLog("Create the target folder " + $folder.TargetFolderUrl + " for the source " + $folder.SourceFolderUrl)
                                $url = $folder.SourceFolderUrl.Split("/")
                                if($url.length -gt 0){
                                    if($folder.SourceFolderUrl.split("/",[System.StringSplitOptions]::RemoveEmptyEntries).count -eq 0){
                                        if($parentFolderURL.Trim() -eq '' ){
                                            $parentFolderURL =  $folder.TargetFolderUrl + $parentFolderURL
                                        }
                                    }
                                    else{
                                        if(!$parentFolderURL.Contains($folder.TargetFolderUrl)){
                                            $parentFolderURL = $parentFolderURL.Replace($folder.SourceFolderUrl, $folder.TargetFolderUrl)
                                        }
                                    }
                                    $targetFolderName =  $folderURL[$i]
                                    if($url[$i] -eq $folderURL[$i]){
                                        $targetFolderName = $folder.TargetFolderUrl.split("/")[$i] 
                                    }
                                    $newFolder = CreateFolderByName $targetFolderName $parentFolderURL $spList.RootFolder.Url
                                    if($newFolder) {
                                        $folderCount++         
                                        WriteLog("Folder Count = " + $folderCount.ToString())
                                    }
                                    break
                                    
                                } 
                            }
                            if($folder.Type -eq "Normal" -and  $folderURL[$sourceFolderLevel] -eq $folder.SourceFolderUrl.Split("/")[$sourceFolderLevel]){
                                $newFolder = CreateFolderByName $folderURL[$i] $parentFolderURL $spList.RootFolder.Url
                                if($newFolder) {
                                    $folderCount++         
                                    WriteLog("Folder Count = " + $folderCount.ToString())
                                }
                                break
                            }                           
                        }
                        if($migrateAll -eq $true -and $isConfiguredFolder -eq $false){
                            $newFolder = CreateFolderByName $folderURL[$i] $parentFolderURL $spList.RootFolder.Url
                            if($newFolder) {
                                $folderCount++         
                                WriteLog("Folder Count = " + $folderCount.ToString())
                            }   
                        }
                        $parentFolderURL = "$parentFolderURL/" + $folderURL[$i]
                    }
                    $i++ 
                }                              
            }
        }
        else{
            WriteLog("Migrate in mode Archive for library: " + $spList.Title + " need to be defined the folder(s) " );
        }
    }
    ##elseif($migrationMode -eq "Archive"){
    ##    if($folderList -ne $null){
    ##        foreach($folder in $allFolders) 
    ##        { 
    ##            WriteLog("......................................................................................")
    ##            WriteLog("Folder Url = " + $folder.Url + ", Folder Name = " + $folder.Name)
    ##
    ##            $parentFolderURL = ''
    ##            $i = 0 
    ## 
    ##            $folderURL = $folder.url.Split("/") 
    ##             
    ##            while($i -lt ($folderURL.count)) 
    ##            {           
    ##                if(($folderURL[$i] -ne $spList.Title) -and ($folderURL[$i] -ne $spList.RootFolder)) { 
    ##                    $newFolder = $null 
    ##                    foreach ($folder in $folderList){
    ##                        $targetFolder = $destList.RootFolder.ServerRelativeUrl + $parentFolderURL + "/" + $folderURL[$i]
    ##                        $parentFolderURL = $parentFolderURL.Replace($folder.SourceFolderUrl, $folder.TargetFolderUrl)
    ##                        $realTargetFolderUrl = $destList.RootFolder.ServerRelativeUrl + $parentFolderURL + $folder.SourceFolderUrl
    ##                        if($realTargetFolderUrl -eq $targetFolder){
    ##                            WriteLog("Create the target folder " + $folder.TargetFolderUrl + " for the source " + $folder.SourceFolderUrl)
    ##                            $url = $folder.TargetFolderUrl.Split("/")
    ##                            if($url.length -gt 0){
    ##                                $targetFolderName = $url[$url.length - 1]
    ##                                $newFolder = CreateFolderByName $targetFolderName $parentFolderURL $spList.RootFolder.Url
    ##                                $newFolder = ""
    ##                                break
    ##                            }
    ##                        }
    ##                    }    
    ##                    if($newFolder -eq $null){   
    ##                        $newFolder = CreateFolderByName $folderURL[$i] $parentFolderURL $spList.RootFolder.Url
    ##                    }
    ##                    if($newFolder) {
    ##                        $folderCount++         
    ##                        WriteLog("Folder Count = " + $folderCount.ToString())
    ##                    }
    ##                    $parentFolderURL = "$parentFolderURL/" + $folderURL[$i]
    ##                }
    ##                $i++ 
    ##            }                              
    ##        }
    ##    }
    ##    else{
    ##        WriteLog("Migrate in mode Archive for library: " + $spList.Title + " need to be defined the folder(s) " );
    ##    }
    ##}
    elseif($migrationMode -eq "Folder"){
        $selectedSFolderLevel = $sourceFolderPath.Split("/").count - 1  
        foreach($folder in $allFolders) 
        { 
            WriteLog("......................................................................................")
            WriteLog("Folder Url = " + $folder.Url + ", Folder Name = " + $folder.Name)

            $parentFolderURL = ''
            $i = 0 

            $folderURL = $folder.url.Split("/")
            if($folderURL.count -ge $selectedSFolderLevel -and "/" + $folderURL[$selectedSFolderLevel] -eq $sourceFolderPath){                 
                while($i -lt ($folderURL.count)) 
                {             
                    if(($folderURL[$i] -ne $spList.Title) -and $folderURL[$i] -ne $spList.RootFolder -and "/" + $folderURL[$i] -ne $sourceFolderPath) { 
                        $isConfiguredFolder = $false
                        foreach ($folder in $folderList){
                            ##if($folderURL.count -gt 0 -and $folderURL[1] -eq "FSIS"){
                            ##    $ab = ""
                            ##    Write-Host "for debuging"
                            ##}

                            $sourceFolderLevel = $folder.SourceFolderUrl.Split("/").count - 1
                            $targetFolderLevel = $null
                            if($folder.TargetFolderUrl -ne $null){
                                $targetFolderLevel = $folder.TargetFolderUrl.Split("/").count - 1
                            }
                            
                            if($folder.Type -eq "Discard" -and  $folderURL[$sourceFolderLevel + $selectedSFolderLevel] -eq $folder.SourceFolderUrl.Split("/")[$sourceFolderLevel]){
                                $isConfiguredFolder = $true
                                break
                            }
                            elseif($folder.Type -eq "Rename" -and  $folderURL[$sourceFolderLevel + $selectedSFolderLevel] -eq $folder.SourceFolderUrl.Split("/")[$sourceFolderLevel]){
                                $isConfiguredFolder = $true
                                if(!$parentFolderURL.Contains($folder.TargetFolderUrl)){
                                    $parentFolderURL = $parentFolderURL.Replace($folder.SourceFolderUrl, $folder.TargetFolderUrl)
                                }
                                #WriteLog("Create the target folder " + $folder.TargetFolderUrl + " for the source " + $folder.SourceFolderUrl)
                                $url = $folder.SourceFolderUrl.Split("/")
                                if($url.length -gt 0){
                                    $targetFolderName =  $folderURL[$i]
                                    if($url[$i - $selectedSFolderLevel] -eq $folderURL[$i]){
                                        $targetFolderName = $folder.TargetFolderUrl.split("/")[$i - $selectedSFolderLevel] 
                                    }
                                    $newFolder = CreateFolderByName $targetFolderName $parentFolderURL $spList.RootFolder.Url
                                    if($newFolder) {
                                        $folderCount++         
                                        WriteLog("Folder Count = " + $folderCount.ToString())
                                    }
                                    break
                                }  
                            }
                            elseif($folder.Type -eq "ChangingLevel"  -and  $folderURL[$sourceFolderLevel + $selectedSFolderLevel] -eq $folder.SourceFolderUrl.Split("/")[$sourceFolderLevel]){
                                $isConfiguredFolder = $true
                                #if($folderURL.count -gt 0 -and $folderURL[1] -eq "FSIS"){
                                #    $ab = ""
                                #    Write-Host "for debuging"
                                #}
                                $sourceFolderArr = $folder.SourceFolderUrl.Split("/")
                                $targetFolderArr = $folder.TargetFolderUrl.Split("/")
                                
                                #increate level
                                if($targetFolderLevel -ne $null -and $targetFolderLevel -gt $sourceFolderLevel){
                                    $pfURL = ''
                                    foreach ($f in $targetFolderArr){
                                        $f = $f.Trim()
                                        if($f -eq '') { continue }
                                        CreateFolderByName $f $pfURL $spList.RootFolder.Url
                                        $pfURL = "$pfURL/" + $f
                                    }
                                } 
                                #decrease level
                                #elseif($targetFolderLevel -ne $null -and $targetFolderLevel -lt $sourceFolderLevel){
                                #    
                                #}
                                if(!$parentFolderURL.Contains($folder.TargetFolderUrl)){
                                    $parentFolderURL = $parentFolderURL.Replace($folder.SourceFolderUrl, $folder.TargetFolderUrl)
                                }
                                #WriteLog("Create the target folder " + $folder.TargetFolderUrl + " for the source " + $folder.SourceFolderUrl)
                                $url = $folder.SourceFolderUrl.Split("/")
                                if($url.length -gt 0){
                                    $targetFolderName =  $folderURL[$i]
                                    if($url[$i - $selectedSFolderLevel] -eq $folderURL[$i]){
                                        $targetFolderName = $folder.TargetFolderUrl.split("/")[$i - $selectedSFolderLevel] 
                                    }
                                    $newFolder = CreateFolderByName $targetFolderName $parentFolderURL $spList.RootFolder.Url
                                    if($newFolder) {
                                        $folderCount++         
                                        WriteLog("Folder Count = " + $folderCount.ToString())
                                    }
                                    break
                                } 
                            }                           
                        }
                        if($migrateAll -eq $true -and $isConfiguredFolder -eq $false){
                            $newFolder = CreateFolderByName $folderURL[$i] $parentFolderURL $spList.RootFolder.Url
                            if($newFolder) {
                                $folderCount++         
                                WriteLog("Folder Count = " + $folderCount.ToString())
                            }  
                        }
                        $parentFolderURL = "$parentFolderURL/" + $folderURL[$i]
                    }
                    $i++ 
                }        
            }                      
        }
    }
    else {
        foreach($folder in $allFolders) 
        { 
            WriteLog("......................................................................................")
            WriteLog("Folder Url = " + $folder.Url + ", Folder Name = " + $folder.Name)

            $parentFolderURL = ''
            $i = 0 
     
            if($folder.url.Contains($sourceFolderPath)) {
                $folderURL = $folder.url.Split("/") 
                 
                while($i -lt ($folderURL.count)) 
                {             
                    if(($folderURL[$i] -ne $spList.Title) -and ($folderURL[$i] -ne $spList.RootFolder)) {                
                        $newFolder = CreateFolderByName $folderURL[$i] $parentFolderURL $spList.RootFolder.Url
                        if($newFolder) {
                            $folderCount++         
                            WriteLog("Folder Count = " + $folderCount.ToString())
                        }
                        $parentFolderURL = "$parentFolderURL/" + $folderURL[$i]
                    }
                    $i++ 
                }        
            }                      
        }
    }
}


function AreArraysEqual($a1, $a2) {
    if ($a1 -isnot [array] -or $a2 -isnot [array]) { 
      throw "Both inputs must be an array"
    }
    if ($a1.Rank -ne $a2.Rank) { 
      return $false 
    }
    if ([System.Object]::ReferenceEquals($a1, $a2)) {
      return $true
    }
    for ($r = 0; $r -lt $a1.Rank; $r++) {
      if ($a1.GetLength($r) -ne $a2.GetLength($r)) {
            return $false
      }
    }
    $enum1 = $a1.GetEnumerator()
    $enum2 = $a2.GetEnumerator()   

    while ($enum1.MoveNext() -and $enum2.MoveNext()) {
      if ($enum1.Current -ne $enum2.Current) {
            return $false
      }
    }
    return $true
}

#a1 contain a2
function IsArraysContainedArray($a1, $a2) {
    if ($a1 -isnot [array] -or $a2 -isnot [array]) { 
      throw "Both inputs must be an array"
    }
    if ($a1.Rank -ne $a2.Rank) { 
      return $false 
    }
    if ([System.Object]::ReferenceEquals($a1, $a2)) {
      return $true
    }
    $enum1 = $a1.GetEnumerator()
    $enum2 = $a2.GetEnumerator()   

    while ($enum1.MoveNext() -and $enum2.MoveNext()) {
      if ($enum1.Current -ne $enum2.Current) {
            return $false
      }
    }
    return $true
}

function CreateFoldersInLibraryFromSharedFolder($sourceFolderPath, $destList,[string]$destWebUrl, $migrationMode, $sourceFolderPath01, $folderList, $sourceFolderLevel, $targetFolderLevel, $targetFolderPath, $migrateAll)
{     
    trap {
		$errorStr = "CreateFoldersInLibraryFromSharedFolder() - ERROR " + $_.Exception.Message + " : " + $_.InvocationInfo.ScriptName 
		WriteLogWithColor $errorStr "Red"
        LogErrorForMigration "CreateFoldersInLibraryFromSharedFolder()" $_.Exception.Message $_.InvocationInfo.ScriptName $gErrorFilePath
        continue
    }

    #$allFolders = $spList.Folders
	$allFolders = Get-ChildItem $sourceFolderPath -Recurse | where { $_.PSIsContainer }

    $folderCount = $allFolders.Count.ToString()
    WriteLogWithColor "Total folders = $folderCount" "Green"
    $folderCount = 0
    if($migrationMode -eq "Library") {
        foreach($folder in $allFolders) 
        { 
            WriteLog("......................................................................................")
            WriteLog("Folder Url = " + $folder.FullName + ", Folder Name = " + $folder.Name)

            $parentFolderURL = ''
            $i = 0 

            $foldersToCreate = $folder.FullName.Replace("$sourceFolderPath", "")
            $folderURL = $foldersToCreate.Split("\") 
                 
            while($i -lt ($folderURL.count)) 
            {             
                if($folderURL[$i] -ne "") {                
                    $newFolder = CreateFolderByName $folderURL[$i] $parentFolderURL ""
                    if($newFolder) {
                        $folderCount++         
                        WriteLog("Folder Count = " + $folderCount.ToString())
                    }
                    $parentFolderURL = "$parentFolderURL/" + $folderURL[$i]
                }
                $i++ 
            }                              
        }
    }
	elseif($migrationMode -eq "ChangingFolder"){
        if($folderList -ne $null){
            foreach($folder in $allFolders) 
            { 
                WriteLog("......................................................................................")
                WriteLog("Folder Url = " + $folder.FullName + ", Folder Name = " + $folder.Name)
                
                #if($folder.FullName.StartsWith("\\cscvieae520508\e$\SharedDrive\CCD\ccd2\ccd1-1\ccd1-1-1"))
                ##if($folder.FullName.StartsWith("\\cscvieae520508\e$\SharedDrive\CCD\ccd2\ccd1-2\ccd1-1-1\ccd1-1-1-1"))
                ##{
                ##    Write-host "ABC"
                ##}

                $parentFolderURL = ''
                $i = 0 
     
                $foldersToCreate = $folder.FullName.Replace("$sourceFolderPath", "")
                $folderURL = $foldersToCreate.Split("\") 
                 
                while($i -lt ($folderURL.count)) 
                {        
                    #if($folderURL.count -gt 0 -and $folderURL[1] -eq "Management"){
                    #    Write-Host "abc"
                    #}   
                    if($folderURL[$i] -ne "") { 
                        $isConfiguredFolder = $false
                        foreach ($folder in $folderList){
                            $sourceFolderLevel = $folder.SourceFolderUrl.Split("\").count - 1
                            $targetFolderLevel = $null
                            if($folder.TargetFolderUrl -ne $null){
                                $targetFolderLevel = $folder.TargetFolderUrl.Split("\").count - 1
                            }
                            
                            $IsArraysContainedArray = IsArraysContainedArray $folderURL $folder.SourceFolderUrl.Split("\")

                            #if($folder.SourceFolderUrl.Split("/").count -gt 0 -and $i -eq 1 -and $folderURL[1] -eq $folder.SourceFolderUrl.Split("/")[1]){ 
                            #    $isConfiguredFolder = $true 
                            #}
                            #if($folder.Type -eq "Discard" -and  $folderURL[$sourceFolderLevel] -eq $folder.SourceFolderUrl.Split("\")[$sourceFolderLevel]){
                            if($folder.Type -eq "Discard" -and $IsArraysContainedArray -eq $true){
                                $isConfiguredFolder = $true
                                break
                            }
                            #elseif($folder.Type -eq "Rename" -and  $folderURL[$sourceFolderLevel] -eq $folder.SourceFolderUrl.Split("\")[$sourceFolderLevel]){
                            elseif($folder.Type -eq "Rename" -and $IsArraysContainedArray -eq $true){
                                #in some cases, folder will be renamed and we need to get the real name.
                                $realFolderName = $folderURL[$i]
                                $isConfiguredFolder = $true
                                if(!$parentFolderURL.Contains($folder.TargetFolderUrl) -and $parentFolderURL.StartsWith($folder.SourceFolderUrl.Replace("\","/"))){
                                    $parentFolderURL = $parentFolderURL.Replace($folder.SourceFolderUrl.Replace("\","/"), $folder.TargetFolderUrl.Replace("\","/"))
                                }
                                #WriteLog("Create the target folder " + $folder.TargetFolderUrl + " for the source " + $folder.SourceFolderUrl)
                                $url = $folder.SourceFolderUrl.Split("\")
                                if($url.length -gt 0){
                                    $targetFolderName =  $realFolderName
                                    if($url[$i] -eq $folderURL[$i]){
                                        $targetFolderName = $folder.TargetFolderUrl.split("\")[$i] 
                                        $realFolderName = $targetFolderName
                                    }
                                    $newFolder = CreateFolderByName $targetFolderName $parentFolderURL $spList.RootFolder.Url
                                    if($newFolder) {
                                        $folderCount++         
                                        WriteLog("Folder Count = " + $folderCount.ToString())
                                    }
                                    break
                                }  
                            }
                            #elseif($folder.Type -eq "ChangingLevel" -and ($folderURL[$sourceFolderLevel] -eq $folder.SourceFolderUrl.Split("\")[$sourceFolderLevel]) -or $folder.SourceFolderUrl.split("\",[System.StringSplitOptions]::RemoveEmptyEntries).count -eq 0){
                            elseif(($folder.Type -eq "ChangingLevel" -and $IsArraysContainedArray -eq $true) -or $folder.SourceFolderUrl.split("\",[System.StringSplitOptions]::RemoveEmptyEntries).count -eq 0){
                                $isConfiguredFolder = $true
                                #if($folderURL.count -gt 0 -and $folderURL[1] -eq "Management"){
                                #    $ab = ""
                                #    Write-Host "for debuging"
                                #}
                                $sourceFolderArr = $folder.SourceFolderUrl.Split("\")
                                $targetFolderArr = $folder.TargetFolderUrl.Split("\")
                                
                                #increase level
                                if($targetFolderLevel -ne $null -and $targetFolderLevel -gt $sourceFolderLevel){
                                    $pfURL = ''
                                    foreach ($f in $targetFolderArr){
                                        $f = $f.Trim()
                                        if($f -eq '') { continue }
                                        CreateFolderByName $f $pfURL $spList.RootFolder.Url
                                        $pfURL = "$pfURL/" + $f
                                    }
                                }
                                #decrease level
                                #elseif($targetFolderLevel -ne $null -and $targetFolderLevel -lt $sourceFolderLevel){
                                #    
                                #}
                                #decrease level from level 0 to level 1
                                #Because this is the mode changing level, so there is only one case that $targetFolderLevel equal $sourceFolderLevel
                                elseif($targetFolderLevel -ne $null -and $targetFolderLevel -eq $sourceFolderLevel){
                                    $pfURL = ''
                                    foreach ($f in $targetFolderArr){
                                        $f = $f.Trim()
                                        if($f -eq '') { continue }
                                        CreateFolderByName $f $pfURL $destList.RootFolder.Url
                                        $pfURL = "$pfURL/" + $f
                                    }
                                }
                                #WriteLog("Create the target folder " + $folder.TargetFolderUrl + " for the source " + $folder.SourceFolderUrl)
                                $url = $folder.SourceFolderUrl.Split("\")
                                if($url.length -gt 0){
                                    ##if($folderURL[$i] -eq "ccd1a-1" -and $parentFolderURL -eq "/ccd1"){
                                    ##    write-host "abc"
                                    ##}
                                    #Case SourceFolderUrl = "\"
                                    if($folder.SourceFolderUrl.split("\",[System.StringSplitOptions]::RemoveEmptyEntries).count -eq 0){
                                        if($parentFolderURL.Trim() -eq '' ){
                                            $parentFolderURL =  $folder.TargetFolderUrl.Replace("\","/") + $parentFolderURL
                                        }
                                    }
                                    else{
                                        if(!$parentFolderURL.Contains($folder.TargetFolderUrl.Replace("\","/")) -and $parentFolderURL.StartsWith($folder.SourceFolderUrl.Replace("\","/"))){
                                            $parentFolderURL = $parentFolderURL.Replace($folder.SourceFolderUrl.Replace("\","/"), $folder.TargetFolderUrl.Replace("\","/"))
                                        }
                                    }
                                    $targetFolderName =  $folderURL[$i]
                                    ##if($targetFolderName -eq "ccd1a-1" -and $parentFolderURL -eq "/ccd1"){
                                    ##    write-host "abc"
                                    ##}
                                    if($url[$i] -eq $folderURL[$i]){
                                        $targetFolderName = $folder.TargetFolderUrl.split("\")[$i] 
                                    }
                                    $newFolder = CreateFolderByName $targetFolderName $parentFolderURL $spList.RootFolder.Url
                                    if($newFolder) {
                                        $folderCount++         
                                        WriteLog("Folder Count = " + $folderCount.ToString())
                                    }
                                    break
                                    
                                } 
                            }
                            #if($folder.Type -eq "Normal" -and  $folderURL[$sourceFolderLevel] -eq $folder.SourceFolderUrl.Split("\")[$sourceFolderLevel]){
                            if($folder.Type -eq "Normal" -and $IsArraysContainedArray -eq $true){
                                $newFolder = CreateFolderByName $folderURL[$i] $parentFolderURL $spList.RootFolder.Url
                                if($newFolder) {
                                    $folderCount++
                                    WriteLog("Folder Count = " + $folderCount.ToString())
                                }
                                break
                            }                           
                        }
                        if($migrateAll -eq $true -and $isConfiguredFolder -eq $false){
                            $newFolder = CreateFolderByName $folderURL[$i] $parentFolderURL $spList.RootFolder.Url
                            if($newFolder) {
                                $folderCount++         
                                WriteLog("Folder Count = " + $folderCount.ToString())
                            }   
                        }
                        if($realFolderName -ne $null -and $realFolderName.Trim() -ne "")
                        {
                            $parentFolderURL = "$parentFolderURL/" + $realFolderName
                            $realFolderName = $null
                        }
                        else
                        {
                            $parentFolderURL = "$parentFolderURL/" + $folderURL[$i]
                        }
                    }
                    $i++ 
                }                              
            }
        }
        else{
            WriteLog("Migrate in mode ChangingFolder: " + $spList.Title + " need to be defined the folder(s) " );
        }
    }
}


function CreateFoldersInList($spList, $destList,[string]$destWebUrl)
{     
    trap {
        WriteLog("CreateFoldersInList() - ERROR " + $_.Exception.Message + " : " + $_.InvocationInfo.ScriptName)
        LogErrorForMigration "CreateFoldersInList()" $_.Exception.Message $_.InvocationInfo.ScriptName $gErrorFilePath
        continue
    }

    $allFolders = $spList.Folders
    foreach($folder in $allFolders) 
    { 
        $parentFolderURL = ''
        $i = 0 
     
        #Break the Folder URL up into sections, separated by "/"
        $folderURL = $folder.url.Split("/") 
         
        #Perform a variable number of actions against the Folder URL based on the number of sections in FolderURL
        while($i -lt ($folderURL.count)) 
        { 
            #Keep apending the Folder section in order to build the parent folder URL
            if(($folderURL[$i] -ne $spList.Title) -and ($folderURL[$i] -ne "Lists")) {
                $parentFolderURL = "$parentFolderURL/" + $folderURL[$i] 
            }
            #Increment the I variable in order to move forward through the folder structure
            $i++ 
        } 
     
        try
        {

           <#$currentFolder = $destList.Folders | ? {$_.url -eq $parentFolderURL} 
            #If the destination list does not contain a folder with the same name, create it
            if(!($currentFolder.Folders | ? {$_.name -eq $folder.Name})) 
            { 
                if($parentFolderURL.LastIndexOf("/") -gt 0) {
                    $folderName = $parentFolderURL.Substring($parentFolderURL.LastIndexOf("/") + 1)
                }
                else {
                    $folderName = $parentFolderURL.Substring(1)
                }

                $targetFolder = $destList.RootFolder.ServerRelativeUrl + $parentFolderURL
                WriteLog("parent folder = " + $parentFolderURL)
                WriteLog("folder name = " + $folderName)

                #Create a Folder in the destination library with the same name as it had in the source library, in the same relative location
                <#$newFolder = $destList.Folders.Add($targetFolder, [Microsoft.SharePoint.SPFileSystemObjectType]::Folder, $folder.Name) 

                #Finalize creating the folder by calling update
                $newFolder.Update();             

                Write-Host "Create new folder = " $newFolder.url

                $newFolder = $destList.AddItem($targetFolder, [Microsoft.SharePoint.SPFileSystemObjectType]::Folder, $folderName)
                #$newFolder["Title"] = $folderName
                $newFolder.Update();

                Write-Host "Create new folder = " $newFolder.url

            } 
            else 
            { 
                #If the folder already exists, retrieve the folder where the file will be created
                $newFolder = $destList.Folders | ? {$_.name -eq $folder.Name} 
            }#>  
        }
        catch {
            WriteLog("CreateFoldersInList() - ERROR " + $_.Exception.Message + " : " + $_.InvocationInfo.ScriptName)
            LogErrorForMigration "CreateFoldersInList()" $_.Exception.Message $_.InvocationInfo.ScriptName $gErrorFilePath
            continue
        }        
    }
}

function GetListTemplate($sourceList)
{
    $listTemplate = $sourceList.BaseTemplate.ToString()
    WriteLog("List Template =" + $listTemplate)

    if($listTemplate -eq "10000") {
        $listTemplate = "GenericList"
    }

    if($listTemplate -eq "851") {
        $listTemplate = "PictureLibrary"
    }

    if($listTemplate -eq "TasksWithTimelineAndHierarchy") {
        $listTemplate = "Tasks"
    }

    if($listTemplate -eq "WebPageLibrary") {
        $listTemplate = "WikiPagelibrary"
    }

    return $listTemplate
}

function SetForceCheckOutOption($library,$value)
{
    $library.ForceCheckOut = $value;
    $library.Update();
}

function CheckHyperLinkInText($itemValue)
{
    if($gSourceWebRelativeUrl.Length -lt 2) {
        $sourceWebUrl = $sourceWeb.Url
        #$index = $itemValue.IndexOf($sourceWebUrl)
        WriteLog("source web url = " + $sourceWebUrl )
        if($itemValue.StartsWith($sourceWebUrl,"CurrentCultureIgnoreCase")) {
            return $itemValue.Substring($sourceWebUrl.Length).Trim()
        }

        return $itemValue
    }

    $itemValue = RemoveSourceWebUrlFromString $itemValue $gSourceWebRelativeUrl
    $itemValue = FixUrl $gSourceWebRelativeUrl $gDestWebRelativeUrl $itemValue

    return $itemValue
}

function RemoveSourceWebUrlFromString($itemValue,$gSourceWebRelativeUrl)
{
    trap {
        WriteLog("RemoveSourceWebUrlFromString() - ERROR " + $_.Exception.Message + " : " + $_.InvocationInfo.ScriptName)
        LogErrorForMigration "RemoveSourceWebUrlFromString()" $_.Exception.Message $_.InvocationInfo.ScriptName $gErrorFilePath
        continue
    }

    $index = $itemValue.IndexOf($gSourceWebRelativeUrl)
    WriteLog("Index = " + $index)
    if($index -gt 0) {
        $value = $itemValue.Substring(0, $index - 1).Trim() + $itemValue.Substring($index).Trim();
        return $value
    }

    return $itemValue
}

function AddFieldToExistingContentType($destWeb, $field, $ctype) {
    write-host "AddFieldToContentType, DisplayName = " $fieldData.DisplayName

	#$field = $destWeb.Fields.GetFieldByInternalName($fieldData.Name)         
	$fieldLink = new-object Microsoft.SharePoint.SPFieldLink($field)
    $fieldLink.DisplayName = $field.DisplayName
	$ctype.fieldlinks.add($fieldLink)    
	$ctype.update()       
}

function CreateCustomFieldAndAddToList($destWeb, $destList, $mainFields, $allFields, $siteContentType)
{
    trap {
        WriteLog("CreateCustomFieldAndAddToList() - ERROR " + $_.Exception.Message + " : " + $_.InvocationInfo.ScriptName)
        LogErrorForMigration "CreateCustomFieldAndAddToList()" $_.Exception.Message $_.InvocationInfo.ScriptName $gErrorFilePath
        continue
    }

    if($mainFields) {
        $listContentType = $siteContentType

        if($siteContentType -ne $null) {
            ####$destList = $destWeb.Lists[$destList.Title]
            $listContentType = $destList.ContentTypes[$siteContentType.Name]
        
            if($listContentType -and ($listContentType.ReadOnly -eq $true)) {
                $listContentType.ReadOnly = $false
                $listContentType.Update()    
                $destList.Update()                            
            }
        }    

        foreach ($field in $mainFields) {
            if($field -ne "Title")
            {                        
                $fieldName = $field 
                $existedField = CheckFieldIsExistedInList $destList $fieldName $destWeb
                if($existedField -eq $false) {
                    $fieldXml = GetFieldSchema $allFields $fieldName
                    WriteLog("Field Schema = " + $fieldXml)
                    $returnedField = CreateFieldByXml $destWeb $fieldXml $fieldName
            
                    if ($returnedField) {
                        if($listContentType -ne $null) {
                            WriteLog("Add field to content type")
                            AddFieldToExistingContentType $destWeb $returnedField $listContentType
                        }
                        else {
                            WriteLog("Add field to list")
                            $destList.Fields.Add($returnedField)
                        }
                    }   
                }                     
            }
        } 

        $destList.Update()
    }
}

function SetReadOnlyForContentType($spList, $contentType, $value)
{
    $contentType.ReadOnly = $value
    $contentType.update()
    $spList.update()
}

function GetFieldSchema($allFields, $fieldName, $destWeb)
{
    $fieldXml = $null
    foreach($field in $allFields) 
    { 
        if($field.InternalName -eq $fieldName)
        {
            $fieldXml = $field.SchemaXml                 
        }
    }

    if($fieldXml -eq $null) {
        $testField = $destWeb.Fields.GetFieldByInternalName($fieldName)
        if($testField -ne $null) {        
            $fieldXml = $testField.SchemaXml
        }
    }

    return $fieldXml
}

function CheckLinkIsExistedInSite($spWeb, $fileUrl, $message)
{
    if($message -eq $null) {
        $message = "LINK NOT FOUND: (" + $fileUrl + ")"
    }
    else {
        $message = "LINK NOT FOUND: (" + $message + ")"
    }

    try {
        $file = $spWeb.GetFile($fileUrl) 
        if (-not($file.Exists)) { 
            WriteLog($message)
            LogErrorForMigration "CheckLinkIsExistedInSite()" $message "CRUDScripts.ps1" $gErrorFilePath

            return $false      
        }

        return $true
    }
    catch {
        WriteLog($message)
        LogErrorForMigration "CheckLinkIsExistedInSite()" $message "CRUDScripts.ps1" $gErrorFilePath
        return $false
    }    
}

#Result: Discard, Existed and Item URL
function WillDocumentBeMigratedForUpdatedFolderMode($destWeb, $sourceFileUrl, $sourceListTitle, $destListTitle, $sourceRootFolder, $folderList, $migrationMode, $sourceFolderPath, $migrateAll)
{
    try {
        $sFileUrl = $sourceFileUrl
        ##if($sourceFileUrl.Contains("02 Research/XXX")){
        ##    Write-Host $sourceFileUrl
        ##    write-host "This is 02 Research"
        ##}
        ##if($sourceFileUrl.Contains("01 Legal Briefs")){
        ##    Write-Host $sourceFileUrl
        ##    write-host "This is 01 Legal Briefs"
        ##}
        ##if($sourceFileUrl.Contains("01 Legal Briefs/XXX")){
        ##    Write-Host $sourceFileUrl
        ##    write-host "This is 01 Legal Briefs"
        ##}
        ##if($sourceFileUrl.Contains("01 Legal Briefs/KKK")){
        ##    Write-Host $sourceFileUrl
        ##    write-host "This is 01 Legal Briefs"
        ##}
        ##if($sourceFileUrl.Split("/").count -eq 1){
        ##    Write-Host $sourceFileUrl
        ##    write-host "Item in root folder"
        ##}
        ##if(!$sourceFileUrl.Contains("01 Legal Briefs/XXX") -and $sourceFileUrl.Split("/").count -gt 3){
        ##    Write-Host $sourceFileUrl
        ##    write-host "Item in thrid level"
        ##}
        $folderURL = $sourceFileUrl.Split("/") 
        if($migrationMode -eq "ChangingFolder"){
            $isConfiguredFolder = $false
            foreach ($folder in $folderList){
                $sourceFolderLevel = $folder.SourceFolderUrl.Split("/").count - 1
                $targetFolderLevel = $null
                if($folder.TargetFolderUrl -ne $null){
                    $targetFolderLevel = $folder.TargetFolderUrl.Split("/").count - 1
                }

                #Write-host "Folder migration type: " $folder.Type
                #Write-host "Source folder url: " $folder.SourceFolderUrl
                #Write-host "Target folder url: " $folder.TargetFolderUrl
                if($folder.Type -eq "Discard" -and $folderURL[$sourceFolderLevel] -eq $folder.SourceFolderUrl.Split("/")[$sourceFolderLevel]){
                    $isConfiguredFolder = $true
                    return "Discard"
                }
                elseif($folder.Type -eq "Rename" -and  $folderURL[$sourceFolderLevel] -eq $folder.SourceFolderUrl.Split("/")[$sourceFolderLevel]){
                    $isConfiguredFolder = $true
                    if(!$sFileUrl.Contains($folder.TargetFolderUrl + "/")){
                        $sFileUrl = $sFileUrl.Replace($folder.SourceFolderUrl + "/", $folder.TargetFolderUrl + "/")
                    }
                    break  
                }
                elseif($folder.Type -eq "ChangingLevel"  -and  ($folderURL[$sourceFolderLevel] -eq $folder.SourceFolderUrl.Split("/")[$sourceFolderLevel]) -or $folder.SourceFolderUrl.split("/",[System.StringSplitOptions]::RemoveEmptyEntries).count -eq 0){
                    $isConfiguredFolder = $true
                    $sourceFolderArr = $folder.SourceFolderUrl.Split("/")
                    $targetFolderArr = $folder.TargetFolderUrl.Split("/")
                    
                    #increase level from level 1 to level 2
                    #Because this is the mode changing level, so there is only one case that $targetFolderLevel equal $sourceFolderLevel
                    if($targetFolderLevel -ne $null -and $targetFolderLevel -eq $sourceFolderLevel){
                        $f = $sFileUrl.Split('/')
                        [System.Collections.ArrayList]$ArrayList = $f
                        if($ArrayList.length -gt 0 -and $folder.TargetFolderUrl.Split('/').length -gt 1){
                            $ArrayList.Insert(1, $folder.TargetFolderUrl.Split('/')[1]) 
                            $sFileUrl = ($ArrayList -join '/')
                        }
                        break
                    }
                    elseif($targetFolderLevel -ne $null){
                        if(!$sFileUrl.Contains($folder.TargetFolderUrl)){
                            $sFileUrl = $sFileUrl.Replace($folder.SourceFolderUrl + "/", $folder.TargetFolderUrl + "/")
                        }
                        break
                    }
                }
                elseif($folder.Type -eq "Normal" -and  $folderURL[$sourceFolderLevel] -eq $folder.SourceFolderUrl.Split("/")[$sourceFolderLevel]){
                    $isConfiguredFolder = $true
                    break  
                }
            }
            #$sFileUrl = $sFileUrl.Replace($sourceListTitle + "/", $destListTitle + "/")
            #$sFileUrl = $sFileUrl.Replace($sourceRootFolder + "/", $destListTitle + "/")
            #if this item does not include in any configation folders and migrate all is false
            if($migrateAll -eq $false -and $isConfiguredFolder -eq $false){
                return "Discard"
            }

            $f = $sFileUrl.Split('/')
            if($f.length -gt 0){
                $f[0] = $destListTitle
                $sFileUrl = ($f -join '/')
            }
        
            WriteLog("Document Url In Target Site = (" + $sFileUrl + ")")
        
            $file = $destWeb.GetFile($sFileUrl) 
            if (-not($file.Exists)) { 
                return $sFileUrl      
            }
            return "Existed"
        }
        elseif($migrationMode -eq "Folder"){
            $isConfiguredFolder = $false
            $selectedSFolderLevel = $sourceFolderPath.Split("/").count - 1

            foreach ($folder in $folderList){
                $sourceFolderLevel = $folder.SourceFolderUrl.Split("/").count - 1
                $targetFolderLevel = $null
                if($folder.TargetFolderUrl -ne $null){
                    $targetFolderLevel = $folder.TargetFolderUrl.Split("/").count - 1
                }

                Write-host "Folder migration type: " $folder.Type
                Write-host "Source folder url: " $folder.SourceFolderUrl
                Write-host "Target folder url: " $folder.TargetFolderUrl
                if($folder.Type -eq "Discard" -and $folderURL[$sourceFolderLevel + $selectedSFolderLevel] -eq $folder.SourceFolderUrl.Split("/")[$sourceFolderLevel]){
                    $isConfiguredFolder = $true
                    return "Discard"
                }
                elseif($folder.Type -eq "Rename" -and  $folderURL[$sourceFolderLevel + $selectedSFolderLevel] -eq $folder.SourceFolderUrl.Split("/")[$sourceFolderLevel]){
                    $isConfiguredFolder = $true
                    if(!$sFileUrl.Contains($folder.TargetFolderUrl + "/")){
                        $sFileUrl = $sFileUrl.Replace($folder.SourceFolderUrl + "/", $folder.TargetFolderUrl + "/")
                    }
                    break  
                }
                elseif($folder.Type -eq "ChangingLevel"  -and  ($folderURL[$sourceFolderLevel + $selectedSFolderLevel] -eq $folder.SourceFolderUrl.Split("/")[$sourceFolderLevel])){
                    $isConfiguredFolder = $true
                    if($targetFolderLevel -ne $null -and !$sFileUrl.Contains($folder.TargetFolderUrl)){
                        $sFileUrl = $sFileUrl.Replace($folder.SourceFolderUrl + "/", $folder.TargetFolderUrl + "/")
                        break
                    }
                }
            }
            #$sFileUrl = $sFileUrl.Replace($sourceListTitle + "/", $destListTitle + "/")
            #$sFileUrl = $sFileUrl.Replace($sourceRootFolder + "/", $destListTitle + "/")
            #if this item does not include in any configation folders and migrate all is false
            if($migrateAll -eq $false -and $isConfiguredFolder -eq $false){
                return "Discard"
            }
            
            $sFileUrl = $sFileUrl.Substring($sFileUrl.IndexOf("/") + 1)
            $f = $sFileUrl.Split('/')
            if($f.length -gt 0){
                $f[0] = $destListTitle
                $sFileUrl = ($f -join '/')
            }
        
            WriteLog("Document Url in target site = (" + $sFileUrl + ")")
        
            $file = $destWeb.GetFile($sFileUrl) 
            if (-not($file.Exists)) { 
                return $sFileUrl  
            }
            return "Existed"
        }
    }
    catch {
        return $false
    }  
}


function CheckDocumentIsExistedOrNot($destWeb, $fileUrl, $sourceListTitle, $destListTitle, $sourceRootFolder, $targetRootFolder)
{
    try {
        #$fileUrl = $fileUrl.Replace($sourceListTitle, $destListTitle)
        $fileUrl = "/" + $fileUrl
        $fileUrl = $fileUrl.Replace("/" + $sourceRootFolder + "/", $targetRootFolder + "/")
        
        WriteLog("Document Url in target site = (" + $fileUrl + ")")
        
        $file = $destWeb.GetFile($fileUrl) 
        if (-not($file.Exists)) { 
            return $false      
        }

        return $true
    }
    catch {
        return $false
    }  
}

function CheckDocumentToArchiveIsExistedOrNot($destWeb, $file, $destListTitle, $folderList)
{
    try {
        $fileUrl = $null
        foreach($folder in $folderList){
            $f = $file.ParentFolder.Url.Split('/')
            $realFn = $folder.SourceFolderUrl.Substring(1)
            if($f.length -gt 0 -and $f[1] -eq $realFn){
                $f[1] = $folder.TargetFolderUrl.Substring(1)
                $fileUrl = ($f -join '/') + "/" + $file.Name #$file.Url.Replace($folder.SourceFolderUrl, $folder.TargetFolderUrl)
                break
            }
        }
        if($fileUrl -ne $null){
            WriteLog("Document Url in target site = (" + $fileUrl + ")")
        
            $file = $destWeb.GetFile($fileUrl) 
            if (-not($file.Exists)) { 
                return $false      
            }

            return $true
        }
        else{
            return $false
        }
    }
    catch {
        return $false
    }  
}

function SetDefaultContentType($spList, $ctName)
{
    if(!$ctName) {
        return
    }

    $result=New-Object System.Collections.Generic.List[Microsoft.SharePoint.SPContentType]
    $currentOrder = $spList.ContentTypes    
    foreach ($ct in $currentOrder)
    {
        if ($ct.Name -eq $ctName) {
            $result.Add($ct)
        }
    }
    $spList.RootFolder.UniqueContentTypeOrder = $result
    $spList.RootFolder.Update()
}
############################## ADD NEW LIST ITEM
function CreateListItemAtRoot($spList,$title)
{
    $newItem = $spList.AddItem()
    $newItem["Title"] = $title
    $newItem.Update()
    write-host "Item created: $title"

    return $newItem
}

function CreateListItemAtSpecificFolder()
{
    # Script settings
    $webUrl = "http://vs-server38"
    $listName = "OnePlace Licenses R7"
    $subFolderName = "OnePlaceDocs"
    $numberItemsToCreate = 10000
    $itemNamePrefix = "License "
     
    # Open web and library
    $web = Get-SPWeb $webUrl
    $list = $web.Lists[$listName]
     
    # Get handle on the subfolder
    $subFolder = $list.RootFolder.SubFolders.Item($subFolderName);
     
    # Create desired number of items in subfolder
    for($i=1; $i -le $numberItemsToCreate; $i++)
    {
        $newItemSuffix = $i.ToString("00000")
        $newItem = $list.AddItem($subFolder.ServerRelativeUrl, [Microsoft.SharePoint.SPFileSystemObjectType]::File, $null)
        $newItem["Title"] = "$itemNamePrefix$newItemSuffix"
        $newItem.Update()
        write-host "Item created: $itemNamePrefix$newItemSuffix"
    }    
}

function AddAttachmentToListItem($item, $attachmentFiles)  
{  
    trap {
        WriteLog("AddAttachmentToListItem() - ERROR " + $_.Exception.Message + " : " + $_.InvocationInfo.ScriptName)
        LogErrorForMigration "AddAttachmentToListItem()" $_.Exception.Message $_.InvocationInfo.ScriptName $gErrorFilePath
        continue
    }

    foreach ($attachment in $attachmentFiles)
    {
        $bytes = [System.IO.File]::ReadAllBytes($attachment)  
        $item.Attachments.Add([System.IO.Path]::GetFileName($attachment),$bytes)  
    } 
}

function GetListItemAttachments($spWeb, $item, $filePath)  
{  
    trap {
        WriteLog("GetListItemAttachments() - ERROR " + $_.Exception.Message + " : " + $_.InvocationInfo.ScriptName)
        LogErrorForMigration "GetListItemAttachments()" $_.Exception.Message $_.InvocationInfo.ScriptName $gErrorFilePath
        continue
    }

    $attachmentFiles = @()

    WriteLog("Attachments = " + $item.Attachments)

    # Loop thru each attachment
    foreach ($attachment in $item.Attachments)
    {
        # Get the attachment
        $file = $spWeb.GetFile($item.Attachments.UrlPrefix + $attachment)
        $bytes = $file.OpenBinary()
   
        # Build the destination path
        $path = $filePath + '\' + $attachment
        $attachmentFiles += $path

        WriteLog("Saving $path")
   
        # Download the file to the path
        [System.IO.FileStream] $fs = new-object System.IO.FileStream($path, "OpenOrCreate")
        $fs.Write($bytes, 0 , $bytes.Length)
        $fs.Close()        
    }  

    return $attachmentFiles
}

############################## DELETE LIST ITEM
function DeleteItemById($spList, [int]$itemId)
{
    $spListItem = $spList.GetItemById($itemId)
    $spListItem.Delete()
}

function DeleteMultipleItems($spList, $spListItemCollection)
{
    # Create batch remove CAML query
    $batchRemove = '<?xml version="1.0" encoding="UTF-8"?><Batch>';
 
    # The command is used for each list item retrieved
    $command = '<Method><SetList Scope="Request">' +
                $spList.ID +'</SetList><SetVar Name="ID">{0}</SetVar>' +
                '<SetVar Name="Cmd">Delete</SetVar></Method>';
 
    foreach ($item in $spListItemCollection)
    { 
        $batchRemove += $command -f $item.Id;
    }
    $batchRemove += "</Batch>";
 
    # Remove the list items using the batch command
    $spList.ParentWeb.ProcessBatchData($batchRemove) | Out-Null
}

function DeleteItemsByBatch($spWeb, $spList)
{
    $spQuery = New-Object Microsoft.SharePoint.SPQuery
	$spQuery.ViewAttributes = "Scope='Recursive'";
	$spQuery.RowLimit = 100
	$caml = '<OrderBy Override="TRUE"><FieldRef Name="ID"/></OrderBy>'
	$spQuery.Query = $caml
 
	do
	{
		$listItems = $spList.GetItems($spQuery)
		$count = $listItems.Count
		$spQuery.ListItemCollectionPosition = $listItems.ListItemCollectionPosition
		$batch = "<?xml version=`"1.0`" encoding=`"UTF-8`"?><Batch>"
		$j = 0
		for ($j = 0; $j -lt $count; $j++)
		{
			$item = $listItems[$j]
			write-host "`rProcessing ID: $($item.ID) ($($j+1) of $($count))" -nonewline
			$batch += "<Method><SetList Scope=`"Request`">$($list.ID)</SetList><SetVar Name=`"ID`">$($item.ID)</SetVar><SetVar Name=`"Cmd`">Delete</SetVar><SetVar Name=`"owsfileref`">$($item.File.ServerRelativeUrl)</SetVar></Method>"
			if ($i -ge $count) { break }
		}
		$batch += "</Batch>"
 
		write-host
 
		write-host "Sending batch..."
		$result = $spWeb.ProcessBatchData($batch)
 
		write-host "Emptying Recycle Bin..."
		$spWeb.RecycleBin.DeleteAll()
	}
	while ($spQuery.ListItemCollectionPosition -ne $null)
	#$spWeb.Dispose()
}