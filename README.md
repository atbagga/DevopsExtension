# Azure Devops Wiki Splitter 

You can use the script in this repository to publish code repositories from different hierarchy from a repository. 
You can split a code wiki/ project wiki into multiple code wikis.

Pre-requisites 
1. Azure-Cli
- Run `az login` to make sure `az devops project list --org <orgurl>` is working.

1. git
- Git credential manager should have the credentials. You can do this by cloning a private repo from the same account. Clone the repository you want to split and that can be reused in the script too. 

# Sample usage

```
split_wiki.ps1 -wikiurl <wikiclone url>  -organization https://dev.azure.com/myorganization -project DevopsTest -path /Network/TeamA -repository TeamAWiki
```

OR just invoke the script and use interactively - 
```
split_wiki.ps1 -wikiurl <wikiclone url>  
```

OR if you already have the wiki repo cloned locally you can skip the -wikiurl param
```
split_wiki.ps1 
```

