#Requires -Version 4

Function Find-GitHubRepository {
<#
.SYNOPSIS
    Finds repositories on GitHub.com according to the specified search query and parameters.
    
.DESCRIPTION
    Uses the GitHub search API to find repositories on GitHub.com according to the specified search query and parameters.

    This API's documentation is available here : https://developer.github.com/v3/search/
    
.PARAMETER <ParameterName>
    
.EXAMPLE

.NOTES
    Author : Mathieu Buisson
    
.LINK
    
    
#>
    [CmdletBinding()]
    
    Param(
        [Parameter(Mandatory=$True,Position=0)]
        [string]$KeywordsString,

        [Parameter(Position=1)]
        [string]$Language,

        [Parameter(Position=2)]
        [ValidateSet('name','description','readme')]
        [string]$In,

        [Parameter(Position=3)]
        [ValidatePattern('^[\d<>][=\d]\d*$')]
        [string]$Size,

        [Parameter(Position=4)]
        [ValidateSet('true','only')]
        [string]$Fork,

        [Parameter(Position=5)]
        [string]$Created,

        [Parameter(Position=6)]
        [string]$Pushed,

        [Parameter(Position=7)]
        [string]$User,

        [Parameter(Position=8)]
        [ValidatePattern('^[\d<>][=\d]\d*$')]
        [string]$Stars,

        [Parameter(Position=9)]
        [ValidateSet('stars','forks','updated')]
        [string]$SortBy,

        [Parameter(Position=10)]
        [ValidateSet('asc','desc')]
        [string]$SortOrder
    )

    Add-Type -AssemblyName System.Web
    $QueryString = [System.Web.HttpUtility]::ParseQueryString([string]::Empty)

    [string]$QueryStringValue = $KeywordsString

    If ( $Language ) {
        
    }

    $Uri = 'https://api.github.com/search/repositories?q=Deployment stuff+language:PowerShell&sort=stars&order=desc&per_page=100'

    $Response = Invoke-WebRequest -Uri $Uri
    $PaginationInfo = $Response.Headers.Link

    If ( -not($PaginationInfo) ) {
        $LastPageNumber = 1
    }
    Else {
        $SplitPaginationInfo = $PaginationInfo -split ', '
        $LastPage = $SplitPaginationInfo | Where-Object { $_ -like '*"last"*' }
        $LastPageNumber = (($LastPage -split '&page=')[1] -split '>')[0] -as [int]
    }

    Foreach ( $PageNumber in 1..$LastPageNumber ) {

        $ResultPageUri = $Uri + "&page=$($PageNumber.ToString())"

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

            $PageResult | Select-Object -Property full_name, html_url
        }
    }
}