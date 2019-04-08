# DevopsExtension

You can use the script in this repository to publish code repositories from different hierarchy from a repository. 
You can split a code wiki/ project wiki into multiple code wikis.

Pre-requisites 
1. Azure-Cli
1. git

# Sample usage

```
split_project_wiki.ps1 -wikiurl <wikiclone url>  -organization https://dev.azure.com/myorganization -project DevopsTest -path /Network/TeamA -repository TeamAWiki
```

OR just invoke the script and use interactively - 
```
split_project_wiki.ps1 -wikiurl <wikiclone url>  
```

OR if you already have the wiki repo cloned locally you can skip the -wikiurl param
```
split_project_wiki.ps1 
```

