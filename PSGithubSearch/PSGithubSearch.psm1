#Requires -Version 4

Function Find-GitHubRepository {
<#
.SYNOPSIS
    Searches repositories on GitHub.com based on the specified search keyword(s) and parameters.
    
.DESCRIPTION
    Uses the GitHub search API to find repositories on GitHub.com based on the specified search keyword(s) and parameters.

    This API's documentation is available here : https://developer.github.com/v3/search/

    NOTE : The GitHub Search API limits each search to 1,000 results and the number of requests to 10 per minute.
    
.PARAMETER Keywords
    One or more keywords to search.

.PARAMETER Language
    To search repositories based on the language they are written in.

.PARAMETER In
    To qualify which field is searched. With this qualifier you can restrict the search to just the repository name, description, or readme.
    If not specified, the default behaviour is to search in both the name, description and readme.

.PARAMETER SizeKB
    To search repositories that match a certain size (in kilobytes).

.PARAMETER Fork
    Filters whether forked repositories should be included ( if the value is 'true' ) or only forked repositories should be returned ( if the value is 'only' ).
    If this parameter is not specified, the default behaviour is to exclude forks.

.PARAMETER User
    To Limit searches to repositories owned by a specific user.
    If the value of this parameter doesn't match exactly with an existing GitHub user name, it throws an error.

.PARAMETER Stars
    To filter repositories based on the number of stars.

.PARAMETER SortBy
    To specify on which field the results should be sorted on : number of stars, forks or last updated date.
    By default, the results are sorted by best match.

.EXAMPLE
    Find-GitHubRepository -Keywords 'TCP' -Language 'Python'

    Searches GitHub repositories which have the word "TCP" in their name or description or readme and are written in Python.

.EXAMPLE
    Find-GitHubRepository -Keywords 'TCP' -Language 'Python' -In name

    Searches GitHub repositories which have the word "TCP" in their name and are written in Python.

.EXAMPLE
    Find-GitHubRepository -Keywords 'UDP' -In description -SizeKB '>200'

    Searches GitHub repositories which have the word "UDP" in their description and are larger than 200 kilobytes.

.EXAMPLE
    Find-GitHubRepository -Keywords 'PowerShell-Docs' -In name -Fork only

    Searches forks which have the word "PowerShell-Docs" in their name.

.EXAMPLE
    Find-GitHubRepository -Keywords 'script' -User 'MathieuBuisson'

    Searches GitHub repositories which have the word "script" in their name or description or readme and are owned by the user MathieuBuisson.

.EXAMPLE
    Find-GitHubRepository -Keywords 'disk','space' -In readme -Stars '>=10'

    Searches GitHub repositories which have both words "disk" and "space" in their readme and have 10 or more stars.

.EXAMPLE
    Find-GitHubRepository -SortBy stars -In name -Language 'PowerShell' -Keywords 'Pester'

    Searches GitHub repositories written in PowerShell which have the word "Pester" in their name and sorts them by the number of stars (descending order).

.NOTES
    Author : Mathieu Buisson
    
.LINK
    https://github.com/MathieuBuisson/PSGithubSearch
#>
    [CmdletBinding()]
    
    Param(
        [Parameter(Mandatory=$True,Position=0)]
        [string[]]$Keywords,

        [Parameter(Position=1)]
        [string]$Language,

        [Parameter(Position=2)]
        [ValidateSet('name','description','readme')]
        [string]$In,

        [Parameter(Position=3)]
        [ValidatePattern('^[\d<>][=\d]\d*$')]
        [string]$SizeKB,

        [Parameter(Position=4)]
        [ValidateSet('true','only')]
        [string]$Fork,

        [Parameter(Position=5)]
        [string]$User,

        [Parameter(Position=6)]
        [ValidatePattern('^[\d<>][=\d]\d*$')]
        [string]$Stars,

        [Parameter(Position=7)]
        [ValidateSet('stars','forks','updated')]
        [string]$SortBy
    )

    [string]$KeywordsString = $Keywords -join '+'
    [string]$QueryString = 'q=' + $KeywordsString

    If ( $Language ) {
        $QueryString += '+language:' + $Language
    }
    If ( $In ) {
        $QueryString += '+in:' + $In
    }
    If ( $SizeKB ) {
        $QueryString += '+size:' + $SizeKB
    }
    If ( $Fork ) {
        $QueryString += '+fork:' + $Fork
    }
    If ( $User ) {
        $QueryString += '+user:' + $User
    }
    If ( $Stars ) {
        $QueryString += '+stars:' + $Stars
    }
    If ( $SortBy ) {
        $QueryString += "&sort=$SortBy"
    }

    # Using the maximum number of results per page to limit the number of requests
    $QueryString += '&per_page=100'

    $UriBuilder = New-Object System.UriBuilder -ArgumentList 'https://api.github.com'
    $UriBuilder.Path = 'search/repositories' -as [uri]
    $UriBuilder.Query = $QueryString

    $BaseUri = $UriBuilder.Uri
    Write-Verbose "Constructed base URI : $($BaseUri.AbsoluteUri)"

    $Response = Invoke-WebRequest -Uri $BaseUri
    If ( $Response.StatusCode -ne 200 ) {

        Write-Warning "The status code was $($Response.StatusCode) : $($Response.StatusDescription)"
    }
    $NumberOfPages = Get-NumberofPage -SearchResult $Response
    Write-Verbose "Number of pages for this search result : $($NumberOfPages)"

    Foreach ( $PageNumber in 1..$NumberOfPages ) {

        $ResultPageUri = $BaseUri.AbsoluteUri + "&page=$($PageNumber.ToString())"

        Try {
            $PageResponse  = Invoke-WebRequest -Uri $ResultPageUri -ErrorAction Stop
        }
        Catch {
            Throw $_.Exception.Message
        }

        # The search API limits the number of requests to 10 requests per minute and per IP address (for unauthenticated requests)
        # We might be subject to the limit on the number of requests if we run function multiple times in the last minute
        $RemainingRequestsNumber = $PageResponse.Headers.'X-RateLimit-Remaining' -as [int]
        Write-Verbose "Number of remaining API requests : $($RemainingRequestsNumber)."

        If ( $RemainingRequestsNumber -le 1 ) {
            Write-Warning "The search API limits the number of requests to 10 requests per minute"
            Write-Warning "Waiting 60 seconds before processing the remaining result pages because we have exceeded this limit."
            Start-Sleep -Seconds 60
        }
        $PageResponseContent = $PageResponse.Content | ConvertFrom-Json

        Foreach ( $PageResult in $PageResponseContent.items ) {

            $PageResult.psobject.TypeNames.Insert(0,'PSGithubSearch.Repository')
            $PageResult
        }
    }
}

