#
# Module manifest for module 'PSGithubSearch'
#
# Generated by: Mathieu Buisson
#
# Generated on: 10/2/2016
#

@{

# Script module or binary module file associated with this manifest.
RootModule = '.\PSGithubSearch.psm1'

# Version number of this module.
ModuleVersion = '1.0.29'

# ID used to uniquely identify this module
GUID = '7fbef890-14aa-4313-a90b-aedf28b13810'

# Author of this module
Author = 'Mathieu Buisson'

# Company or vendor of this module
CompanyName = 'Unknown'

# Copyright statement for this module
Copyright = '(c) 2016 Mathieu Buisson. All rights reserved.'

# Description of the functionality provided by this module
Description = ' PowerShell module to search for the following on GitHub :
- Repositories
- Code 
- Issues
- Pull requests
- Users

It uses the GitHub search API and implements most of its features in user-friendly cmdlets and parameters.  
The API documentation is available here : https://developer.github.com/v3/search/'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '4.0'

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
FormatsToProcess = 'PSGithubSearch.format.ps1xml'

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module
FunctionsToExport = 'Find-GitHubCode', 'Find-GitHubIssue', 'Find-GitHubRepository', 'Find-GithubUser'

# Cmdlets to export from this module
#CmdletsToExport = '*'

# Variables to export from this module
#VariablesToExport = '*'

# Aliases to export from this module
#AliasesToExport = '*'

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = 'GitHub'

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/MathieuBuisson/PSGithubSearch/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/MathieuBuisson/PSGithubSearch'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        # ReleaseNotes = ''

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

