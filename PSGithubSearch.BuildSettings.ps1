# This file stores variables which are used by the build script

# Storing all values in a single $Settings variable to make it obvious that the values are coming from this BuildSettings file when accessing them.
$Settings = @{

    Dependency = @('Coveralls','Pester','PsScriptAnalyzer','PSCodeHealth')
    CoverallsKey = $env:Coveralls_Key
    Branch = $env:APPVEYOR_REPO_BRANCH
    TestUploadUrl = "https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)"
    Version = $env:APPVEYOR_BUILD_VERSION
    ManifestPath = '{0}\{1}\{1}.psd1' -f $PSScriptRoot, $env:APPVEYOR_PROJECT_NAME
    VersionRegex = "ModuleVersion\s=\s'(?<ModuleVersion>\S+)'" -as [regex]

    UnitTestParams = @{
        Script = '.\Tests\Unit'
        CodeCoverage = '.\PSGithubSearch\PSGithubSearch.psm1'
        OutputFile = "$PSScriptRoot\BuildOutput\UnitTestsResult.xml"
        PassThru = $True
    }

    CodeHealthParams = @{
        Path = '.\PSGithubSearch\'
    }

    QualityGateParams = @{
        CustomSettingsPath = '.\ProjectRules.json'
        SettingsGroup = 'OverallMetrics'
        MetricName = @('LinesOfCodeAverage',
            'TestCoverage',
            'ScriptAnalyzerFindingsTotal'
            'ComplexityAverage'
        )
    }

    GitHubKey = $env:GitHub_Key
    Email = 'MathieuBuisson@users.noreply.github.com'
    Name = 'Mathieu Buisson'
    BuildOutput = "$PSScriptRoot\BuildOutput"
    SourceFolder = "$PSScriptRoot\$($env:APPVEYOR_PROJECT_NAME)"
    OutputModulePath = "$PSScriptRoot\BuildOutput\$($env:APPVEYOR_PROJECT_NAME)"
}