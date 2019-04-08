#---------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.
# --------------------------------------------------------------------------------------------

param(
    [String]$organization,
    [String]$project,
    [String]$path,
    [String]$repository,
    [String]$wikiurl,
    [String]$wikipath
)

if (!$organization) {
    $organization = Read-Host 'Enter your organization url (e.g. https://dev.azure.com/microsoftorg):'
}

if (!$project) {
    $project = Read-Host 'Enter your Azure Devops project where you want to host the wiki?'
}

$ErrorActionPreference = "Stop"

function New-TemporaryDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    [string] $name = [System.Guid]::NewGuid()
    New-Item -ItemType Directory -Path (Join-Path $parent $name)
}

# Handle long paths - 
$longpath = git config --get --system core.longpaths
$disable_longpath = 0
git config http.postBuffer 524288000
if(!($longpath -eq 'true')) {
    git config --system core.longpaths true
    $disable_longpath = 1
}
else { 
    Write-host 'Long paths is already enabled'
}

# uninstall existing devops extension, if there
try
{ 
    Write-Host("Uninstalling existing extension if installed.")
    az extension remove -n azure-devops
}
catch
{
    Write-Host("Azure Devops extension not installed.")
}

# Install devops extension 
Write-Host("Installing dev version of devops extension (For wiki commands).")
az extension add --source https://github.com/atbagga/DevopsExtension/releases/download/test/azure_devops-0.5.0-py2.py3-none-any.whl -y

$wiki_dir = Get-Location

# Clone the main wiki
if ($wikiurl) { 
    Write-Host("Cloning wiki repository " + $wikiurl)
    git clone $wikiurl

    $wikiname = $wikiurl.substring($wikiurl.LastIndexOf('/') + 1)
    # change directory to Wiki repo
    $cur_dir = Get-Location
    Set-Location -Path (Join-Path -Path $cur_dir -ChildPath $wikiname)
    $wiki_dir = Get-Location
}
elseif (!$wikipath) {
    $yes_no = Read-Host 'Are we in the correct wiki clone directory (yes/no)?'
    if ($yes_no.ToLower() -eq 'no') {
        $wikipath = Read-Host 'Enter the wiki clone directory'
    }
}

if ($wikipath) {
    Set-Location -Path $wikipath
    $wiki_dir = Get-Location
}

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
git init

Write-host 'Copying files'
# Copying items 
Copy-Item -Path $folder_path -Destination $dest_dir -recurse -Force 
Copy-Item -Path $attachments_dir -Destination $dest_dir -recurse -Force
if([System.IO.File]::Exists($folder_path + '.md')){
    $file_path = $folder_path + '.md'
    Copy-Item -Path $file_path -Destination $dest_dir    
}

git add .
git commit -am "Creating team wiki from azurewiki"
git push

$wiki_to_create = $repository + '.wiki'
$wiki_obj = az devops wiki create --name $wiki_to_create --repository $repository --mapped-path / --type codewiki -v master -o json --org $organization --project $project

# uninstall devops extension 
Write-Host("Uninstalling dev version of devops extension.")
az extension remove -n azure-devops

Write-Host("Installing released version of devops extension.")
az extension add -n azure-devops

# reset git setting if we had set it 
if(!($disable_longpath -eq 1)) {
    git config --system core.longpaths false
}

$wiki_remote_url = $wiki_obj | ConvertFrom-Json | select -ExpandProperty remoteUrl

Write-Host 'Here is your new wiki - ' $wiki_remote_url
Set-Location $wiki_dir
