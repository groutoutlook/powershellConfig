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

$argsBuilder = {
    # TODO: better use something type safe other than all $args like this.
    $dashArgs = ($args | Where-Object { $_ -like '-*' }) -join " "
    $pureStringArgs = ($args | Where-Object { $_ -notlike '-*' }) 

    $withinAmount = $pureStringArgs[-1] -eq "**" ? 0 : $pureStringArgs[-1] -as [int] ?? 20
    if ($pureStringArgs[-1] -as [int] -and $pureStringArgs.Count -ge 2) {
        $pureStringArgs = $pureStringArgs[0..($pureStringArgs.Count - 2)]
    }
    $patternBetween = $WithinAmount -eq 0 ? ".*?" : ".{0,$WithinAmount}?"

    # I want to search multiple lines.
    if ($pureStringArgs[-1] -eq "*n") {
        $pureStringArgs = $pureStringArgs[0..($pureStringArgs.Count - 2)]
        $patternBetween = '.*?\n.*?' 
        $dashArgs += ' -U'
    }
    
    $pureStringArgs = $pureStringArgs -join $patternBetween

    return $pureStringArgs , $dashArgs
}

function rgj
(
) {
    $pureStringArgs , $dashArgs = $argsBuilder.Invoke($args)
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
    $pureStringArgs , $dashArgs = $argsBuilder.Invoke($args)
    $command = "rg `"$pureStringArgs`"  -g !'*Journal.md' (zoxide query obs) -M 400 -C0 $dashArgs"
    Invoke-Expression $command
}

# HACK: rg in vault's other files.
function igo() { 
    $pureStringArgs , $dashArgs = $argsBuilder.Invoke($args)
    $command = "ig `'$pureStringArgs`'  -g !'*Journal.md' (zoxide query obs) --context-viewer=horizontal $dashArgs"
    Invoke-Expression $command
}

