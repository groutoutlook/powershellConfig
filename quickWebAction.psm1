$global:lookupSite = @{
    "reddit"     =  "site%3Areddit.com"
    "rd"         =  "site%3Areddit.com"
    "hackernews" =  "site%3Anews.ycombinator.com"
    "hn"         =  "site%3Anews.ycombinator.com"
    "gh"         =  "site%3Agithub.com"
    "gist"       =  "site%3Agist.github.com"
    "gits"       =  "site%3Agist.github.com"
    "so"         = "site%3Astackoverflow.com"
    "st"         = "site%3Astackexchange.com"
    "su"         = "site%3Asuperuser.com"
    "elec"       = "site%3Aelectronic.stackexchange.com"
    "ms"         = "site%3Alearn.microsoft.com"
    "pwsh"       = "site%3Alearn.microsoft.com" # NOTE: Since it's the same to search pwsh in msdoc.
}

# FIXME: Reason I have to use that variable because of the broken state of some browser could..
# affect my speed for accessing things.
$global:defaultBrowser = "msedge"

# reason to make this function is, I may need some kind of initial or something to do some opreataion after firing the query
function hashmapMatch($argsToMatch) {
    $appendix = $global:lookupSite[$argsToMatch]
    if ( $appendix -ne $null) {
        $argsToMatch = $appendix
    } 
    return $argsToMatch
}

function hvdic(
    $phrase,
    $space_split = 1
) {	
    $query = 'https://hvdic.thivien.net/whv/'
    if ($null -eq $phrase) {
        $phrase = (Get-Clipboard)
    }
    if ($space_split -eq 1) {
        $phrase.ToCharArray() | % { 
            $link = $query + "$_" 
            $url = $link.Substring(0, $link.Length)
            Invoke-Expression "$global:defaultBrowser $url"
        }
    }
}

# INFO: Bang! syntax is useful. You could always search for it.
function Search-DuckDuckGo {
    # TODO: Should make a list of abbrev about what to saerch here.
    $exclamationArray = @()
    foreach ($arg in $args) {
        if ($arg -like "!*") {
            $exclamationArray += $arg
        }
    }

    if ($args[0] -match "^(?:cb|gcb)") {
        $args[0] = "$(Get-Clipboard)"
    }
    elseif ($args[0] -match "^ok$") {
        $args[0] = "PlaceholderQuery"
    }
  
    $args[-1] = hashmapMatch($args[-1])
    $global:oldQuery = $args
			
    $filteredArgs = $args | Where-Object { $_ -notin $exclamationArray }
    $filteredArgsString = $filteredArgs -join "+"
    if ($exclamationArray.count -eq 0) {
        $exQuery = 'https://www.duckduckgo.com/?q=' + $filteredArgsString 
        Invoke-Expression "$global:defaultBrowser $exQuery"
    }
    else {
        foreach ($exArg in $exclamationArray) {
            $exQuery = 'https://www.duckduckgo.com/?q=' + $filteredArgsString + "+" + $exArg
            Invoke-Expression "$global:defaultBrowser $exQuery"
        }
    }
}

Set-Alias -Name dg -Value Search-DuckDuckGo
Set-Alias -Name gg -Value Search-DuckDuckGo

# NOTE: wrap input in single quote
function Select-ID(
    [Parameter(
        # Mandatory = $true,
        ValueFromPipeline = $true
    )]
    $url = (Get-Clipboard),
    [switch]$AllMatches
) {
    # [“Dynamic Programming” is not referring to “computer programming” | Hacker News](https://news.ycombinator.com/item?id=44603349)
    # HACK: lots of false positive with this number 22954711, from SE network in my obs.
    # $id = $url | sls -all "[0-9a-fA-F]{4,}" |%{ $_.Matches.Value}
    $id = $url | sls -All:$AllMatches "[0-9a-fA-F]{4,}" | % { $_.Matches.Value }
    Write-Verbose $id 
    if ($id.GetType().Name -eq "Object[]") {
        $id | % { rgj $_ } 
    }
    else {
        rgj $id
    }
}


