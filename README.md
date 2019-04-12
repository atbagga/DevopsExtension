# Azure Devops Wiki Splitter 

You can use the script in this repository to publish code repositories from different hierarchy from a repository. 
You can split a code wiki/project wiki into multiple code wikis.

## Limitations

Proceed to use the script if you are OK with the following limitations.

1. Attachments directory is copied blindly in the split repository. This can add substantial size in some cases without using most of those files. 
1. File history will be lost. This will create a new wiki all revisions history of your pages will not be available in the new wiki.
1. Links referring to files outside your area of split will be broken. 


## Pre-requisites 

1. Azure-Cli should be installed. Refer [this](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) for platform specific installation instructions.
- Run `az login`. Use the same AAD account which you use for devops login. 

2. Git.exe (Download and install git for windows. Linux and Mac have git already installed by default.)
- Git credential manager should have the credentials. You can do this by cloning a private repo from the same account. Clone the repository you want to split and that can be reused in the script too. 


## Syntax 

split_wiki.ps1 -wikiurl _WikiCloneURl_  -organization _DevOpsOrganizationUrl_ -project _ProjectName_ -path _RelativePathToPublishNewWikiFrom_ -repository _NewRepositoryNameForCodeWiki_ -commitmessage _'Commit Message For The New Wiki Creation'_

* _Powershell execution policy on the machine might stop you from using the script. You can bypass the policy to run the script like this-_

    **`PowerShell.exe -ExecutionPolicy Bypass`** `./split_wiki -wikiurl <wikiclone url>  -organization https://dev.azure.com/myorganization -project DevopsTest -path /Network/TeamA -repository TeamAWiki --commitmessage 'Splitting my team wiki from main wiki'` 

## Parameter Description

 - **-organization** : Organization url where the new wiki is to be hosted. e.g. https://dev.azure.com/officeorg
 - **-project** : Project name where the new wiki is to be hosted. 
 - **-path** : Folder path relative from root of repository from where new wiki is to be published. /Network-Team/TSGs/
 - **-repository** : Name of the backing repository for the new wiki. e.g. NetworkTSGs (Wiki name will be created as NetworkTSGs.wiki)
 - **-wikiurl** : [Required - if wikipath is not specified] Clone url of the wiki which is to be split. This can be some non wiki git repository also. e.g. https://dev.azure.com/officeorg/DefaultCollection/Office/_git/officewiki
 - **-wikipath** : [Required - if wikiurl not specified] If the wiki to be split is already cloned locally then use this instead of wikiurl. Directory path where the wiki repository is already cloned locally. e.g. C:\officewiki\
 - **-commitmessage** : Commit message for the new wiki. All files will be added with this in a single commit.


## Sample usage

```
split_wiki.ps1 -wikiurl <wikiclone url>  -organization https://dev.azure.com/myorganization -project DevopsTest -path /Network/TeamA -repository TeamAWiki -commitmessage 'Automated - Split wiki from main wiki'
```

OR

If you already have the wiki repo cloned locally you can use -wikipath to point the script to use the cloned repo
```
split_wiki.ps1 -wikipath c:/officewiki/  -organization https://dev.azure.com/myorganization -project DevopsTest -path /Network/TeamA -repository TeamAWiki -commitmessage 'Automated - Split wiki from main wiki'
```

![](WikiMigrationScript.gif)


## Troubleshooting

1. Powershell execution policy might disallow unsigned scripts. You can bypass the policy by running the script like below- 
`PowerShell.exe -ExecutionPolicy Bypass ./split_wiki -wikiurl <wikiclone url>  -organization https://dev.azure.com/myorganization -project DevopsTest -path /Network/TeamA -repository TeamAWiki --commitmessage 'Splitting my team wiki from main wiki'`
1. `The user '' does not have permissions for the action.`. You do not have appropriate permissions for creating a repository in the project. Get the permissions from the Administrator to try again.
1. git failure - Verify that the git clone is working on your machine for any repository in the same account. 
1. If you see path too long issues in windows. Use `git config --system core.longpath true` to allow long paths in git. 
