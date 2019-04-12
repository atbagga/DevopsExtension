# # # # # # # # # # # # # # # PARAMETER DESCRIPTION # # # # # # # # # # # # # # # # # # # 

# -organization : Organization url where the new wiki is to be hosted. 
# -project : Project name where the new wiki is to be hosted.
# -path : Folder path relative from root of repository from where new wiki is to be published.
# -repository : Name of the backing repository for the new wiki.
# -wikiurl : [Required - if wikipath is not specified] Clone url of the wiki which is to be split. This can be some non wiki git repository also.
# -wikipath : [Required - if wikiurl not specified] If the wiki to be split is already cloned locally then use this instead of wikiurl. Directory path where the wiki repository is already cloned locally. 
# -commitmessage : Commit message for the new wiki. All files will be added with this in a single commit.

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

param(
    [String]$organization,
    [String]$project,
    [String]$path,
    [String]$repository,
    [String]$wikiurl,
    [String]$wikipath,
    [String]$commitmessage
)

$script_directory = Get-Location

try {

    $ErrorActionPreference = "Stop"

    $wiki_dir = Get-Location

    # Clone the main wiki
    if ($wikiurl) {
        $is_git = git rev-parse --is-inside-work-tree
        if($is_git -eq 'true' -or $is_git -eq 'false') {
            throw 'We need to clone the wiki repository here. Invoke the script from outside of a git repository.'
        } 

        Write-Host("Cloning wiki repository " + $wikiurl)
        git clone $wikiurl

        $wikiname = $wikiurl.substring($wikiurl.LastIndexOf('/') + 1)
        # change directory to Wiki repo
        $cur_dir = Get-Location
        Set-Location -Path (Join-Path -Path $cur_dir -ChildPath $wikiname)
        $wiki_dir = Get-Location
    }
    elseif ($wikipath) {
        Set-Location -Path $wikipath
        $wiki_dir = Get-Location
        
        # verify git repository
        $is_git = git rev-parse --is-inside-work-tree
        if(!($is_git -eq 'true')) {
            throw '-wikipath should have the repository already cloned. This does not look like a valid git repository path.'
        } 
    }

    elseif (!$wikipath) {
       throw 'Either provide -wikiurl <Clone URL of Wiki/Repo to split> OR -wikipath <local directory path where repo is cloned if the wiki is already cloned>'
    }

    if (!$organization) {
        $organization = Read-Host 'Enter your organization url (e.g. https://dev.azure.com/microsoftorg)'
    }

    if (!$project) {
        $project = Read-Host 'Enter your Azure Devops project where you want to host the wiki'
    }

    function New-TemporaryDirectory {
        $parent = [System.IO.Path]::GetTempPath()
        [string] $name = [System.Guid]::NewGuid()
        New-Item -ItemType Directory -Path (Join-Path $parent $name)
    }

    # uninstall existing devops extension, if there
    Write-Host("Uninstalling existing extension if installed.")
    az extension remove -n azure-devops

    # Install devops extension 
    Write-Host("Installing dev version of devops extension (For wiki commands).")
    az extension add --source https://github.com/atbagga/DevopsExtension/releases/download/test/azure_devops-0.5.0-py2.py3-none-any.whl -y

    if([string]::IsNullOrWhiteSpace($path))
    {
        $path = Read-Host 'What part of hierarchy do you want to publish? (ex: InteractionsAndSearch/TeamProtcol)'
    }

    # what are we copying?
    $folder_path = Join-Path $wiki_dir $path
    $attachments_dir = Join-Path -Path $wiki_dir -ChildPath '.attachments'

    if([string]::IsNullOrWhiteSpace($repository))
    {
        $repository = Read-Host 'Enter the repository name to create (This will be the backing repository for your wiki e.g. NetworkingTeam): '
    }

    # Create a backing repository for code wiki
    Write-Host("Creating repository with name " + $repository)
    $repo_obj = az repos create --name $repository --project $project --organization $organization -o json
    $remote_url = $repo_obj | ConvertFrom-Json | select -ExpandProperty remoteUrl
    Write-Host("Clone url is - " + $remote_url)

    # clone the new repo
    $dest_dir = New-TemporaryDirectory
    Set-Location -Path $dest_dir
    git clone $remote_url

    # Change directory to repository and initialize the repo
    $dest_dir = Join-Path -Path $dest_dir -ChildPath $repository
    Set-Location -Path $dest_dir

    # Handle long paths and big files 
    git config http.postBuffer 524288000
    git config core.longpaths true

    Write-host 'Copying files...'

    # Copying main folder recursively
    Copy-Item -Path $folder_path -Destination $dest_dir -recurse -Force 

    # copy attachments directory
    if([System.IO.Directory]::Exists($attachments_dir)){
        Copy-Item -Path $attachments_dir -Destination $dest_dir -recurse -Force
    }

    # copy .md file corresponding to main folder if exists
    if([System.IO.File]::Exists($folder_path + '.md')){
        $file_path = $folder_path + '.md'
        Copy-Item -Path $file_path -Destination $dest_dir    
    }
    
    if([string]::IsNullOrWhiteSpace($commitmessage))
    {
        $commitmessage = Read-Host 'Enter commit message (users will see this in revision history)'
    }
    
    if (!$commitmessage){
        $commitmessage = "Automated - splitting team wiki from main wiki"
    }

    git add .
    git commit -am  $commitmessage
    git push

    $wiki_to_create = $repository + '.wiki'
    $wiki_obj = az devops wiki create --name $wiki_to_create --repository $repository --mapped-path / --type codewiki -v master -o json --org $organization --project $project

    # uninstall devops extension 
    Write-Host("Uninstalling dev version of devops extension.")
    az extension remove -n azure-devops

    Write-Host("Installing released version of devops extension.")
    az extension add -n azure-devops

    $wiki_remote_url = $wiki_obj | ConvertFrom-Json | select -ExpandProperty remoteUrl
    Write-Host 'Here is your new wiki - ' $wiki_remote_url
}
finally {
    Set-Location $script_directory
}
