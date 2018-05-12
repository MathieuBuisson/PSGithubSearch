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