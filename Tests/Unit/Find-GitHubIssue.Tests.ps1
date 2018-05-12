$ModuleName = 'PSGithubSearch'
Import-Module "$PSScriptRoot\..\..\$ModuleName\$ModuleName.psd1" -Force

Describe 'Find-GitHubIssue' {
    InModuleScope $ModuleName {

        $Mocks = ConvertFrom-Json (Get-Content -Path "$PSScriptRoot\..\TestData\MockObjects.json" -Raw )

        Context 'Keywords' {

            It 'All results have the specified keywords when multiple keywords are specified' {
                Mock Invoke-WebRequest { $Mocks.'Invoke-WebRequest'.IssueKeywords }
                Mock ConvertFrom-Json { $Mocks.'Invoke-WebRequest'.IssueKeywords.Content }
                $KeywordTest = Find-GitHubIssue -Type issue -Keywords 'case', 'sensitive' -In title

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
                $InTest = Find-GitHubIssue -Type issue -Keywords 'error', 'cannot' -In body

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
