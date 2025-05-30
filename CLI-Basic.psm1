# INFO: numbat is a kind of bc in both Windows/Linux. There are also Julia if you want to try.
function bc {
    Write-Host "Numbat started." -ForegroundColor Red
    if ($args) {
        numbat -e "$args"
    }
    else {
        Write-Host "Start shell instead" -ForegroundColor Yellow
        numbat 
    }
}

function omniSearchObsidian {
    $query = ""
    $args | % {
        $query = $query + "$_%20"
    }
    Start-Process "obsidian://omnisearch?query=$query" &
}

# function ig() {
#     $dashArgs = ($args | Where-Object { $_ -like '-*' }) -join " "
#     $pureStringArgs = ($args | Where-Object { $_ -notlike '-*' }) -join " "
#     $command = "ig $dashArgs `"$pureStringArgs`""
#     Invoke-Expression $command
# }

function rgj() {
    $dashArgs = ($args | Where-Object { $_ -like '-*' }) -join " "
    $pureStringArgs = ($args | Where-Object { $_ -notlike '-*' }) -join " "
    $command = "rg `"$pureStringArgs`" -g '*Journal.md' (zoxide query obs) -M 400 -A3 $dashArgs"
    Invoke-Expression $command

    if ($? -eq $false) {
        Write-Host "not in those journal.md" -ForegroundColor Magenta
        rg "$($args -join " ")" -g !'*Journal.md' (zoxide query obs) -M 400
        if ($? -eq $false) {
            Search-DuckDuckGo ($args -join " ") 
            Write-Host "Fall back to other search engine." -ForegroundColor Red
        }
        else {
            Write-Host "In other Files in Vault, not in those journal.md" -ForegroundColor Blue
        }
    }
}

# HACK: rg in vault's other files.
function rgo() { 
    $dashArgs = ($args | Where-Object { $_ -like '-*' }) -join " "
    $pureStringArgs = ($args | Where-Object { $_ -notlike '-*' }) -join " "
    $command = "rg `"$pureStringArgs`"  -g !'*Journal.md' (zoxide query obs) -M 400 -C0 $dashArgs"
    Invoke-Expression $command
}

# HACK: rg in vault's other files.
function igo() { 
    $dashArgs = ($args | Where-Object { $_ -like '-*' }) -join " "
    $pureStringArgs = ($args | Where-Object { $_ -notlike '-*' }) -join " "
    $command = "ig `"$pureStringArgs`"  -g !'*Journal.md' (zoxide query obs) --context-viewer=horizontal $dashArgs"
    Invoke-Expression $command
}

function igj() {
    $dashArgs = ($args | Where-Object { $_ -like '-*' }) -join " "
    $pureStringArgs = ($args | Where-Object { $_ -notlike '-*' }) -join " "
    $command = "ig `"$pureStringArgs`"  -g '*Journal.md' (zoxide query obs) --context-viewer=horizontal $dashArgs"
    Invoke-Expression $command
}

# INFO: yazi quick call.
function y {
    $tmp = [System.IO.Path]::GetTempFileName()
    yazi $args --cwd-file="$tmp"
    $cwd = Get-Content -Path $tmp -Encoding UTF8
    if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
        Set-Location -LiteralPath ([System.IO.Path]::GetFullPath($cwd))
    }
    Remove-Item -Path $tmp
}
Set-Alias -Name zz -Value y

function Invoke-SudoPwsh {
    sudo --inline pwsh -Command "$args"
}
# INFO: mousemaster or something related to mouse controlling
function Invoke-KeyMouse {
    Invoke-SudoPwsh "Stop-Process -Name mousemaster*"
    Invoke-SudoPwsh "Stop-Process -Name kanata*"
    if ($args.Length -ne 1) {
        Start-Sleep -Seconds 1 
        Set-LocationWhere mousemaster
        sudo run mousemaster &
        sudo run kanata &
    }
}
Set-Alias -Name msmt -Value Invoke-KeyMouse

function Get-PathFromFiles() {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [string[]]$Strings
    )
    $inputPath = $Strings -join ""
    $isDoubleQuote = $inputPath -match '"' 
    # HACK: since we have cmd and ps1 with differrent style of wrapping path.
    $patternOnQuotes = $isDoubleQuote ? '"([^"]+)"' : "'`([^']+`)'"
    if ($inputPath -match $patternOnQuotes) {
        $path = $matches[1]
        return $path
    }
    else {
        Write-Host "isDoubleQuote is $isDoubleQuote"
        Write-Host "invalid string, not contained any kind of filesystem path."
    }
}

function zsh {
    # INFO: Since I set an experimental flag in powershell which evaluate the ~ symbol. No need to cd to ~ anymore.
    wsl $args --cd ~
    # wsl
}

# INFO: since some of the cli utils take quote as exact match, have to invoke  like this.
function zq {
    Invoke-Expression "zoxide query $($args -join " ")" 
}
function zqi {
    Invoke-Expression  "zoxide query -i $($args -join " ")"
}
function ze {
    Invoke-Expression "zoxide edit $($args -join " ")" 
}
function za {
    Invoke-Expression "zoxide add $($args -join " ")" 
}

Set-Alias zo zq
Set-Alias zoi zqi
Set-Alias rgr scooter

# INFO: vscode quick open, with line/column number
function ccb {
    $clipboardContent = Get-Clipboard
    $lineNumber = ":" + ($args -join ":")
    $isPath = Test-Path $clipboardContent
    if ($isPath) {
        code --goto "$clipboardContent$lineNumber"
    }
    else {
        Write-Error "Not Path, check again."
    }
}

# INFO: same for helix.
function xcb {
    $clipboardContent = Get-Clipboard
    if ($args -ne $null) { $lineNumber = ":" + ($args -join ":") }
    else { $lineNumber = ":1" }
    $isPath = Test-Path $clipboardContent
    if ($isPath) {
        hx "$clipboardContent$lineNumber"
    }
    else {
        Write-Error "Not Path, check again."
    }
}

function rb {
    just build
}
function rr {
    just run
}
function re {
    just -e
}
Set-Alias -Name r -Value just -Scope Global -Option AllScope

# INFO: more alias.
Set-Alias -Name b -Value bat
Set-Alias -Name top -Value btm
Set-Alias -Name du -Value dust
Set-Alias -Name less -Value tspin

# HACK: `f` for quicker `find`
function f() {
    $dashArgs = ($args | Where-Object { $_ -like '-*' }) -join " "
    $pureStringArgs = ($args | Where-Object { $_ -notlike '-*' }) -join " "
    $command = "fd $pureStringArgs --hyperlink $dashArgs"
    Invoke-Expression $command
}

# HACK: `lsd` and `ls` to `exa`
function lsd {
    exa --hyperlink --icons=always $args 
}
Set-Alias -Name ls -Value lsd -Scope Global -Option AllScope

# TODO: check if there are more than the default level (-L=2) of nesting directory.
# NOTE: and echo it? 
function tree() {
    exa --hyperlink -T -L=2 $args 
    Write-Host "depth flags : -L=2" -ForegroundColor Green
}

function Get-Navitldr() {
    $dashArgs = ($args | Where-Object { $_ -like '-*' }) -join " "
    $pureStringArgs = ($args | Where-Object { $_ -notlike '-*' }) -join " "
    # HACK: have to manually null it out... since `navi` dont understand the ''..?
    if ($dashArgs -eq "") { $dashArgs = $null }
    if ($pureStringArgs -eq "") {
        navi
    }
    else {
        navi --tldr $pureStringArgs $dashArgs
    }
}
Set-Alias -Name man -Value Get-Navitldr -Scope Global -Option AllScope
