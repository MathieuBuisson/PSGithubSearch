$ModuleName = 'PSGithubSearch'
Import-Module "$($PSScriptRoot)\..\..\$($ModuleName).psd1" -Force

Describe 'Find-GitHubRepository' {
    
    Context 'Keywords' {
    
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

    Context 'Search qualifiers behaviour' {
       
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
        It 'All results are forks if the Fork parameter has the value "only"' {
        
            $OnlyFork = Find-GitHubRepository -Keywords 'PowerShell-Docs' -In name -SizeKB '>400' -Fork only

            Foreach ( $Result in $OnlyFork ) {
                $Result.fork | Should Be $True
            }
        }
        It 'All results have the owner specified via the User parameter' {
        
            $UserTest = Find-GitHubRepository -Keywords 'script' -User 'MathieuBuisson'

            Foreach ( $Result in $UserTest ) {
                $Result.owner.login | Should match 'MathieuBuisson'
            }
        }
        It 'All results match the stars filter specified via the Stars parameter' {
        
            $StarsTest = Find-GitHubRepository -Keywords 'script' -User 'MathieuBuisson' -Stars '>=1'

            Foreach ( $Result in $StarsTest ) {
                $Result.stargazers_count | Should BeGreaterThan 0
            }
        }
    }
    Context 'Sorting of search results' {

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
}

Describe 'Find-GitHubCode' {
    
    Context 'Defaut parameter set using positional parameters' {
        
        It 'Should use the defaut parameter set and bind the second argument to the User parameter' {
            
            $ParamSetTest = Find-GitHubCode 'SupportsShouldProcess' 'MathieuBuisson'

            Foreach ( $Result in $ParamSetTest ) {
                $Result.repository.owner.login | Should Be 'MathieuBuisson'
            }
        }
    }
    Context 'Keywords' {
        
        It 'All file results have the specified keyword in their path' {

            $KeywordTest = Find-GitHubCode -Keywords 'Deployment' -User 'MathieuBuisson' -In path

            Foreach ( $Result in $KeywordTest ) {
                $Result.path | Should Match 'Deployment'
            }
        }
        It 'All results have the specified keywords when multiple keywords are specified' {
        
            $KeywordTest2 = Find-GitHubCode -Keywords 'Deployment','Validation' -User 'MathieuBuisson' -In path

            Foreach ( $Result in $KeywordTest2 ) {
                $Result.path | Should Match 'Deployment'
            }
            Foreach ( $Result in $KeywordTest2 ) {
                $Result.path | Should Match 'Validation'
            }
        }
    }
    Context 'Search qualifiers behaviour' {

        It 'All results are from the repository specified via the Repo parameter' {

            $RepoTest = Find-GitHubCode -Keywords 'CmdletBinding()' -Repo 'MathieuBuisson/DeploymentReadinessChecker'

            Foreach ( $Result in $RepoTest ) {
                $Result.repository.full_name | Should Be 'MathieuBuisson/DeploymentReadinessChecker'
            }

        }
        It 'All file results match the size filter (less than) specified via the SizeBytes parameter' {
            
            $SizeTest = Find-GitHubCode -Keywords 'socket' -Language 'go' -User 'googollee' -SizeBytes '<150'
            $FileDetails = Invoke-RestMethod -Uri $SizeTest[0].url
            $FileDetails.size | Should BeLessThan 150
        }
        It 'All file results have the string specified via the FileName parameter in their name' {
            
            $FileNameTest = Find-GitHubCode -Keywords 'Computer' -User 'MathieuBuisson' -FileName 'Tests'

            Foreach ( $Result in $FileNameTest ) {
                $Result.name | Should Match 'Tests'
            }
        }
        It 'All file results have the extension specified via the Extension parameter' {
            
            $ExtensionTest = Find-GitHubCode -Keywords 'ComputerName' -User 'MathieuBuisson' -Extension 'psm1'
            
            Foreach ( $Result in $ExtensionTest ) {
                $Result.name | Should Match '\.psm1$'
            }
        }
    }
}
Describe 'Find-GitHubIssue' {
    
    Context 'Keywords' {
    
        It 'All results have the specified keywords when multiple keywords are specified' {
        
            $KeywordTest = Find-GitHubIssue -Type issue -Keywords 'case','sensitive' -In title  -Repo 'Powershell/powershell'

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
        
            $InTest = Find-GitHubIssue -Type issue -Keywords 'crash','memory' -In body -Repo 'docker/docker' -State closed

            Foreach ( $Result in $InTest ) {
                $Result.body | Should Match 'crash'
            }
            Foreach ( $Result in $InTest ) {
                $Result.body | Should Match 'memory'
            }
        }
        It 'All issues were opened by the user specified via the Author parameter' {
        
            $AuthorTest = Find-GitHubIssue -Author 'jpsnover' -Repo 'powershell/powershell' -Type issue -State closed

            Foreach ( $Result in $AuthorTest ) {
                $Result.user.login | Should Be 'jpsnover'
            }
        }
        It 'All results have the type specified via the Type parameter' {
            
            $TypeTest = Find-GitHubIssue -Type pr -Author 'mwrock' -Repo 'pester/pester'

            Foreach ( $Result in $TypeTest ) {
                $Result.pull_request | Should Not BeNullOrEmpty
            }
        }
        It 'All results have the assignee specified via the Assignee parameter' {
            
            $AssigneeTest = Find-GitHubIssue -Type issue -Repo 'powershell/powershell' -Assignee 'lzybkr' -State closed

            Foreach ( $Result in $AssigneeTest ) {
                $Result.assignees.login -join ' ' | Should Match 'lzybkr'
            }
        }
        It 'All results have the state specified via the State parameter' {
            
            $StateTest = Find-GitHubIssue -Type issue -Repo 'powershell/powershell' -Keywords 'case' -State closed

            Foreach ( $Result in $StateTest ) {
                $Result.state | Should Be 'closed'
            }
        }
        It 'All results have the label specified via the Labels parameter' {
            
            $LabelTest = Find-GitHubIssue -Type issue -Repo 'powershell/powershell' -Labels 'Area-Engine' -State closed

            Foreach ( $Result in $LabelTest ) {
                $Result.labels.name -join ' ' | Should Match 'Area-Engine'
            }
        }
        It 'All results have all the labels when multiple labels are specified via the Labels parameter' {
            
            $LabelsTest = Find-GitHubIssue -Type issue -Repo 'powershell/powershell' -Labels 'Area-Engine','Area-Language'
            
            Foreach ( $Result in $LabelsTest ) {
                $Result.labels.name -join ' ' | Should Match 'Area-Engine'
            }
            Foreach ( $Result in $LabelsTest ) {
                $Result.labels.name -join ' ' | Should Match 'Area-Language'
            }
        }
        It 'All results have the metadata field specified via the No parameter empty' {
            
            $NoTest = Find-GitHubIssue -Type issue -Repo 'powershell/powershell' -Labels 'Area-Test' -No assignee -State closed

            Foreach ( $Result in $NoTest ) {
                ($Result.assignees).Count | Should Be 0
            }
        }
    }
    
    Context 'Sorting of search results' {
        It 'When the SortBy value is "comments", any result has more comments than the next one' {
        
            $SortByTest = Find-GitHubIssue -Type issue -Repo 'powershell/powershell' -Labels 'Area-Language' -SortBy comments

            Foreach ( $ResultIndex in 0.. ($SortByTest.Count - 2) ) {
                $SortByTest[$ResultIndex].comments + 1 |
                Should BeGreaterThan $SortByTest[$ResultIndex + 1].comments
            }
        }
    }
}

Describe 'Find-GitHubUser' {
    
    Context 'Keywords' {
    
        It 'All results have the specified keywords' {
        
            $KeywordTest = Find-GithubUser -Type user -Keywords 'Rambling' -In login -Repos '>7'

            Foreach ( $Result in $KeywordTest ) {
                $Result.login | Should Match 'Rambling'
            }
        }
    }
    
    Context 'Search qualifiers behaviour' {
        
        It 'All results have the specified keyword in the field specified via the In parameter' {
        
            $InTest = Find-GithubUser -Type user -Keywords 'Cookie' -In email

            Foreach ( $Result in $InTest ) {
                $Result.'Email Address' | Should Match 'Cookie'
            }
        }
        It 'All the results are in the location specified via the Location parameter' {
            
            $LocationTest = Find-GithubUser -Type user -Language 'PowerShell' -Location 'Ireland'

            Foreach ( $Result in $LocationTest ) {
                $Result.Location | Should Match 'Ireland'
            }
        }
    }
}