Function Find-GitHubCode {
<#
.SYNOPSIS
    Searches file contents on GitHub.com based on the specified search keyword(s) and parameters.
    
.DESCRIPTION
    Uses the GitHub search API to find code in files on GitHub.com based on the specified search keyword(s) and parameters.

    This API's documentation is available here : https://developer.github.com/v3/search/

    NOTE : Due to the complexity of searching code, the GitHub Search API has a few restrictions on how searches are performed :
        - Only the default branch is considered. In most cases, this will be the  master  branch.
        - Only files smaller than 384 KB are searchable.
        - Only repositories with fewer than 500,000 files are searchable.

.PARAMETER Keywords
    One or more keywords or code snippet to search.

.PARAMETER User
    To Limit searches to code owned by a specific user.
    If the value of this parameter doesn't match exactly with an existing GitHub user name, it throws an error.

.PARAMETER Repo
    To Limit searches to code in a specific repository.
    The value of this parameter must match exactly with the full name of an existing GitHub repository, formatted as : Username/RepoName.

.PARAMETER Language
    To search code based on the language it is written in.

.PARAMETER In
    To qualify which field is searched. With this qualifier you can restrict the search to files contents or to files paths.
    If not specified, the default behaviour is to search in both files contents and paths.
        
.PARAMETER SizeBytes
    To search only files that match a certain size (in bytes).

.PARAMETER Fork
    Filters whether forked repositories should be included in the search.
    By default, forks are not searched unless the fork has more stars than the parent repository.

.PARAMETER FileName
    Filters the search to files with a name containing the string specified via this parameter.

.PARAMETER Extension
    Filters the search to files with the specified extension.

.PARAMETER SortByLastIndexed
    Sorts the results by how recently a file has been indexed by the GitHub search infrastructure.
    By default, the results are sorted by best match.

.EXAMPLE
    Find-GitHubCode -User 'MathieuBuisson' -Keywords 'SupportsShouldProcess' -Extension 'psm1'

    Finds the .psm1 files which contain the code 'SupportsShouldProcess' in repositories from the user 'MathieuBuisson'.

.NOTES
    Author : Mathieu Buisson
    
.LINK
    https://github.com/MathieuBuisson/PSGithubSearch
#>
    [CmdletBinding(DefaultParameterSetName='User')]
    
    Param(
        [Parameter(Mandatory=$True,Position=0)]
        [string[]]$Keywords,

        [Parameter(Position=1,ParameterSetName='User')]
        [string]$User,

        [Parameter(Position=1,ParameterSetName='Repo')]
        [ValidatePattern('^[a-zA-Z]+/[a-zA-Z]+')]
        [string]$Repo,

        [Parameter(Position=2)]
        [string]$Language,

        [Parameter(Position=3)]
        [ValidateSet('file','path')]
        [string]$In,

        [Parameter(Position=4)]
        [ValidatePattern('^[\d<>][=\d]\d*$')]
        [string]$SizeBytes,

        [Parameter(Position=5)]
        [switch]$Fork,

        [Parameter(Position=6)]
        [string]$FileName,

        [Parameter(Position=7)]
        [string]$Extension,

        [Parameter(Position=8)]
        [switch]$SortByLastIndexed
    )

    # Cleaning up the value of $Extension if the user puts a "dot" at the beginning
    If ( $Extension -match '^\.' ) {
        $Extension = $Extension.TrimStart('.')
    }

    [string]$KeywordsString = $Keywords -join '+'
    [string]$QueryString = 'q=' + $KeywordsString

    If ( $Language ) {
        $QueryString += '+language:' + $Language
    }
    If ( $In ) {
        $QueryString += '+in:' + $In
    }
    If ( $SizeBytes ) {
        $QueryString += '+size:' + $SizeBytes
    }
    If ( $Fork ) {
        $QueryString += '+fork:true'
    }
    If ( $User ) {
        $QueryString += '+user:' + $User
    }
    If ( $Repo ) {
        $QueryString += '+repo:' + $Repo
    }
    If ( $FileName ) {
        $QueryString += '+filename:' + $FileName
    }
    If ( $Extension ) {
        $QueryString += '+extension:' + $Extension
    }
    If ( $SortByLastIndexed ) {
        $QueryString += "&sort=indexed"
    }

    # Using the maximum number of results per page to limit the number of requests
    $QueryString += '&per_page=100'

    $UriBuilder = New-Object System.UriBuilder -ArgumentList 'https://api.github.com'
    $UriBuilder.Path = 'search/code' -as [uri]
    $UriBuilder.Query = $QueryString

    $BaseUri = $UriBuilder.Uri
    Write-Verbose "Constructed base URI : $($BaseUri.AbsoluteUri)"

    $Response = Invoke-WebRequest -Uri $BaseUri
    If ( $Response.StatusCode -ne 200 ) {

        Write-Warning "The status code was $($Response.StatusCode) : $($Response.StatusDescription)"
    }
    $NumberOfPages = Get-NumberofPage -SearchResult $Response
    Write-Verbose "Number of pages for this search result : $($NumberOfPages)"

    Foreach ( $PageNumber in 1..$NumberOfPages ) {

        $ResultPageUri = $BaseUri.AbsoluteUri + "&page=$($PageNumber.ToString())"

        Try {
            $PageResponse  = Invoke-WebRequest -Uri $ResultPageUri -ErrorAction Stop
        }
        Catch {
            Throw $_.Exception.Message
        }

        # The search API limits the number of requests to 10 requests per minute and per IP address (for unauthenticated requests)
        # We might be subject to the limit on the number of requests if we run function multiple times in the last minute
        $RemainingRequestsNumber = $PageResponse.Headers.'X-RateLimit-Remaining' -as [int]
        Write-Verbose "Number of remaining API requests : $($RemainingRequestsNumber)."

        If ( $RemainingRequestsNumber -le 1 ) {
            Write-Warning "The search API limits the number of requests to 10 requests per minute"
            Write-Warning "Waiting 60 seconds before processing the remaining result pages because we have exceeded this limit."
            Start-Sleep -Seconds 60
        }
        $PageResponseContent = $PageResponse.Content | ConvertFrom-Json

        Foreach ( $PageResult in $PageResponseContent.items ) {            

            $PageResult.psobject.TypeNames.Insert(0,'PSGithubSearch.Code')
            $PageResult
        }
    }
}

