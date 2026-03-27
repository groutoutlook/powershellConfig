function quickInitGit($repo_name = "$(Split-Path $pwd -Leaf)", $remote_branch_name = "origin", $remote = "gh", $default_user = "groutoutlook") {
    # Copy-Item "$(zoxide query pwsh)/.github" $pwd -Recurse
    Copy-Just && git init && git add * && git commit -m "feat: genesis"
    gh repo create $repo_name -d "$repo_name description" --source=. --remote "$remote_branch_name" --push --private 
}

function quickDeInitGit($repo_name = "$(Split-Path $pwd -Leaf)", $remote = "gh", $default_user = "groutoutlook") {
    Remove-FullForce .git
    Set-Clipboard "$default_user/$repo_name"
    gh repo delete $repo_name
}

function Select-RepoLink {
    param($url = (Get-Clipboard))
    
    
    # HACK: Real hack is extracting links from the Markdown links.
    $processedLink = $url
    if ($filtered = filterURI -strings $url -stripUnplay 'all') {
        $processedLink = ($filtered -split "`n")[-1]
    }
    $processedLink = $processedLink -replace "#.*", ""

    if ($processedLink -match "^https") {
        # INFO: here we trim the `?.*` queries part of the URL.
        $trimmedQueryURI = $processedLink -replace "\?.*", "" -replace "/tree/.*", ""
        $repoName = Split-Path $trimmedQueryURI -Leaf
        return $trimmedQueryURI, $repoName
    }
    else {
        return $null, $null
    }
}

function gitCloneClipboard(
    $finalDir = $null, 
    $url = (Get-Clipboard),
    $gitOptions 
) {
    if ($trimmedQueryURI, $repoName = Select-RepoLink $url) {
        git clone --recursive $gitOptions ($trimmedQueryURI) $finalDir && cd $repoName
    }
    else {
        echo ($url).psobject
        Write-Host "Not a link." -ForegroundColor Red
    }
}

Set-Alias -Name gccb -Value gitCloneClipboard

Set-Alias -Name gui -Value gitui
