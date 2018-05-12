$ModuleName = 'PSGithubSearch'
Import-Module "$PSScriptRoot\..\..\$ModuleName\$ModuleName.psd1" -Force

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