Function Find-GitHubIssue {
<#
.SYNOPSIS
    Searches issues and pull requests on GitHub.com based on the specified search keyword(s) and parameters.
    
.DESCRIPTION
    Uses the GitHub search API to find issues and/or pull requests on GitHub.com based on the specified search keyword(s) and parameters.

    This API's documentation is available here : https://developer.github.com/v3/search/

.PARAMETER Keywords
    To search issues and/or pull requests containing the specified keyword(s) in their title, body or comments.

.PARAMETER Type
    To restrict the search to issues only or pull requests only.
    By default, both are searched.

.PARAMETER In
    To qualify which field is searched for the specified keyword(s). With this qualifier you can restrict the search to the title, body or comments of issues and pull requests.
    By default, all these fields are searched for the specified keyword(s).

.PARAMETER Author
    To Limit searches to issues or pull requests created by a specific user.
    If the value of this parameter doesn't match exactly with an existing GitHub user name, it throws an error.

.PARAMETER Assignee
    To Limit searches to issues or pull requests assigned to a specific user.
    If the value of this parameter doesn't match exactly with an existing GitHub user name, it throws an error.

.PARAMETER Mentions
    To Limit searches to issues or pull requests in which a specific user is mentioned.
    If the value of this parameter doesn't match exactly with an existing GitHub user name, it throws an error.

.PARAMETER Commenter
    To Limit searches to issues or pull requests in which a specific user commented.
    If the value of this parameter doesn't match exactly with an existing GitHub user name, it throws an error.

.PARAMETER Involves
    To Limit searches to issues or pull requests which were either created by a specific user, assigned to that user, mention that user, or were commented on by that user.
    If the value of this parameter doesn't match exactly with an existing GitHub user name, it throws an error.

.PARAMETER State
    Filter issues and/or pull requests based on whether they are open or closed.

.PARAMETER Labels
    Filters issues and/or pull requests based on their labels.
    Limitation : this doesn't retrieve labels containing spaces or forward slashes.

    If multiple labels are specified, only issues which have all the specified labels are returned.

.PARAMETER No
    To Limit searches to issues or pull requests which are missing certain metadata : label, milestone or assignee.

.PARAMETER Language
    Searches for issues and/or pull requests within repositories that match a certain language.

.PARAMETER Repo
    To Limit searches to issues and/or pull requests within a specific repository.

.PARAMETER SortBy
    To specify on which field the results should be sorted on : number of comments, creation date or last updated date.
    By default, the results are sorted by best match.

.EXAMPLE
    $PowershellPR = Find-GitHubIssue -Type pr -Repo 'powershell/powershell'
    $PowershellPR | Group-Object -Property { $_.User.login } | Sort-Object -Property Count -Descending | Select-Object -First 10

    Gets the username of the 10 largest contributors to the PowerShell repository, in number of pull requests.

.NOTES
    Author : Mathieu Buisson
    
.LINK
    https://github.com/MathieuBuisson/PSGithubSearch
#>
    [CmdletBinding()]
    
    Param(
        [Parameter(Position=0)]
        [string[]]$Keywords,

        [Parameter(Position=1)]
        [ValidateSet('issue','pr')]
        [string]$Type,

        [Parameter(Position=2)]
        [ValidateSet('title','body','comments')]
        [string]$In,

        [Parameter(Position=3)]
        [string]$Author,

        [Parameter(Position=4)]
        [string]$Assignee,

        [Parameter(Position=5)]
        [string]$Mentions,

        [Parameter(Position=6)]
        [string]$Commenter,

        [Parameter(Position=7)]
        [string]$Involves,

        [Parameter(Position=8)]
        [ValidateSet('open','closed')]
        [string]$State,

        [Parameter(Position=9)]
        [string[]]$Labels,

        [Parameter(Position=10)]
        [ValidateSet('label','milestone','assignee')]
        [string]$No,

        [Parameter(Position=11)]
        [string]$Language,

        [Parameter(Position=12)]
        [string]$Repo,

        [Parameter(Position=13)]
        [ValidateSet('comments','created','updated')]
        [string]$SortBy
    )

    If ( $Keywords ) {
        $KeywordFilter = $Keywords -join '+'
    }
    If ( $Labels ) {
        $LabelsFilterArray = Foreach ( $Label in $Labels ) { 'label:{0}' -f $Label }
        [string]$LabelsFilter = If ( $LabelsFilterArray.Count -gt 0 ) { $LabelsFilterArray -join '+' }
    }

    # The remaining filters can be used the same way to build their respective filter strings
    If ( $PSBoundParameters.ContainsKey('Keywords') ) {
        $Null = $PSBoundParameters.Remove('Keywords')
    }
    If ( $PSBoundParameters.ContainsKey('Labels') ) {
        $Null = $PSBoundParameters.Remove('Labels')
    }
    If ( $PSBoundParameters.ContainsKey('SortBy') ) {
        $Null = $PSBoundParameters.Remove('SortBy')
    }    
    [System.Collections.ArrayList]$JoinableFilterStrings = @()
    Foreach ( $ParamName in $PSBoundParameters.Keys ) {
        
        $JoinableFilterString = '{0}:{1}' -f $ParamName.ToLower(), $PSBoundParameters[$ParamName]
        $Null = $JoinableFilterStrings.Add($JoinableFilterString)
    }
    $JoinedFilterStrings = If ($JoinableFilterStrings.Count -gt 0) {$JoinableFilterStrings -join '+'}
    $JoinedFilter = ($KeywordFilter, $JoinedFilterStrings, $LabelsFilter -join '+').Trim('+')
    $QueryString = 'q={0}' -f $JoinedFilter

    If ( $SortBy ) {
        $QueryString += '&sort={0}' -f $SortBy
    }
    $QueryString += '&per_page=100'
    
    $UriBuilder = New-Object System.UriBuilder -ArgumentList 'https://api.github.com'
    $UriBuilder.Path = 'search/issues' -as [uri]
    $UriBuilder.Query = $QueryString

    $BaseUri = $UriBuilder.Uri
    Write-Verbose "Constructed base URI : $($BaseUri.AbsoluteUri)"

    $Response = Invoke-WebRequest -Uri $BaseUri
    If ( $Response.StatusCode -ne 200 ) {

        Write-Warning "The status code was $($Response.StatusCode) : $($Response.StatusDescription)"
    }
    $NumberOfPages = Get-NumberofPage -SearchResult $Response
    Write-Verbose "Number of pages for this search result : $($NumberOfPages)"

    Foreach ( $PageNumber in 1..$NumberOfPages ) {

        $ResultPageUri = $BaseUri.AbsoluteUri + "&page=$($PageNumber.ToString())"

        Try {
            $PageResponse  = Invoke-WebRequest -Uri $ResultPageUri -ErrorAction Stop
        }
        Catch {
            Throw $_.Exception.Message
        }

        # The search API limits the number of requests to 10 requests per minute and per IP address (for unauthenticated requests)
        # We might be subject to the limit on the number of requests if we run function multiple times in the last minute
        $RemainingRequestsNumber = $PageResponse.Headers.'X-RateLimit-Remaining' -as [int]
        Write-Verbose "Number of remaining API requests : $($RemainingRequestsNumber)."

        If ( $RemainingRequestsNumber -le 1 ) {
            Write-Warning "The search API limits the number of requests to 10 requests per minute"
            Write-Warning "Waiting 60 seconds before processing the remaining result pages because we have exceeded this limit."
            Start-Sleep -Seconds 60
        }
        $PageResponseContent = $PageResponse.Content | ConvertFrom-Json

        Foreach ( $PageResult in $PageResponseContent.items ) {            

            $PageResult.psobject.TypeNames.Insert(0,'PSGithubSearch.IssueOrPR')
            $PageResult
        }
    }
}