function igj() {
    $pureStringArgs , $dashArgs = $argsBuilder.Invoke($args)
    $command = "ig `'$pureStringArgs`'  -g '*Journal.md' (zoxide query obs) --context-viewer=horizontal $dashArgs"
    # echo $command
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

function Invoke-SudoPwsh {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Command,
        [switch]$HaveProfile,
        [Parameter(ValueFromPipeline = $true)]
        [object]$InputObject,
        [Parameter(ValueFromRemainingArguments = $true)]
        [object[]]$CommandArgs
    )
    begin {
        $pwshArgs = @('-NoLogo', '-NonInteractive', '-ExecutionPolicy', 'Bypass')
        if (-not $HaveProfile) {
            $pwshArgs = @('-NoProfile') + $pwshArgs
        }

        if ($Command) {
            if ($CommandArgs) {
                $Command += ' ' + ($CommandArgs | ForEach-Object { '"{0}"' -f ($_ -replace '"', '\"') }) -join ' '
            }
            $pwshArgs += '-Command', $Command
        }
        elseif ($CommandArgs) {
            $pwshArgs += '-Command', ($CommandArgs | ForEach-Object { '"{0}"' -f ($_ -replace '"', '\"') }) -join ' '
        }

        $sudoArgs = @('--inline', 'pwsh') + $pwshArgs
        $buffer = [System.Collections.Generic.List[object]]::new()
    }

    process {
        # INFO: this is all a kind of string builder, to build this:
        # `sudo --inline pwsh -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$command"`
        $buffer.Add($InputObject)
    }

    end {
        if ($buffer.Count -gt 0) {
            $buffer.ToArray() | sudo @sudoArgs
        }
        else {
            sudo @sudoArgs
        }
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
    wsl $args --cd ~
}

# INFO: since some of the cli utils take quote as exact match, have to invoke like this.
function zq {
    Invoke-Expression "zoxide query $($args -join " ")" 
}
function zqi {
    Invoke-Expression  "zoxide query -i $($args -join " ")"
}
function zb {
    Invoke-Expression  "z $(zqb ($($args -join ' ')))"
}
function zbi {
    Invoke-Expression  "z $(zqbi ($($args -join ' ')))"
}
function zqb {
    Invoke-Expression  "zoxide query $($args -join " ") --base-dir $pwd"
}
function zqbi {
    Invoke-Expression  "zoxide query -i $($args -join " ") --base-dir $pwd"
}
function ze {
    Invoke-Expression "zoxide edit $($args -join " ")" 
}
function za {
    Invoke-Expression "zoxide add $($args -join " ")" 
}
function zaa($path = $pwd) {
    gci $path | % { za $_ && Write-Host "Add Path $_ to zoxide database." }
}

Set-Alias zo zq
Set-Alias zoi zqi
Set-Alias cdb zb
Set-Alias rgr scooter

# INFO: vscode quick open, with line/column number
function ccb {
    $paramPath = $null
    $paramLine = $null
    $paramCol = $null

    # Helper scriptblock to parse "path:line:col" or "path"
    $ParsePathStr = {
        param($str)
        if ([string]::IsNullOrWhiteSpace($str)) { return $null }
        # Clean quotes
        $str = $str -replace '^"|"$','' -replace "^'|'$",''
        
        if (Test-Path -LiteralPath $str) { return @{ Path=$str; Line=$null; Col=$null } }
        # Handle path:line or path:line:col
        if ($str -match "^(.+):(\d+)(?::(\d+))?$") {
            $p = $matches[1]
            if (Test-Path -LiteralPath $p) {
                return @{ Path=$p; Line=$matches[2]; Col=$matches[3] }
            }
        }
        return $null
    }

    $parsed = $null
    $argIdx = 0

    # 1. Try first arg as path
    if ($args.Count -gt 0) {
        $parsed = & $ParsePathStr $args[0]
        if ($parsed) {
            $argIdx = 1
        }
    }

    # 2. Parse overrides from remaining args
    if ($args.Count -gt $argIdx) {
        $paramLine = $args[$argIdx]
    }
    if ($args.Count -gt ($argIdx + 1)) {
        $paramCol = $args[$argIdx + 1]
    }

    # 3. If no path from args, try clipboard
    if (-not $parsed) {
        $clipboardContent = Get-Clipboard | Out-String
        if ($clipboardContent) {
           $parsed = & $ParsePathStr $clipboardContent.Trim()
        }
        
        if (-not $parsed) {
            Write-Error "Not Path, check again."
            return
        }
    }

    # 4. Resolve final Line/Col
    $fileResult = $parsed.Path
    # If explicit line arg provided, use it. Else use embedded line.
    $lineResult = if ($paramLine) { $paramLine } else { $parsed.Line }
    # Same for col
    $colResult = if ($paramCol) { $paramCol } else { $parsed.Col }

    $finalArg = "$fileResult"
    if ($lineResult) { 
        $finalArg += ":$lineResult"
        if ($colResult) { $finalArg += ":$colResult" }
    }
    
    code --goto "$finalArg"
}

function rb {
    just build ($args.Length ? "$($args -join ' ')" : $null)
}
function rt {
    just test ($args.Length ? "$($args -join ' ')" : $null)
}
function rr {
    just run ($args.Length ? "$($args -join ' ')" : $null)
}
function rfmt {
    just format ($args.Length ? "$($args -join ' ')" : $null)
}
function rd {
    just deploy ($args.Length ? "$($args -join ' ')" : $null)
}
function rs {
    just seek ($args.Length ? "$($args -join ' ')" : $null)
}
function rw {
    just watch ($args.Length ? "$($args -join ' ')" : $null)
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
function tre() {
    lstr --hyperlinks --icons -gG -s -L=2 --dirs-first --natural-sort $args
    Write-Host "depth flags : -L=2" -ForegroundColor Green
}
function trei() {
    lstr interactive --icons -gG -s --dirs-first --natural-sort $args
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

function pcb {
    $targets = $args
    if ($targets.Count -eq 0) {
        $targets = @(Get-Clipboard)
    }

    foreach ($file in $targets) {
        if ([string]::IsNullOrWhiteSpace($file)) { continue }

        # Remove potential quotes from string paths
        $file = $file -replace '"', ''
        
        if (-not (Test-Path $file)) {
             Write-Warning "File not found: $file"
             continue
        }

        $ext = [System.IO.Path]::GetExtension($file)
        switch -Regex ($ext) {
            '\.(kicad_pcb|pcbdoc)$' { & pcbnew $file }
            '\.(kicad_sch|schdoc)$' { & eeschema $file }
            default { Write-Warning "Unknown file type for KiCad: $file" }
        }
    }
}
