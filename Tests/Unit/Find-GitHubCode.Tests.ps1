$ModuleName = 'PSGithubSearch'
Import-Module "$PSScriptRoot\..\..\$ModuleName\$ModuleName.psd1" -Force

Describe 'Find-GitHubCode' {
    InModuleScope $ModuleName {

        $Mocks = ConvertFrom-Json (Get-Content -Path "$PSScriptRoot\..\TestData\MockObjects.json" -Raw )

        Context 'Defaut parameter set using positional parameters' {

            It 'Should use the defaut parameter set and bind the second argument to the User parameter' {
                Mock Invoke-WebRequest { $Mocks.'Invoke-WebRequest'.ParameterSet }
                Mock ConvertFrom-Json { $Mocks.'Invoke-WebRequest'.ParameterSet.Content }
                $ParamSetTest = Find-GitHubCode 'SupportsShouldProcess' 'MathieuBuisson'

                Foreach ( $Result in $ParamSetTest ) {
                    $Result.repository.owner.login | Should Be 'MathieuBuisson'
                }
            }
        }
        Context 'Keywords' {

            It 'All file results have the specified keyword in their path' {
                Mock Invoke-WebRequest { $Mocks.'Invoke-WebRequest'.DeploymentInPath }
                Mock ConvertFrom-Json { $Mocks.'Invoke-WebRequest'.DeploymentInPath.Content }
                $KeywordTest = Find-GitHubCode -Keywords 'Deployment' -User 'MathieuBuisson' -In path

                Foreach ( $Result in $KeywordTest ) {
                    $Result.path | Should Match 'Deployment'
                }
            }
            It 'All results have the specified keywords when multiple keywords are specified' {
                Mock Invoke-WebRequest { $Mocks.'Invoke-WebRequest'.MultiKeywords }
                Mock ConvertFrom-Json { $Mocks.'Invoke-WebRequest'.MultiKeywords.Content }
                $MultiKeyword = Find-GitHubCode -Keywords 'Deployment', 'Validation' -In path -Language 'PowerShell'

                Foreach ( $Result in $MultiKeyword ) {
                    $Result.path | Should Match 'Deployment'
                }
                Foreach ( $Result in $MultiKeyword ) {
                    $Result.path | Should Match 'Validation'
                }
            }
        }
        Context 'Search qualifiers behaviour' {

            It 'All results are from the repository specified via the Repo parameter' {
                Mock Invoke-WebRequest { $Mocks.'Invoke-WebRequest'.MultiKeywords }
                Mock ConvertFrom-Json { $Mocks.'Invoke-WebRequest'.MultiKeywords.Content }
                $RepoTest = Find-GitHubCode -Keywords 'Any' -Repo 'MathieuBuisson/DeploymentReadinessChecker'

                Foreach ( $Result in $RepoTest ) {
                    $Result.repository.full_name | Should Be 'MathieuBuisson/DeploymentReadinessChecker'
                }

            }
            It 'All file results have the string specified via the FileName parameter in their name' {
                Mock Invoke-WebRequest { $Mocks.'Invoke-WebRequest'.MultiKeywords }
                Mock ConvertFrom-Json { $Mocks.'Invoke-WebRequest'.MultiKeywords.Content }
                $FileNameTest = Find-GitHubCode -Keywords 'Any' -User 'MathieuBuisson' -FileName 'Tests'

                Foreach ( $Result in $FileNameTest ) {
                    $Result.name | Should Match 'Tests'
                }
            }
            It 'All file results have the extension specified via the Extension parameter' {
                Mock Invoke-WebRequest { $Mocks.'Invoke-WebRequest'.MultiKeywords }
                Mock ConvertFrom-Json { $Mocks.'Invoke-WebRequest'.MultiKeywords.Content }
                $ExtensionTest = Find-GitHubCode -Keywords 'Any' -User 'MathieuBuisson' -Extension 'ps1'

                Foreach ( $Result in $ExtensionTest ) {
                    $Result.name | Should Match '\.ps1$'
                }
            }
        }
    }
}