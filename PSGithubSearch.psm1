#Requires -Version 4

Function Find-GitHubRepository {
<#
.SYNOPSIS
    Searches repositories on GitHub.com according to the specified search keyword(s) and parameters.
    
.DESCRIPTION
    Uses the GitHub search API to find repositories on GitHub.com according to the specified search keyword(s) and parameters.

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
    If not specified, the default behaviour sorts the results by best match.

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
    $NumberOfPages = Get-NumberofPages -SearchResult $Response
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
            Write-Warning "Stopped processing the remaining result pages because we have exceeded this limit."
            break
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
    Searches file contents on GitHub.com according to the specified search keyword(s) and parameters.
    
.DESCRIPTION
    Uses the GitHub search API to find code in files on GitHub.com according to the specified search keyword(s) and parameters.

    This API's documentation is available here : https://developer.github.com/v3/search/

    NOTE : Due to the complexity of searching code, the GitHub Search API has a few restrictions on how searches are performed :
        - Only the default branch is considered. In most cases, this will be the  master  branch.
        - Only files smaller than 384 KB are searchable.
        - Only repositories with fewer than 500,000 files are searchable.

.EXAMPLE

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
        [ValidateSet('file','path')]
        [string]$In,

        [Parameter(Position=3)]
        [ValidatePattern('^[\d<>][=\d]\d*$')]
        [string]$SizeBytes,

        [Parameter(Position=4)]
        [switch]$Fork,

        [Parameter(Position=5)]
        [string]$User,

        [Parameter(Position=5)]
        [ValidatePattern('^[a-zA-Z]+/[a-zA-Z]+')]
        [string]$Repo,

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


}

Function Get-NumberofPages {
<#
.SYNOPSIS
    Helper function to get the number of pages from a search result response.    
#>
    [CmdletBinding()]
    
    Param(
        [Parameter(Mandatory=$True,Position=0)]
        [Microsoft.PowerShell.Commands.HtmlWebResponseObject]$SearchResult
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