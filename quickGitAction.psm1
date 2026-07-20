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

function Invoke-GitApplyPatch {
    param([switch] $Check)

    $patchText = Get-Clipboard -Raw
    if ([string]::IsNullOrWhiteSpace($patchText)) {
        throw 'The clipboard is empty.'
    }

    # Restore the prefix only for empty lines that belong to a hunk.
    $lines = [regex]::Split($patchText, "`r`n|`n|`r")
    $targetFile = $null
    $targetLines = $null
    $oldLineNumber = 0
    $oldLines = 0
    $newLines = 0
    $inHunk = $false
    $normalized = foreach ($line in $lines) {
        if ($line -match '^--- a/(.+)$') {
            [void]($targetFile = Join-Path (Get-Location) ($Matches[1] -replace '/', '\'))
            if (Test-Path -LiteralPath $targetFile) {
                [void]($targetLines = Get-Content -LiteralPath $targetFile)
            }
        }
        if ($line -match '^@@ -\d+(?:,(\d+))? \+\d+(?:,(\d+))? @@') {
            [void]($oldLineNumber = [int]($line -replace '^@@ -(\d+).*', '$1'))
            [void]($oldLines = if ($Matches[1]) { [int]$Matches[1] } else { 1 })
            [void]($newLines = if ($Matches[2]) { [int]$Matches[2] } else { 1 })
            [void]($inHunk = $true)
            $line
            continue
        }

        if ($inHunk -and ($oldLines -gt 0 -or $newLines -gt 0)) {
            if ($targetLines -and $oldLineNumber -le $targetLines.Count) {
                if ($line.StartsWith(' ') -or $line.StartsWith('-')) {
                    [void]($lineContent = $line.Substring(1))
                    if (($lineContent -replace '\s', '') -eq ($targetLines[$oldLineNumber - 1] -replace '\s', '')) {
                        [void]($line = $line.Substring(0, 1) + $targetLines[$oldLineNumber - 1])
                    }
                }
                $isWhitespaceOnlyContext = $line.Length -eq 0 -or
                ($line.StartsWith(' ') -and $line.Substring(1) -match '^\s*$')
                if ($isWhitespaceOnlyContext) {
                    [void]($line = ' ' + $targetLines[$oldLineNumber - 1])
                }
            }
            if ($line.StartsWith('+')) { [void]($newLines--) }
            elseif ($line.StartsWith('-')) { [void]($oldLines--); [void]($oldLineNumber++) }
            elseif ($line.StartsWith(' ')) { [void]($oldLines--); [void]($newLines--); [void]($oldLineNumber++) }
            elseif ($line.StartsWith('\')) { }
            else { [void]($line = " $line"); [void]($oldLines--); [void]($newLines--); [void]($oldLineNumber++) }
            if ($oldLines -eq 0 -and $newLines -eq 0) { [void]($inHunk = $false) }
        }

        $line
    }
    $patchText = [string]::Join("`n", $normalized)
    if (-not $patchText.EndsWith("`n")) { $patchText += "`n" }

    $patchFile = New-TemporaryFile
    try {
        [IO.File]::WriteAllText($patchFile, $patchText, [Text.UTF8Encoding]::new($false))
        git apply --recount --ignore-whitespace $(if ($Check) { '--check' }) $patchFile
    }
    finally {
        Remove-Item $patchFile -Force -ErrorAction SilentlyContinue
    }
}

Set-Alias -Name Apply-GitPatch -Value Invoke-GitApplyPatch

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
