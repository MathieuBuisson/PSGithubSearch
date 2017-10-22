#Requires -Modules 'InvokeBuild'

# Importing all build settings into the current scope
. '.\PSGithubSearch.BuildSettings.ps1'

Function Write-TaskBanner ( [string]$TaskName ) {
    "`n" + ('-' * 79) + "`n" + "`t`t`t $($TaskName.ToUpper()) `n" + ('-' * 79) + "`n"
}

task Clean {
    Write-TaskBanner -TaskName $Task.Name

    If (Test-Path -Path $Settings.BuildOutput) {
        "Removing existing files and folders in $($Settings.BuildOutput)\"
        Get-ChildItem $Settings.BuildOutput | Remove-Item -Force -Recurse
    }
    Else {
        "$($Settings.BuildOutput) is not present, nothing to clean up."
        $Null = New-Item -ItemType Directory -Path $Settings.BuildOutput
    }
}

task Install_Dependencies {
    Write-TaskBanner -TaskName $Task.Name

    Foreach ( $Depend in $Settings.Dependency ) {
        "Installing build dependency : $Depend"
        If ( $Depend -eq 'Selenium.WebDriver' ) {
            Install-Package $Depend -Source nuget.org -Force
        }
        Else {
            Install-Module $Depend -Scope CurrentUser -Force -SkipPublisherCheck
            Import-Module $Depend -Force
        }
    }
}

task Unit_Tests {
    Write-TaskBanner -TaskName $Task.Name

    $UnitTestSettings = $Settings.UnitTestParams
    $Script:UnitTestsResult = Invoke-Pester @UnitTestSettings
}

task Fail_If_Failed_Unit_Test {
    Write-TaskBanner -TaskName $Task.Name

    $FailureMessage = '{0} Unit test(s) failed. Aborting build' -f $UnitTestsResult.FailedCount
    assert ($UnitTestsResult.FailedCount -eq 0) $FailureMessage
}

task Publish_Unit_Tests_Coverage {
    Write-TaskBanner -TaskName $Task.Name

    $Coverage = Format-Coverage -PesterResults $UnitTestsResult -CoverallsApiToken $Settings.CoverallsKey -BranchName $Settings.Branch
    Publish-Coverage -Coverage $Coverage
}

task Upload_Test_Results_To_AppVeyor {
    Write-TaskBanner -TaskName $Task.Name

    $TestResultFiles = (Get-ChildItem -Path $Settings.BuildOutput -Filter '*TestsResult.xml').FullName
    Foreach ( $TestResultFile in $TestResultFiles ) {
        "Uploading test result file : $TestResultFile"
        (New-Object 'System.Net.WebClient').UploadFile($Settings.TestUploadUrl, $TestResultFile)
    }
}

task Test Unit_Tests,
    Fail_If_Failed_Unit_Test,
    Publish_Unit_Tests_Coverage,
    Upload_Test_Results_To_AppVeyor

task Generate_Quality_Report {
    Write-TaskBanner -TaskName $Task.Name

    $CodeHealthSettings = $Settings.CodeHealthParams
    $Script:HealthReport = Invoke-PSCodeHealth @CodeHealthSettings -TestsResult $UnitTestsResult
}

task Fail_If_Quality_Goal_Not_Met {
    Write-TaskBanner -TaskName $Task.Name

    Add-AppveyorTest -Name 'Quality Gate' -Outcome Running
    $QualityGateSettings = $Settings.QualityGateParams
    $Compliance = Test-PSCodeHealthCompliance @QualityGateSettings -HealthReport $HealthReport
    $Compliance
    $FailedRules = $Compliance | Where-Object Result -eq 'Fail'

    If ( $FailedRules ) {
        $WarningMessage = "Failed compliance rules : `n" + ($FailedRules | Out-String)
        Write-Warning $WarningMessage
        $ErrorMessage = "Project's code didn't pass the quality gate. Aborting build"
        Update-AppveyorTest -Name 'Quality Gate' -Outcome Failed -ErrorMessage $ErrorMessage
        Throw $ErrorMessage
    }
    Else {
        Update-AppveyorTest -Name 'Quality Gate' -Outcome Passed
    }
}

task Set_Module_Version {
    Write-TaskBanner -TaskName $Task.Name

    $ManifestContent = Get-Content -Path $Settings.ManifestPath
    $CurrentVersion = $Settings.VersionRegex.Match($ManifestContent).Groups['ModuleVersion'].Value
    "Current module version in the manifest : $CurrentVersion"

    $ManifestContent -replace $CurrentVersion,$Settings.Version | Set-Content -Path $Settings.ManifestPath -Force
    $NewManifestContent = Get-Content -Path $Settings.ManifestPath
    $NewVersion = $Settings.VersionRegex.Match($NewManifestContent).Groups['ModuleVersion'].Value
    "Updated module version in the manifest : $NewVersion"

    If ( $NewVersion -ne $Settings.Version ) {
        Throw "Module version was not updated correctly to $($Settings.Version) in the manifest."
    }
}

task Push_Build_Changes_To_Repo {
    Write-TaskBanner -TaskName $Task.Name
    
    cmd /c "git config --global credential.helper store 2>&1"    
    Add-Content "$env:USERPROFILE\.git-credentials" "https://$($Settings.GitHubKey):x-oauth-basic@github.com`n"
    cmd /c "git config --global user.email ""$($Settings.Email)"" 2>&1"
    cmd /c "git config --global user.name ""$($Settings.Name)"" 2>&1"
    cmd /c "git config --global core.autocrlf true 2>&1"
    cmd /c "git checkout $($Settings.Branch) 2>&1"
    cmd /c "git add -A 2>&1"
    cmd /c "git commit -m ""Commit build changes [ci skip]"" 2>&1"
    cmd /c "git status 2>&1"
    cmd /c "git push origin $($Settings.Branch) 2>&1"
}

task Copy_Source_To_Build_Output {
    Write-TaskBanner -TaskName $Task.Name

    "Copying the source folder [$($Settings.SourceFolder)] into the build output folder : [$($Settings.BuildOutput)]"
    Copy-Item -Path $Settings.SourceFolder -Destination $Settings.BuildOutput -Recurse
}

# Default task :
task . Clean,
    Install_Dependencies,
    Test,
    Generate_Quality_Report,
    Fail_If_Quality_Goal_Not_Met,
    Set_Module_Version,
    Push_Build_Changes_To_Repo,
    Copy_Source_To_Build_Output