function DoDeploySolutions([string]$farmSolutionsfolderPath, [string]$dataFileFullPath){

    $siteData = GetXmlStructure($dataFileFullPath)
    if($siteData.Web.Data.Solutions.Solution -eq $null){
        return
    }

    $siteData.Web.Data.Solutions.Solution | ForEach {
        Write-Host "===================================================================================="
        $solutionFileName = $_.Name
        $solutionPath = $farmSolutionsfolderPath + "\" + $solutionFileName
        $featureName = $_.FeatureName
        $featureScope = $_.Scope

        if($_.DeployedGlobally -eq $null -or $_.DeployedGlobally -eq $false){
            if (VerifyFeatureActivated -featureId $featureName -scope $featureScope -url $gSiteCollectionUrl){
                Write-Host "Disable Feature " $featureName -ForegroundColor "yellow"
                Disable-SPFeature –Identity $featureName –url $gSiteCollectionUrl -confirm:$false

                Write-Host "Uninstall Feature " $featureName -ForegroundColor "yellow"
                Uninstall-SPFeature $featureName -Force -ErrorAction "SilentlyContinue" -Confirm:$false|Out-Null
            }
        }

        if (VerifySolutionExisted $solutionFileName){
            #Deactivate solution feature if existed
            #Retract and remove solution
            if (VerifyDeployed -solutionName $solutionFileName -webApp $null)
            {
                Write-Host "Uninstall SPSolution " $solutionFileName -ForegroundColor "yellow"
                if($_.DeployedGlobally -eq $null -or $_.DeployedGlobally -eq $false){
                    Uninstall-SPSolution –Identity $solutionFileName -WebApplication $gwebAppUrl -Confirm:$false  
                
                    if ($?)
                    {
                        #wait for job to finish
                        WaitForJobToFinish $solutionName
                    }
                }
                elseif($_.DeployedGlobally -eq $true)
                {
                    Uninstall-SPSolution –Identity $solutionFileName -Confirm:$false  
                
                    if ($?)
                    {
                        #wait for job to finish
                        WaitForJobToFinish $solutionName
                    }
                }
                        
                Remove-SPSolution –Identity $solutionFileName -Confirm:$false | Out-Null

                if ($?){
                    while (VerifySolutionExisted $solutionFileName)
                    {
                        WaitForJobDone
                    }
                }
            }
            else
            {
                Write-Host "Remove SPSolution " $solutionFileName -ForegroundColor "yellow"

                Remove-SPSolution –Identity $solutionFileName -Confirm:$false | Out-Null
                if ($?){
                    while (VerifySolutionExisted $solutionFileName)
                    {
                        WaitForJobDone
                    }
                }
            }
        }
       
        Write-Host "Add SPSolution " $solutionFileName -ForegroundColor "yellow"
        Add-SPSolution $solutionPath

        Write-Host "Install SPSolution " $solutionFileName -ForegroundColor "yellow"
        if($_.DeployedGlobally -eq $null -or $_.DeployedGlobally -eq $false){
            Install-SPSolution -Identity $solutionFileName -WebApplication $gwebAppUrl -GACDeployment -FullTrustBinDeployment -Force
            if ($?){
                #wait for job to finish
                WaitForJobToFinish $solutionFileName
            }
            
            Write-Host "Install SPFeature " $featureName -ForegroundColor "yellow" 
            Install-SPFeature $featureName -Force|Out-Null
        
            ActivateFeature $gSiteCollectionUrl $featureName $featureScope  
        } 
        elseif($_.DeployedGlobally -eq $true)
        {
            Install-SPSolution -Identity $solutionFileName -GACDeployment -Force   
            if ($?){
                #wait for job to finish
                WaitForJobToFinish $solutionFileName
            }
        }         
    }
        
}

