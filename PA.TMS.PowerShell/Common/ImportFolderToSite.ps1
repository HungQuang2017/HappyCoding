#--------------------------------------------------------------------------------- 
#The sample scripts are not supported under any Microsoft standard support 
#program or service. The sample scripts are provided AS IS without warranty  
#of any kind. Microsoft further disclaims all implied warranties including,  
#without limitation, any implied warranties of merchantability or of fitness for 
#a particular purpose. The entire risk arising out of the use or performance of  
#the sample scripts and documentation remains with you. In no event shall 
#Microsoft, its authors, or anyone else involved in the creation, production, or 
#delivery of the scripts be liable for any damages whatsoever (including, 
#without limitation, damages for loss of business profits, business interruption, 
#loss of business information, or other pecuniary loss) arising out of the use 
#of or inability to use the sample scripts or documentation, even if Microsoft 
#has been advised of the possibility of such damages 
#--------------------------------------------------------------------------------- 
#requires -Version 2

Function Import-OSCFolder
{
<#
 	.SYNOPSIS
        Import-OSCFolder is an advanced function which can be used to import a folder to a library on site.
    .DESCRIPTION
        Import-OSCFolder is an advanced function which can be used to import a folder to a library on site.
    .PARAMETER  <SiteUrl>
		Specifies the site url.
	.PARAMETER  <Library>
	 	Specifies the library of site.
	.PARAMETER  <Path>
		Specifies the path of the folder.
    .EXAMPLE
        C:\PS> Import-OSCFolder -siteurl "http://win-lfseeatt8jr/sites/myteam" -Library "Shared Documents" -path  "C:\Users\Administrator\Desktop\Test"

		
		This command shows how to import folder "C:\Users\Administrator\Desktop\Test" to Site "http://win-lfseeatt8jr/sites/myteam".
#>
	[CmdletBinding()]
	param 
	(
		[Parameter(Mandatory=$true,Position=0)]
		[string]$Siteurl,
		[Parameter(Mandatory=$true,Position=1)]
		[string]$Library,
		[Parameter(Mandatory=$true,Position=2)]
		[string]$Path
	)
	
	
	if ((Get-PSSnapin | Where-Object {$_.Name -eq 'Microsoft.SharePoint.Powershell'})-eq $null) 
    {
    	Add-PSSnapin "Microsoft.SharePoint.Powershell"
    }
	#Get sp site
	$spWeb = Get-SPWeb $siteurl -ErrorAction SilentlyContinue
	If($spWeb)
	{	
		#Get the specified library
		$spDocumentLibrary = $spWeb.Lists[$Library]  
		If($spDocumentLibrary)
		{
            #Turn of version history
            $spDocumentLibrary.EnableVersioning = $false
            $spDocumentLibrary.EnableMinorVersions = $false
            $spDocumentLibrary.ForceCheckOut = $false
            $spDocumentLibrary.Update()

			#verify if the path is valid
			If(Test-Path -Path $Path)
			{
				#Get the folder
				$Fol = Get-Item -Path $Path 
				If($Fol.PSIsContainer)
				{
					$result = $spDocumentLibrary.ParentWeb.GetFolder($spDocumentLibrary.RootFolder.ServerRelativeUrl +"/"+ $Fol.Name )
					If($result.Exists -eq "True")
					{
						Write-Warning "There is a folder existing on site $siteUrl and will be deleted for new updates"
                        $spDocumentLibrary.Folders.DeleteItemById($result.Item.ID)

					}
					
                    #Import the folder to site library.
					$SPFol = $spDocumentLibrary.AddItem("",[Microsoft.SharePoint.SPFileSystemObjectType]::Folder,$Fol.Name) 
					$SPFol.Update()
					SubFolder  $path $SPFol $spDocumentLibrary
						
					Write-Host "Import '$Path' folder to site $siteurl successfully."
				}
				Else
				{
					Write-Error "The object is not a folder."
				}
			}
			Else 
			{
				Write-Error "Invalid path,try again."
			}
		}
		Else
		{
			Write-Warning "There is no library named $Library on site $siteurl."
		}
	}
	Else
	{
		Write-Error "Not find the specified site $siteurl"
	}

}

Function SubFolder($Folder,$SPFol,$spDocumentLibrary)
{
	#Import the folder and subfolders to site library.
	$SPFolder = $spDocumentLibrary.ParentWeb.GetFolder($SPFol.Folder.ServerRelativeUrl)
	$Objects = Get-ChildItem -Path $Folder 
	Foreach($obj in $Objects)
	{
		If($obj.PSIsContainer)
		{	
			$SubFolder = $spDocumentLibrary.AddItem($SPFolder.ServerRelativeUrl,[Microsoft.SharePoint.SPFileSystemObjectType]::Folder,$obj.Name)
			$SubFolder.Update()
			$Fullname = $obj.FullName
			SubFolder  $Fullname $SubFolder $spDocumentLibrary 
			
		}
		Else
		{	
			$fileStream = ([System.IO.FileInfo]$obj).OpenRead() 
			#$contents = new-object byte[] $fileStream.Length 
			$FolderObj = $spDocumentLibrary.ParentWeb.GetFolder($SPFolder.ServerRelativeUrl)
			[Microsoft.SharePoint.SPFile]$SpFile = $FolderObj.Files.Add($FolderObj.Url + "/"+$obj.Name, [System.IO.Stream]$fileStream, $true)
			$spItem = $SpFile.Item
		}
	}

}


