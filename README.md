# PSGithubSearch  

[![Build status](https://ci.appveyor.com/api/projects/status/gg800e2jxt663q5i/branch/master?svg=true)](https://ci.appveyor.com/project/MathieuBuisson/psgithubsearch/branch/master) [![Coverage Status](https://coveralls.io/repos/github/MathieuBuisson/PSGithubSearch/badge.svg?branch=master)](https://coveralls.io/github/MathieuBuisson/PSGithubSearch?branch=master)  

PowerShell module to search for the following on GitHub :
- Repositories
- Code 
- Issues
- Pull requests
- Users

It uses the GitHub search API and implements most of its features with user-friendly cmdlets and parameters.  
**NOTE :** The GitHub Search API limits each search to 1,000 results and the number of unauthenticated requests to 10 per minute.


This module contains 4 cmdlets :  
**Find-GitHubCode**  
**Find-GitHubIssue**  
**Find-GitHubRepository**  
**Find-GithubUser**  


It requires PowerShell version 4 (or later).



## Find-GitHubCode :




Uses the GitHub search API to find code in files on GitHub.com based on the specified search keyword(s) 
and parameters.

This API's documentation is available here : https://developer.github.com/v3/search/

**NOTE :** Due to the complexity of searching code, the GitHub Search API has a few restrictions on how 
searches are performed :
- Only the default branch is considered. In most cases, this will be the  master  branch.
- Only files smaller than 384 KB are searchable.
- Only repositories with fewer than 500,000 files are searchable.  


### Parameters :



**Keywords :** One or more keywords or code snippet to search.  



**User :** To Limit searches to code owned by a specific user.
If the value of this parameter doesn't match exactly with an existing GitHub user name, it throws an error.  



**Repo :** To Limit searches to code in a specific repository.
The value of this parameter must match exactly with the full name of an existing GitHub repository, formatted as : Username/RepoName.  



**Language :** To search code based on the language it is written in.  



**In :** To qualify which field is searched. With this qualifier you can restrict the search to files contents or to files paths.
If not specified, the default behaviour is to search in both files contents and paths.  



**SizeBytes :** To search only files that match a certain size (in bytes).  



**Fork :** Filters whether forked repositories should be included in the search.
By default, forks are not searched unless the fork has more stars than the parent repository.  
If not specified, it defaults to False .



**FileName :** Filters the search to files with a name containing the string specified via this parameter.  



**Extension :** Filters the search to files with the specified extension.  



**SortByLastIndexed :** Sorts the results by how recently a file has been indexed by the GitHub search infrastructure.
By default, the results are sorted by best match.  
If not specified, it defaults to False .



### Examples :



-------------------------- EXAMPLE 1 --------------------------

PS C:\>Find-GitHubCode -User 'MathieuBuisson' -Keywords 'SupportsShouldProcess' -Extension 'psm1'


Finds the .psm1 files which contain the code 'SupportsShouldProcess' in repositories from the user 
'MathieuBuisson'.




## Find-GitHubIssue :



Uses the GitHub search API to find issues and/or pull requests on GitHub.com based on the specified search 
keyword(s) and parameters.

This API's documentation is available here : https://developer.github.com/v3/search/

### Parameters :



**Keywords :** To search issues and/or pull requests containing the specified keyword(s) in their title, body or comments.  



**Type :** To restrict the search to issues only or pull requests only.
By default, both are searched.  



**In :** To qualify which field is searched for the specified keyword(s). With this qualifier you can restrict the search to the title, body or comments of issues and pull requests.
By default, all these fields are searched for the specified keyword(s).  



**Author :** To Limit searches to issues or pull requests created by a specific user.
If the value of this parameter doesn't match exactly with an existing GitHub user name, it throws an error.  



**Assignee :** To Limit searches to issues or pull requests assigned to a specific user.
If the value of this parameter doesn't match exactly with an existing GitHub user name, it throws an error.  



**Mentions :** To Limit searches to issues or pull requests in which a specific user is mentioned.
If the value of this parameter doesn't match exactly with an existing GitHub user name, it throws an error.  



**Commenter :** To Limit searches to issues or pull requests in which a specific user commented.
If the value of this parameter doesn't match exactly with an existing GitHub user name, it throws an error.  



**Involves :** To Limit searches to issues or pull requests which were either created by a specific user, assigned to that user, mention that user, or were commented on by that user.
If the value of this parameter doesn't match exactly with an existing GitHub user name, it throws an error.  



**State :** Filter issues and/or pull requests based on whether they are open or closed.  



**Labels :** Filters issues and/or pull requests based on their labels.
Limitation : this doesn't retrieve labels containing spaces or forward slashes.

If multiple labels are specified, only issues which have all the specified labels are returned.  



**No :** To Limit searches to issues or pull requests which are missing certain metadata : label, milestone or assignee.  



**Language :** Searches for issues and/or pull requests within repositories that match a certain language.  



**Repo :** To Limit searches to issues and/or pull requests within a specific repository.  



**SortBy :** To specify on which field the results should be sorted on : number of comments, creation date or last updated date.
By default, the results are sorted by best match.  



### Examples :



-------------------------- EXAMPLE 1 --------------------------

PS C:\>$PowershellPR = Find-GitHubIssue -Type pr -Repo 'powershell/powershell'


PS C:\>$PowershellPR | Group-Object -Property { $_.User.login } | Sort-Object -Property Count -Descending | Select-Object -First 10

Gets the username of the 10 largest contributors to the PowerShell repository, in number of pull requests.




## Find-GitHubRepository :



Uses the GitHub search API to find repositories on GitHub.com based on the specified search keyword(s) and parameters.

This API's documentation is available here : https://developer.github.com/v3/search/

**NOTE :** The GitHub Search API limits each search to 1,000 results and the number of requests to 10 per minute.

### Parameters :



**Keywords :** One or more keywords to search.  



**Language :** To search repositories based on the language they are written in.  



**In :** To qualify which field is searched. With this qualifier you can restrict the search to just the repository name, description, or readme.
If not specified, the default behaviour is to search in both the name, description and readme.  



**SizeKB :** To search repositories that match a certain size (in kilobytes).  



**Fork :** Filters whether forked repositories should be included ( if the value is 'true' ) or only forked repositories should be returned ( if the value is 'only' ).
If this parameter is not specified, the default behaviour is to exclude forks.  



**User :** To Limit searches to repositories owned by a specific user.
If the value of this parameter doesn't match exactly with an existing GitHub user name, it throws an error.  



**Stars :** To filter repositories based on the number of stars.  



**SortBy :** To specify on which field the results should be sorted on : number of stars, forks or last updated date.
By default, the results are sorted by best match.  



### Examples :



-------------------------- EXAMPLE 1 --------------------------

PS C:\>Find-GitHubRepository -Keywords 'TCP' -Language 'Python'


Searches GitHub repositories which have the word "TCP" in their name or description or readme and are 
written in Python.




-------------------------- EXAMPLE 2 --------------------------

PS C:\>Find-GitHubRepository -Keywords 'TCP' -Language 'Python' -In name


Searches GitHub repositories which have the word "TCP" in their name and are written in Python.




-------------------------- EXAMPLE 3 --------------------------

Find-GitHubRepository -Keywords 'UDP' -In description -SizeKB '>200'


Searches GitHub repositories which have the word "UDP" in their description and are larger than 200 
kilobytes.




-------------------------- EXAMPLE 4 --------------------------

PS C:\>Find-GitHubRepository -Keywords 'PowerShell-Docs' -In name -Fork only


Searches forks which have the word "PowerShell-Docs" in their name.




-------------------------- EXAMPLE 5 --------------------------

PS C:\>Find-GitHubRepository -Keywords 'script' -User 'MathieuBuisson'


Searches GitHub repositories which have the word "script" in their name or description or readme and are 
owned by the user MathieuBuisson.




-------------------------- EXAMPLE 6 --------------------------

Find-GitHubRepository -Keywords 'disk','space' -In readme -Stars '>=10'


Searches GitHub repositories which have both words "disk" and "space" in their readme and have 10 or more 
stars.




-------------------------- EXAMPLE 7 --------------------------

PS C:\>Find-GitHubRepository -SortBy stars -In name -Language 'PowerShell' -Keywords 'Pester'


Searches GitHub repositories written in PowerShell which have the word "Pester" in their name and sorts 
them by the number of stars (descending order).








## Find-GithubUser :



Uses the GitHub search API to find users and/or organisations on GitHub.com based on the specified search 
keyword(s) and parameters.

This API's documentation is available here : https://developer.github.com/v3/search/

**NOTE :** The GitHub Search API limits each search to 1,000 results and the number of requests to 10 per minute.

### Parameters :



**Keywords :** One or more keywords to search.  



**Language :** To search users who have repositories written in the specified language.  



**In :** To qualify which field is searched. With this qualifier you can restrict the search to just the username (login), public email address (email) or full name (fullname).
If not specified, the default behaviour is to search in both the username, full name and public email address..  



**Type :** To restrict the search to personal accounts or organization accounts.
By default, both are searched.  



**Repos :** To filter the users or organization based on the number of repositories they have.  



**Location :** To filter users or organizations based on the location indicated on their profile.  



**Followers :** To filter users or organizations based on the number of followers they have.  



**SortBy :** To specify on which field the results should be sorted on : number of followers, number of repositories, or when they joined GitHub.
By default, the results are sorted by best match.  



### Examples :



-------------------------- EXAMPLE 1 --------------------------

PS C:\>Find-GithubUser -Type user -Language 'PowerShell' -Location 'Ireland' | Where-Object { $_.Hireable }


Gets information on GitHub users located in Ireland, who have at least one PowerShell repository and who have indicated on their profile that they are available for hire.  