function VerifyFeatureActivated($featureId, $scope, $url)
{
    if ($url -eq $null -or $scope -eq "farm")
    {
        $feature = get-SPFeature $featureId -farm -ErrorAction "SilentlyContinue"
        return ($feature -ne $null)
    }
    elseif ($url -ne $null)
    {
        if ($scope -eq "site")
        {
            $feature = get-SPFeature $featureId -Site $url -ErrorAction "SilentlyContinue"
        }
        else
        {
            $feature = get-SPFeature $featureId -Web $url -ErrorAction "SilentlyContinue"
        }
        return ($feature -ne $null)
    }
    else
    {
        return $false
    }
}

#Get a solution based on solution name
function GetSolution($solutionName)
{
    #check whether solution is added
    try
    {
        $solution = Get-SPSolution | where-object {$_.Name -eq $solutionName}
        return $solution    
    }
    catch [Microsoft.SharePoint.PowerShell.SPCmdletPipeBindException]
    {
        return $null 
    }
}

function VerifySolutionExisted($solutionName)
{
    $solution = GetSolution($solutionName)
    return ($solution -ne $null)
}

function VerifyDeployed($solutionName, $webApp)
{
    $solution = GetSolution $solutionName
    if ($webApp -eq $null)
    {
        return $solution.Deployed
    }
    elseif ($solution.Deployed)
    {
        if ($solution.DeployedWebApplications.Count -eq $null)
        {
            return ($solution.DeployedWebApplications.Name -eq $webApp.Name)
        }
        else
        {
            return ($solution.DeployedWebApplications.Contains($webApp))
        }
    }
    else
    {
        return $solution.Deployed
    }
}

function WaitForJobDone()
{
    $SLEEP_TIME_FOR_TIMER_JOB_DONE = 2
    Start-Sleep -Seconds $SLEEP_TIME_FOR_TIMER_JOB_DONE
}

function PrintStartWaitingStatus($content)
{
    write-Host -NoNewline "`t $content " -ForegroundColor "yellow"
}

function PrintEndWaitingStatus($content)
{
    write-Host "...$content" -ForegroundColor "yellow"
}

function PrintContinueWaitingStatus()
{
    write-Host -NoNewline "." -ForegroundColor "yellow"
}

function WaitForJobToFinish([string]$SolutionFileName)
{ 
    $SLEEP_TIME_FOR_TIMER_JOB_DONE = 2
    $JobName = "*solution-deployment*$SolutionFileName*"    
	$job = Get-SPTimerJob | ?{ $_.Name -like $JobName }
	$maxwait = 1000
	$currentwait =0
    
	if ($job -eq $null) 
    {
        PrintError 'Timer job not found'
    }
    else
    {
        $JobFullName = $job.Name
        PrintStartWaitingStatus "Waiting for timer job"        
		while (($currentwait -lt $maxwait)) 
        {
            PrintContinueWaitingStatus
			$currentwait = $currentwait + 1
			Start-Sleep -Seconds $SLEEP_TIME_FOR_TIMER_JOB_DONE
			if ((Get-SPTimerJob $JobFullName) -eq $null){
			break;
			}
        }
        PrintEndWaitingStatus "Done!"
    }
}

function PrintError($content)
{
    Write-Host $content -ForegroundColor "red"
}

function ActivateFeature($siteURL, $featureId, $scope){
    try
        {
            Write-Host "Enable SPFeature " $featureId -ForegroundColor "yellow"
            switch ($scope)
		    {
			    "Site" { 
                    $web = Get-spsite $siteUrl 
                }
			    "Web" { 
                    $web = Get-spWeb $siteUrl 
                }			               
		    }
            $feature = $web.Features[$featureId]
            if ($feature -eq $null) {  
                Enable-SPFeature -Identity $featureId -Url $siteURL  -Confirm:$false
				Write-Host "Feature is activated"
			} 
			else { 
				Write-Host "This feature is activated already" 
			}
        }
        catch{
             $ErrorMessage = $_.Exception.Message
             Write-Host $web.Title  $ErrorMessage
             throw
        }
}