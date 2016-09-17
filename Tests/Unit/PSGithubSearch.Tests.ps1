$ModuleName = 'PSGithubSearch'
Import-Module "$($PSScriptRoot)\..\..\$($ModuleName).psm1" -Force

Describe 'Keywords' {
    
    It 'All results have the specified keyword' {

        $KeywordTest = Find-GitHubRepository -Keywords 'PowerShell' -User 'MathieuBuisson' -In description

        Foreach ( $Result in $KeywordTest ) {
            $Result.description | Should Match 'PowerShell'
        }
    }
    It 'All results have the specified keywords when multiple keywords are specified' {
        
        $KeywordTest = Find-GitHubRepository -Keywords 'PowerShell','module' -User 'MathieuBuisson' -In description

        Foreach ( $Result in $KeywordTest ) {
            $Result.description | Should Match 'PowerShell'
        }
        Foreach ( $Result in $KeywordTest ) {
            $Result.description | Should Match 'module'
        }
    }
}

Describe 'Search qualifiers behaviour' {
       
    It 'All results have the specified language' {
        
        $LanguageTest = Find-GitHubRepository -Keywords 'script' -Language 'PowerShell' -User 'MathieuBuisson'

        Foreach ( $Result in $LanguageTest ) {
            $Result.language | Should Be 'PowerShell'
        }
    }
    It 'All results have the specified keyword in the field specified via the In parameter' {
        
        $InTest = Find-GitHubRepository -Keywords 'PowerShell-' -In name -User 'MathieuBuisson'

        Foreach ( $Result in $InTest ) {
            $Result.name | Should Match 'PowerShell-'
        }
    }
    It 'All results match the size filter (greater than) specified via the SizeKB parameter' {
        
        $SizeKBTest = Find-GitHubRepository -Keywords 'PowerShell' -User 'MathieuBuisson' -SizeKB '>59'

        Foreach ( $Result in $SizeKBTest ) {
            $Result.size | Should BeGreaterThan 59
        }
    }
    # Waiting 1 minute because the GitHub Search API limits to 10 requests per minute
    Start-Sleep -Seconds 61

    It 'All results match the size filter (less than) specified via the SizeKB parameter' {
        
        $SizeKBTest_LessThan = Find-GitHubRepository -Keywords 'PowerShell' -User 'MathieuBuisson' -SizeKB '<58'

        Foreach ( $Result in $SizeKBTest_LessThan ) {
            $Result.size | Should BeLessThan 58
        }
    }
    It 'All results are NOT forks if the Fork parameter is not used' {
        
        $NoFork = Find-GitHubRepository -Keywords 'PowerShell-Docs' -In name -SizeKB '>400'

        Foreach ( $Result in $NoFork ) {
            $Result.fork | Should Be $False
        }
    }
    Start-Sleep -Seconds 61

    It 'All results are forks if the Fork parameter has the value "only"' {
        
        $OnlyFork = Find-GitHubRepository -Keywords 'PowerShell-Docs' -In name -SizeKB '>400' -Fork only

        Foreach ( $Result in $OnlyFork ) {
            $Result.fork | Should Be $True
        }
    }
    Start-Sleep -Seconds 61

    It 'All results have the owner specified via the User parameter' {
        
        $UserTest = Find-GitHubRepository -Keywords 'script' -User 'MathieuBuisson'

        Foreach ( $Result in $UserTest ) {
            $Result.owner.login | Should match 'MathieuBuisson'
        }
    }
    It 'All results match the size filter specified via the Stars parameter' {
        
        $StarsTest = Find-GitHubRepository -Keywords 'script' -User 'MathieuBuisson' -Stars '>=1'

        Foreach ( $Result in $StarsTest ) {
            $Result.stargazers_count | Should BeGreaterThan 0
        }
    }
}
Describe 'Sorting and ordering of search results' {

    It 'When the $SortBy value is "stars", any result has more stars than the next one' {
        
        $SortByTest = Find-GitHubRepository -Keywords 'Pester' -SortBy stars -In name -Language 'PowerShell'

        Foreach ( $ResultIndex in 0.. ($SortByTest.Count - 2) ) {
            $SortByTest[$ResultIndex].stargazers_count + 1 |
            Should BeGreaterThan $SortByTest[$ResultIndex + 1].stargazers_count
        }

    }
    It "When the $SortBy value is 'forks', any result has more forks than the next one" {

        $SortbyForksTest = Find-GitHubRepository -Keywords 'Pester' -SortBy forks -In name -Language 'PowerShell'

        Foreach ( $ResultIndex in 0.. ($SortbyForksTest.Count - 2) ) {
            $SortbyForksTest[$ResultIndex].forks + 1 |
            Should BeGreaterThan $SortbyForksTest[$ResultIndex + 1].forks
        }
    }
}