Function Find-GithubUser {
<#
.SYNOPSIS
    Searches users and/or organisations on GitHub.com based on the specified search keyword(s) and parameters.
    
.DESCRIPTION
    Uses the GitHub search API to find users or organisations on GitHub.com based on the specified search keyword(s) and parameters.

    This API's documentation is available here : https://developer.github.com/v3/search/

    NOTE : The GitHub Search API limits each search to 1,000 results and the number of requests to 10 per minute.
    
.PARAMETER Keywords
    One or more keywords to search.

.PARAMETER Language
    To search users who have repositories written in the specified language.

.PARAMETER In
    To qualify which field is searched. With this qualifier you can restrict the search to just the username (login), public email address (email) or full name (fullname).
    If not specified, the default behaviour is to search in both the username, full name and public email address..

.PARAMETER Type
    To restrict the search to personal accounts or organization accounts.
    By default, both are searched.

.PARAMETER Repos
    To filter the users or organization based on the number of repositories they have.

.PARAMETER Location
    To filter users or organizations based on the location indicated on their profile.

.PARAMETER Followers
    To filter users or organizations based on the number of followers they have.

.PARAMETER SortBy
    To specify on which field the results should be sorted on : number of followers, number of repositories, or when they joined GitHub.
    By default, the results are sorted by best match.

.EXAMPLE
    Find-GithubUser -Type user -Language 'PowerShell' -Location 'Ireland' | Where-Object { $_.Hireable }

    Gets information on GitHub users located in Ireland, who have at least one PowerShell repository and who have indicated on their profile that they are available for hire.

.NOTES
    Author : Mathieu Buisson
    
.LINK
    https://github.com/MathieuBuisson/PSGithubSearch
#>
    [CmdletBinding()]
    
    Param(
        [Parameter(Position=0)]
        [string[]]$Keywords,

        [Parameter(Position=1)]
        [string]$Language,

        [Parameter(Position=2)]
        [ValidateSet('login','email','fullname')]
        [string]$In,

        [Parameter(Position=3)]
        [ValidateSet('user','org')]
        [string]$Type,

        [Parameter(Position=4)]
        [ValidatePattern('^[\d<>][=\d]\d*$')]
        [string]$Repos,

        [Parameter(Position=5)]
        [string]$Location,

        [Parameter(Position=6)]
        [ValidatePattern('^[\d<>][=\d]\d*$')]
        [string]$Followers,

        [Parameter(Position=7)]
        [ValidateSet('followers','repositories','joined')]
        [string]$SortBy
    )

    [string]$QueryString = 'q='
    $EmptyQueryString = $True

    If ( $Keywords ) {
        $QueryString += ($Keywords -join '+')
        $EmptyQueryString = $False
    }
    If ( $Language ) {
        If ( $EmptyQueryString ) {
            $QueryString += 'language:' + $Language
            $EmptyQueryString = $False
        }
        Else {
            $QueryString += '+language:' + $Language
        }
    }
    If ( $In ) {
        If ( $EmptyQueryString ) {
            $QueryString += 'in:' + $In
            $EmptyQueryString = $False
        }
        Else {
            $QueryString += '+in:' + $In
        }
    }
    If ( $Type ) {
        If ( $EmptyQueryString ) {
            $QueryString += 'type:' + $Type
            $EmptyQueryString = $False
        }
        Else {
            $QueryString += '+type:' + $Type
        }
    }
    If ( $Repos ) {
        If ( $EmptyQueryString ) {
            $QueryString += 'repos:' + $Repos
            $EmptyQueryString = $False
        }
        Else {
            $QueryString += '+repos:' + $Repos
        }
    }
    If ( $Location ) {
        If ( $EmptyQueryString ) {
            $QueryString += 'location:' + $Location
            $EmptyQueryString = $False
        }
        Else {
            $QueryString += '+location:' + $Location
        }
    }
    If ( $Followers ) {
        If ( $EmptyQueryString ) {
            $QueryString += 'followers:' + $Followers
            $EmptyQueryString = $False
        }
        Else {
            $QueryString += '+followers:' + $Followers
        }
    }
    If ( $SortBy ) {
        $QueryString += "&sort=$SortBy"
    }

    # Using the maximum number of results per page to limit the number of requests
    $QueryString += '&per_page=100'

    $UriBuilder = New-Object System.UriBuilder -ArgumentList 'https://api.github.com'
    $UriBuilder.Path = 'search/users' -as [uri]
    $UriBuilder.Query = $QueryString

    $BaseUri = $UriBuilder.Uri
    Write-Verbose "Constructed base URI : $($BaseUri.AbsoluteUri)"

    $Response = Invoke-WebRequest -Uri $BaseUri
    If ( $Response.StatusCode -ne 200 ) {

        Write-Warning "The status code was $($Response.StatusCode) : $($Response.StatusDescription)"
    }
    $NumberOfPages = Get-NumberofPage -SearchResult $Response
    Write-Verbose "Number of pages for this search result : $($NumberOfPages)"

    Foreach ( $PageNumber in 1..$NumberOfPages ) {

        $ResultPageUri = $BaseUri.AbsoluteUri + "&page=$($PageNumber.ToString())"

        Try {
            $PageResponse  = Invoke-WebRequest -Uri $ResultPageUri -ErrorAction Stop
        }
        Catch {
            Throw $_.Exception.Message
        }

        # The search API limits the number of requests to 10 requests per minute and per IP address (for unauthenticated requests)
        # We might be subject to the limit on the number of requests if we run function multiple times in the last minute
        $RemainingRequestsNumber = $PageResponse.Headers.'X-RateLimit-Remaining' -as [int]
        Write-Verbose "Number of remaining API requests : $($RemainingRequestsNumber)."

        If ( $RemainingRequestsNumber -le 1 ) {
            Write-Warning "The search API limits the number of requests to 10 requests per minute"
            Write-Warning "Waiting 60 seconds before processing the remaining result pages because we have exceeded this limit."
            Start-Sleep -Seconds 60
        }
        $PageResponseContent = $PageResponse.Content | ConvertFrom-Json

        Foreach ( $PageResult in $PageResponseContent.items ) {
                       
            $UserDetailsResponse = Invoke-WebRequest -Uri $PageResult.url

            If ( ($UserDetailsResponse.Headers.'X-RateLimit-Remaining' -as [int]) -le 1 ) {
                Write-Warning "The search API limits the number of requests to 10 requests per minute"
                Write-Warning "Waiting 60 seconds before processing the remaining result pages because we have exceeded this limit."
                Start-Sleep -Seconds 60
            }
            $UserDetails = $UserDetailsResponse.Content | ConvertFrom-Json

            $UserProperties = [ordered]@{
                            'Full Name' = $UserDetails.name
                            'Company' = $UserDetails.company
                            'Blog' = $UserDetails.blog
                            'Location' = $UserDetails.location
                            'Email Address' = $UserDetails.email
                            'Hireable' = $UserDetails.hireable
                            'Bio' = $UserDetails.bio
                            'Repos' = $UserDetails.public_repos
                            'Gists' = $UserDetails.public_gists
                            'Followers' = $UserDetails.followers
                            'Following' = $UserDetails.following
                            'Joined' = $UserDetails.created_at
                            }

            Add-Member -InputObject $PageResult -NotePropertyMembers $UserProperties -Force

            $PageResult.psobject.TypeNames.Insert(0,'PSGithubSearch.User')
            $PageResult
        }
    }
}

Function Get-NumberofPage {
<#
.SYNOPSIS
    Helper function to get the number of pages from a search result response.    
#>
    [CmdletBinding()]
    [OutputType([System.Int32])]
    Param(
        [Parameter(Mandatory=$True,Position=0)]
        [PSObject]$SearchResult
    )

    $PaginationInfo = $SearchResult.Headers.Link

    If ( -not($PaginationInfo) ) {
        $NumberOfPages = 1
    }
    Else {
        $SplitPaginationInfo = $PaginationInfo -split ', '
        $LastPage = $SplitPaginationInfo | Where-Object { $_ -like '*"last"*' }
        $NumberOfPages = (($LastPage -split '&page=')[1] -split '>')[0] -as [int]
    }
    return $NumberOfPages
}