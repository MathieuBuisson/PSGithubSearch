#Requires -Version 4

Function Find-GitHubRepository {
<#
.SYNOPSIS
    Finds repositories on GitHub.com according to the specified search query and parameters.
    
.DESCRIPTION
    Uses the GitHub search API to find repositories on GitHub.com according to the specified search query and parameters.

    This API's documentation is available here : https://developer.github.com/v3/search/
    
.PARAMETER Keywords

.PARAMETER Language

.PARAMETER In

.PARAMETER SizeKB

.PARAMETER Fork

.PARAMETER User

.PARAMETER Stars

.PARAMETER SortBy

.PARAMETER SortOrder
    
.EXAMPLE

.NOTES
    Author : Mathieu Buisson
    
.LINK    
    
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
        [string]$SortBy,

        [Parameter(Position=8)]
        [ValidateSet('asc','desc')]
        [string]$SortOrder
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
    If ( $SortOrder ) {
        $QueryString += "&sort=$SortOrder"
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

            $PageResult
        }
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