Set-Alias -Name id -Value Select-ID

# NOTE: wrap input in single quote
function Invoke-SelectedID(
    [Parameter(
        # Mandatory = $true,
        ValueFromPipeline = $true
    )]
    $url = (Get-Clipboard),
    [switch]$AllMatches
) {
    # [“Dynamic Programming” is not referring to “computer programming” | Hacker News](https://news.ycombinator.com/item?id=44603349)
    # HACK: lots of false positive with this number 22954711, from SE network in my obs.
    # $id = $url | sls -all "[0-9a-fA-F]{4,}" |%{ $_.Matches.Value}
    $id = $url | sls -All:$AllMatches "[0-9a-fA-F]{4,}" | % { $_.Matches.Value }
    Write-Verbose $id 
    if ($id.GetType().Name -eq "Object[]") {
        $finalQuery = $id -join "|"
        igj "$finalQuery"
    }
    else {
        igj $id
    }
}
Set-Alias -Name iid -Value Invoke-SelectedID

# function compSearch {
#     $query = 'https://componentsearchengine.com/search?term='
#     $args | % { $query = $query + "$_+" }
#     $url = $query.Substring(0, $query.Length - 1)
#     Start-Process "$url"
# }
#
# Add-Type -AssemblyName System.Windows.Forms
# # INFO: Streaming services quick-access Twitch and Youtube.
# $dictStreamPage = @{
#     "tw" = "https://www.twitch.tv/groutnotout"
#     "yt" = "https://www.youtube.com/@dell_p1/streams"
# }
#
# function obss {
#     Show-Window obs64
# }
# function Start-Streaming($defaultPages = "tw") {
#
#     $streamingHomepageURI = $dictStreamPage[$defaultPages] 
#     $streamingHomepageURI ??= $dictStreamPage["tw"] 
#     # INFO: Basically wrapping around the `obs-cmd` executable.
#     # Or just simply invoke the shortcut.
#     try {
#         (Get-Process -Name obs64 -ErrorAction Stop) `
#             && obs-cmd streaming start && obs-cmd replay start
#
#     }
#     catch [Microsoft.PowerShell.Commands.ProcessCommandException] {
#         Write-Host "Havent started OBS Studio yet." -ForegroundColor Red
#         Start-Process "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Scoop Apps\OBS Studio.lnk"
#     }
# }
# Set-Alias sstream Start-Streaming
# function Stop-Streaming {
#     # HACK: This is too linear though. Maybe we need them to express more information, or clean the output...
#     # Havent thought of it yet.
#     obs-cmd streaming stop
#     obs-cmd recording stop
#     obs-cmd replay save
#     obs-cmd replay stop
# }
# Set-Alias kstream Stop-Streaming
#
# function Test-Stream(
#     $defaultPages = "tw",
#     $checkStatus = "cli" 
# ) {
#     # Since chrome have my account registered, better automate it here.
#     $defaultStreamingBrowser = "msedge" 
#     # HACK: It's relying on replay status since I toggled it on the same time as streaming.
#     # Should be changed when we have a command like `streaming status` available.
#     $outputCheck = (obs-cmd replay status) | Select-String -Pattern "not"
#     if ($null -ne $outputCheck) {
#         Write-Host "Stream havent started." -ForegroundColor Red
#     }
#     else {
#         Write-Host "Stream started." -ForegroundColor Green
#     }
#
#     if ($checkStatus -match "^cli") {
#         # there may be elegant ways to do this, just implemented something as `obs-cmd streaming status`
#         Write-Host "Check web portal." -ForegroundColor Yellow
#         # $checkStatus = "web"
#     } 
#     if ($checkStatus -match "^w") {
#         $streamingHomepageURI = $dictStreamPage[$defaultPages] 
#         $streamingHomepageURI ??= $dictStreamPage["tw"] 
#
#         Invoke-Expression "$defaultStreamingBrowser $streamingHomepageURI"
#     }
# }
# Set-Alias ckstream Test-Stream
