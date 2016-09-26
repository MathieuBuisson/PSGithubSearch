# PSGithubSearch  

[![Build status](https://ci.appveyor.com/api/projects/status/gg800e2jxt663q5i/branch/master?svg=true)](https://ci.appveyor.com/project/MathieuBuisson/psgithubsearch/branch/master)  


PowerShell module to search for the following on GitHub :
- Repositories
- Code 
- Issues
- Pull requests
- Users

It uses the GitHub search API and implements most of its features in user-friendly cmdlets and parameters.  
The API documentation is available here : https://developer.github.com/v3/search/

NOTE : The GitHub Search API limits each search to 1,000 results and the number of unauthenticated requests to 10 per minute.