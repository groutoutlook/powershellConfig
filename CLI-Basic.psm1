# CLI-specific env var.
$env:EZA_CONFIG_DIR = "$env:USERPROFILE\.config\eza"
$env:_ZO_FZF_OPTS = "--height=35% --bind one:accept"

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
    # INFO: Im so lazy typing .* everytime. for space you should type \s. or wrap in quotes. 
    $dashArgs = ($args | Where-Object { $_ -like '-*' }) -join " "
    $pureStringArgs = ($args | Where-Object { $_ -notlike '-*' }) -join '.*'
    $command = "rg `"$pureStringArgs`" -g '*Journal.md' (zoxide query obs) -M 400 -A3 $dashArgs"
    Invoke-Expression $command

    if ($? -eq $false) {
        Write-Host "not in those journal.md" -ForegroundColor Magenta
        rg "$($args -join ".*")" -g !'*Journal.md' (zoxide query obs) -M 400
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
    $pureStringArgs = ($args | Where-Object { $_ -notlike '-*' }) -join '.*'
    $command = "rg `"$pureStringArgs`"  -g !'*Journal.md' (zoxide query obs) -M 400 -C0 $dashArgs"
    Invoke-Expression $command
}

# HACK: rg in vault's other files.
function igo() { 
    $dashArgs = ($args | Where-Object { $_ -like '-*' }) -join " "
    $pureStringArgs = ($args | Where-Object { $_ -notlike '-*' }) -join '.*'
    $command = "ig `"$pureStringArgs`"  -g !'*Journal.md' (zoxide query obs) --context-viewer=horizontal $dashArgs"
    Invoke-Expression $command
}

function igj() {
    $dashArgs = ($args | Where-Object { $_ -like '-*' }) -join " "
    $pureStringArgs = ($args | Where-Object { $_ -notlike '-*' }) -join '.*'
    $command = "ig `"$pureStringArgs`"  -g '*Journal.md' (zoxide query obs) --context-viewer=horizontal $dashArgs"
    Invoke-Expression $command
}

# INFO: yazi quick call.
function yz {
    $tmp = [System.IO.Path]::GetTempFileName()
    yazi $args --cwd-file="$tmp"
    $cwd = Get-Content -Path $tmp -Encoding UTF8
    if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
        Set-Location -LiteralPath ([System.IO.Path]::GetFullPath($cwd))
    }
    Remove-Item -Path $tmp
}
Set-Alias -Name zz -Value yz

function Invoke-SudoPwsh (
    [string]$command, # TODO: could be a ScriptBlock.
    [switch]$haveProfile 
) {
    if ($haveProfile) {
        sudo --inline pwsh -NoLogo -NonInteractive -ExecutionPolicy Bypass -Command "$command"
    }
    else {
        sudo --inline pwsh -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$command"
    }
}
# INFO: mousemaster or something related to mouse controlling
function Invoke-KeyMouse {
    if ($args.Length -ne 1) {
        sudo run pwsh -NoLogo -NoProfile -Command "Stop-Process -Name mousemaster*; D:\usr\bin\mousemaster --configuration-file=D:\usr\bin\mousemaster.properties" &
    }
    else {
        Invoke-SudoPwsh "Stop-Process -Name mousemaster*"
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
    just build ($args.Length ? "$args -join ' '" : $null)
}
function rt {
    just test ($args.Length ? "$args -join ' '" : $null)
}
function rr {
    just run ($args.Length ? "$args -join ' '" : $null)
}
function rfmt {
    just format ($args.Length ? "$args -join ' '" : $null)
}
function rd {
    just deploy ($args.Length ? "$args -join ' '" : $null)
}
function rs {
    just seek ($args.Length ? "$args -join ' '" : $null)
}
function rw {
    just watch ($args.Length ? "$args -join ' '" : $null)
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
    eza --hyperlink --icons=always $args 
}
Set-Alias -Name ls -Value lsd -Scope Global -Option AllScope

# HACK: `la` since I pressed that a lot.
function la {
    eza --hyperlink --icons=always -al $args  
}
Set-Alias -Name ls -Value lsd -Scope Global -Option AllScope


# TODO: check if there are more than the default level (-L=2) of nesting directory.
# NOTE: and echo it? 
function tree() {
    eza --hyperlink -T -L=2 $args 
    Write-Host "depth flags : -L=2" -ForegroundColor Green
}

Set-Alias -Name nc -Value ncat -Scope Global -Option AllScope
function ncput(
    [String]$content = (Get-Clipboard),
    $netAddress = "192.168.1.42",
    $defaultPort = 9001
) {
    $content | % { $_ | ncat $netAddress $defaultPort -w 20s
        Write-Host "Done sent $_" -ForegroundColor Green
    }
}
function ncget(
    $defaultPort = 9001
) {
    $getString = ncat -lvp $defaultPort -w 20
    if ($?) {
        Set-Clipboard $getString
        Write-Host "Clipboard set to: $getString" -ForegroundColor Green
    }
    else {
        Write-Host "nothing came up...? Timeout." -ForegroundColor Red
    }
}

Set-Alias -Name bc -Value fend -Scope Global -Option AllScope
