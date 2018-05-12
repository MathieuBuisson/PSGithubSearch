$ModuleName = 'PSGithubSearch'
Import-Module "$PSScriptRoot\..\..\$ModuleName\$ModuleName.psd1" -Force

# Helper stuff
Add-Type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

Describe 'Find-GitHubRepository' {
    InModuleScope $ModuleName {

        $Mocks = ConvertFrom-Json (Get-Content -Path "$PSScriptRoot\..\TestData\MockObjects.json" -Raw )
        Mock ConvertFrom-Json { return $InputObject }

        Context 'Keywords' {
             $MockedResponse = $Mocks.'Invoke-WebRequest'.MathieuBuissonPowerShell
             Mock Invoke-WebRequest { $MockedResponse }

            It 'All results have the specified keyword' {

                $KeywordTest = Find-GitHubRepository -Keywords 'PowerShell' -User 'MathieuBuisson' -In description

                Foreach ( $Result in $KeywordTest ) {
                    $Result.description | Should Match 'PowerShell'
                }
            }
        }
        Context 'Search qualifiers behaviour' {

            It 'All results have the specified language' {

                $LanguageTest = Find-GitHubRepository -Keywords 'script' -Language 'PowerShell' -User 'MathieuBuisson'

                Foreach ( $Result in $LanguageTest ) {
                    $Result.language | Should Be 'PowerShell'
                }
            }
            It 'All results have the specified keyword in the field specified via the In parameter' {
                Mock Invoke-WebRequest { $Mocks.'Invoke-WebRequest'.PowerShellInName }
                $InTest = Find-GitHubRepository -Keywords 'PowerShell-' -In 'name' -User 'MathieuBuisson'

                Foreach ( $Result in $InTest ) {
                    $Result.name | Should Match 'PowerShell-'
                }
            }
            It 'All results match the size filter (greater than) specified via the SizeKB parameter' {
                Mock Invoke-WebRequest { $Mocks.'Invoke-WebRequest'.SizeGreaterThan100 }
                $SizeKBTest = Find-GitHubRepository -Keywords 'PowerShell' -User 'MathieuBuisson' -SizeKB '>100'

                Foreach ( $Result in $SizeKBTest ) {
                    $Result.size | Should BeGreaterThan 100
                }
            }
            It 'All results are NOT forks if the Fork parameter is not used' {
                Mock Invoke-WebRequest { $Mocks.'Invoke-WebRequest'.NoFork }
                $NoFork = Find-GitHubRepository -Keywords 'Any' -In name

                Foreach ( $Result in $NoFork ) {
                    $Result.fork | Should Be $False
                }
            }
            It 'All results are forks if the Fork parameter has the value "only"' {
                Mock Invoke-WebRequest { $Mocks.'Invoke-WebRequest'.ForksOnly }
                $OnlyFork = Find-GitHubRepository -Keywords 'Any' -In name -Fork 'only'

                Foreach ( $Result in $OnlyFork ) {
                    $Result.fork | Should Be $True
                }
            }
            It 'All results have the owner specified via the User parameter' {

                $UserTest = Find-GitHubRepository -Keywords 'PS' -User 'MathieuBuisson'

                Foreach ( $Result in $UserTest ) {
                    $Result.owner.login | Should match 'MathieuBuisson'
                }
            }
            It 'All results match the stars filter specified via the Stars parameter' {
                Mock Invoke-WebRequest { $Mocks.'Invoke-WebRequest'.MoreThan20Stars }
                $StarsTest = Find-GitHubRepository -Keywords 'script' -User 'MathieuBuisson' -Stars '>20'

                Foreach ( $Result in $StarsTest ) {
                    $Result.stargazers_count | Should BeGreaterThan 20
                }
            }
        }
        Context 'Sorting of search results' {

            It 'When the $SortBy value is "stars", any result has more stars than the next one' {
                Mock Invoke-WebRequest { $Mocks.'Invoke-WebRequest'.MoreThan20Stars }
                Mock ConvertFrom-Json { $Mocks.'Invoke-WebRequest'.MoreThan20Stars.Content }

                $SortByTest = Find-GitHubRepository -Keywords 'Any' -SortBy 'stars'
                $SortByTest[0].stargazers_count | Should BeGreaterThan $SortByTest[1].stargazers_count

            }
            It "When the $SortBy value is 'forks', any result has more forks than the next one" {
                Mock Invoke-WebRequest { $Mocks.'Invoke-WebRequest'.SortByForks }
                Mock ConvertFrom-Json { $Mocks.'Invoke-WebRequest'.SortByForks.Content }

                $SortbyForks = Find-GitHubRepository -Keywords 'Any' -SortBy forks
                $SortbyForks[0].forks | Should BeGreaterThan $SortbyForks[1].forks
            }
        }
    }
}
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
                $MultiKeyword = Find-GitHubCode -Keywords 'Deployment','Validation' -In path -Language 'PowerShell'

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
Describe 'Find-GitHubIssue' {
    InModuleScope $ModuleName {

        $Mocks = ConvertFrom-Json (Get-Content -Path "$PSScriptRoot\..\TestData\MockObjects.json" -Raw )

        Context 'Keywords' {

            It 'All results have the specified keywords when multiple keywords are specified' {
                Mock Invoke-WebRequest { $Mocks.'Invoke-WebRequest'.IssueKeywords }
                Mock ConvertFrom-Json { $Mocks.'Invoke-WebRequest'.IssueKeywords.Content }
                $KeywordTest = Find-GitHubIssue -Type issue -Keywords 'case','sensitive' -In title

                Foreach ( $Result in $KeywordTest ) {
                    $Result.title | Should Match 'case'
                }
                Foreach ( $Result in $KeywordTest ) {
                    $Result.title | Should Match 'sensitive'
                }
            }
        }
        Context 'Search qualifiers behaviour' {

            It 'All results have the specified keyword in the field specified via the In parameter' {
                Mock Invoke-WebRequest { $Mocks.'Invoke-WebRequest'.IssueKeywords }
                Mock ConvertFrom-Json { $Mocks.'Invoke-WebRequest'.IssueKeywords.Content }
                $InTest = Find-GitHubIssue -Type issue -Keywords 'error','cannot' -In body

                Foreach ( $Result in $InTest ) {
                    $Result.body | Should Match 'error'
                }
                Foreach ( $Result in $InTest ) {
                    $Result.body | Should Match 'cannot'
                }
            }
            It 'All issues were opened by the user specified via the Author parameter' {
                Mock Invoke-WebRequest { $Mocks.'Invoke-WebRequest'.AuthorSnover }
                Mock ConvertFrom-Json { $Mocks.'Invoke-WebRequest'.AuthorSnover.Content }
                $AuthorTest = Find-GitHubIssue -Author 'jpsnover' -Type issue -Mentions 'jpsnover'

                Foreach ( $Result in $AuthorTest ) {
                    $Result.user.login | Should Be 'jpsnover'
                }
            }
            It 'All results have the type specified via the Type parameter' {
                Mock Invoke-WebRequest { $Mocks.'Invoke-WebRequest'.TypePR }
                Mock ConvertFrom-Json { $Mocks.'Invoke-WebRequest'.TypePR.Content }
                $TypeTest = Find-GitHubIssue -Type pr -Author 'mwrock' -Commenter 'lzybkr'

                Foreach ( $Result in $TypeTest ) {
                    $Result.pull_request | Should Not BeNullOrEmpty
                }
            }
            It 'All results have the assignee specified via the Assignee parameter' {
                Mock Invoke-WebRequest { $Mocks.'Invoke-WebRequest'.AuthorSnover }
                Mock ConvertFrom-Json { $Mocks.'Invoke-WebRequest'.AuthorSnover.Content }
                $AssigneeTest = Find-GitHubIssue -Type issue -Assignee 'lzybkr'

                Foreach ( $Result in $AssigneeTest ) {
                    $Result.assignees.login -join ' ' | Should Match 'lzybkr'
                }
            }
            It 'All results have the state specified via the State parameter' {
                Mock Invoke-WebRequest { $Mocks.'Invoke-WebRequest'.AuthorSnover }
                Mock ConvertFrom-Json { $Mocks.'Invoke-WebRequest'.AuthorSnover.Content }
                $StateTest = Find-GitHubIssue -Type issue -Assignee 'lzybkr'

                Foreach ( $Result in $StateTest ) {
                    $Result.state | Should Be 'closed'
                }
            }
            It 'All results have the label specified via the Labels parameter' {
                Mock Invoke-WebRequest { $Mocks.'Invoke-WebRequest'.AuthorSnover }
                Mock ConvertFrom-Json { $Mocks.'Invoke-WebRequest'.AuthorSnover.Content }
                $LabelTest = Find-GitHubIssue -Type issue -Labels 'Area-Engine'

                Foreach ( $Result in $LabelTest ) {
                    $Result.labels.name -join ' ' | Should Match 'Area-Engine'
                }
            }
            It 'All results have the metadata field specified via the No parameter empty' {
                Mock Invoke-WebRequest { $Mocks.'Invoke-WebRequest'.NoAssignee }
                Mock ConvertFrom-Json { $Mocks.'Invoke-WebRequest'.NoAssignee.Content }
                $NoTest = Find-GitHubIssue -Type issue -Repo 'powershell/powershell' -Labels 'Area-Test' -No assignee -State closed

                Foreach ( $Result in $NoTest ) {
                    $Result.assignees | Should BeNullOrEmpty
                }
            }
        }
        Context 'Sorting of search results' {
            It 'When the SortBy value is "comments", any result has more comments than the next one' {
                Mock Invoke-WebRequest { $Mocks.'Invoke-WebRequest'.NoAssignee }
                Mock ConvertFrom-Json { $Mocks.'Invoke-WebRequest'.NoAssignee.Content }
                $SortByTest = Find-GitHubIssue -Type 'issue' -Labels 'Area-Test' -SortBy comments

                $SortByTest[0].comments | Should BeGreaterThan $SortByTest[1].comments
            }
        }
    }
}

Describe 'Find-GitHubUser' {
    InModuleScope $ModuleName {

        $Mocks = ConvertFrom-Json (Get-Content -Path "$PSScriptRoot\..\TestData\MockObjects.json" -Raw )

        Context 'Keywords' {

            It 'All results have the specified keywords' {
                Mock Invoke-WebRequest { $Mocks.'Invoke-WebRequest'.RamblingInLogin }
                Mock ConvertFrom-Json { $Mocks.'Invoke-WebRequest'.RamblingInLogin.Content }
                $KeywordTest = Find-GithubUser -Type 'user' -Keywords 'Rambling' -In 'login' -Repos '>12'

                Foreach ( $Result in $KeywordTest ) {
                    $Result.login | Should Match 'Rambling'
                }
            }
        }
        Context 'Sorting of search results' {

            It 'When the $SortBy value is "followers", any result has more followers than the next one' {
                $SortByFollowers = Find-GithubUser -Type 'user' -Keywords 'Rambling' -In 'login' -Repos '>18' -SortBy 'followers'
                $SortByFollowers[0].Followers | Should BeGreaterThan $SortByFollowers[1].Followers
            }
        }
    }
}