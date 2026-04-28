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



# Parse args into pure tokens and dash args (modular helper)
function Get-SearchArgs {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [object[]]$InputArgs
    )
    $isDashOption = {
        param($token)
        return $token -is [string] -and $token -match '^-{1,2}[A-Za-z]'
    }

    $dashArgs = @($InputArgs | Where-Object { $isDashOption.Invoke($_) })
    $pureTokens = @($InputArgs | Where-Object { -not $isDashOption.Invoke($_) })

    return [PSCustomObject]@{ PureTokens = $pureTokens; DashArgs = $dashArgs }
}

# Build search pattern info from pure tokens (returns terms, patternBetween and extra dash args)
function Build-PatternFromPureTokens {
    param(
        [object[]]$PureTokens
    )

    if (-not $PureTokens -or $PureTokens.Count -eq 0) {
        return [PSCustomObject]@{ Terms = @(); PatternBetween = ''; ExtraDash = @() ; Pattern = '' }
    }

    $tokens = @($PureTokens)
    $extraDash = @()

    $last = $tokens[-1]
    $withinAmount = if ($last -eq '**') { 0 } else { ($last -as [int]) ?? 30 }
    if (($last -as [int]) -and $tokens.Count -ge 2) {
        $tokens = $tokens[0..($tokens.Count - 2)]
    }

    $patternBetween = if ($withinAmount -eq 0) { '.*?' } else { ".{0,$withinAmount}?" }

    if ($tokens.Count -gt 2 -and $tokens[-1] -eq '*n') {
        if ($tokens.Count -ge 2) { $tokens = $tokens[0..($tokens.Count - 2)] } else { $tokens = @() }
        $patternBetween = '.*?\n?.*?'
        $extraDash += '-U'
    }

    $pattern = if ($tokens.Count -gt 0) { $tokens -join $patternBetween } else { '' }

    return [PSCustomObject]@{ Terms = $tokens; PatternBetween = $patternBetween; ExtraDash = $extraDash; Pattern = $pattern }
}

function rgj
(
) {
    $obsPath = zoxide query obs

    # Modular parsing: split dash options and pure tokens
    $parsed = Get-SearchArgs -InputArgs $args
    $pureTokens = @($parsed.PureTokens)
    $dashArgs = @($parsed.DashArgs)

    # Build pattern info from pure tokens
    $build = Build-PatternFromPureTokens -PureTokens $pureTokens
    $terms = @($build.Terms)
    $patternBetween = $build.PatternBetween
    $extraDash = @($build.ExtraDash)

    $dashArgsCombined = @($dashArgs + $extraDash)
    $pattern = $build.Pattern

    & rg -g '*Journal.md' -M 400 -A3 @dashArgsCombined -- $pattern $obsPath

    if ($? -eq $false) {
        Write-Host "not in those journal.md, trying rotate mode..." -ForegroundColor Magenta
        # Rotate mode: permute terms and retry
        if ($terms.Count -ge 2) {
            # Determine how many initial terms to permute (2, 3, or 4) based on terms
            $permuteCount = if ($terms.Count -ge 4) { 4 } elseif ($terms.Count -eq 3) { 3 } else { 2 }
            # Keep tail (terms beyond permuteCount)
            $tail = if ($terms.Count -gt $permuteCount) { $terms[$permuteCount..($terms.Count - 1)] } else { @() }

            # Hardcoded permutations per permuteCount
            switch ($permuteCount) {
                2 { $permutations = @( @(1, 0) , @()) }
                3 {
                    $permutations = @(
                        @(0, 2, 1), @(1, 0, 2), @(1, 2, 0), @(2, 0, 1), @(2, 1, 0)
                    ) 
                }
                4 {
                    $permutations = @(
                        @(0, 1, 3, 2), @(0, 2, 1, 3), @(0, 2, 3, 1), @(0, 3, 1, 2), @(0, 3, 2, 1),
                        @(1, 0, 2, 3), @(1, 0, 3, 2), @(1, 2, 0, 3), @(1, 2, 3, 0), @(1, 3, 0, 2), @(1, 3, 2, 0),
                        @(2, 0, 1, 3), @(2, 0, 3, 1), @(2, 1, 0, 3), @(2, 1, 3, 0), @(2, 3, 0, 1), @(2, 3, 1, 0),
                        @(3, 0, 1, 2), @(3, 0, 2, 1), @(3, 1, 0, 2), @(3, 1, 2, 0), @(3, 2, 0, 1), @(3, 2, 1, 0)
                    ) 
                }
            }

            $found = $false
            foreach ($p in $permutations) {
                # HACK: this is the fault of typesystem to demote the type of array[] to array.
                if ($p.Count -eq 0) { continue } 
                $newTerms = @()
                foreach ($idx in $p) { $newTerms += $terms[$idx] }
                $newTerms += $tail

                $testPattern = if ($newTerms.Count -gt 0) { $newTerms -join $patternBetween } else { '' }
                & rg -g '*Journal.md' -M 400 -A3 @dashArgsCombined -- $testPattern $obsPath
                if ($?) {
                    $found = $true
                    $order = ($newTerms | Where-Object { $_ -is [string] -and $_ -notmatch '^-' }) -join ' '
                    Write-Host "Found in journal.md (rotated: $order)" -ForegroundColor Green
                    break
                }
            }

            if (-not $found) {
                if ($terms.Count -gt $permuteCount) {
                    Write-Host "Still not found. Only the first $permuteCount terms were permuted — try shortening your query." -ForegroundColor Yellow
                }
                else {
                    Write-Host "Still not found in journal.md, try upping the within amount to * or more than 30?" -ForegroundColor Yellow
                }
            }
        }
        else {
            Write-Host "Not enough terms to rotate. Fall back to other search engine." -ForegroundColor Red
        }
    }
}

# HACK: rg in vault's other files.
function rgo() { 
    $obsPath = zoxide query obs
    $parsed = Get-SearchArgs -InputArgs $args
    $pureTokens = @($parsed.PureTokens)
    $dashArgs = @($parsed.DashArgs)
    $build = Build-PatternFromPureTokens -PureTokens $pureTokens
    $pattern = $build.Pattern
    $dashArgs += $build.ExtraDash
    & rg -g !'*Journal.md' -M 400 -C0 @dashArgs -- $pattern $obsPath
}

# HACK: rg in vault's other files.
function igo() { 
    $obsPath = zoxide query obs
    $parsed = Get-SearchArgs -InputArgs $args
    $pureTokens = @($parsed.PureTokens)
    $dashArgs = @($parsed.DashArgs)
    $build = Build-PatternFromPureTokens -PureTokens $pureTokens
    $pattern = $build.Pattern
    $dashArgs += $build.ExtraDash
    & ig -g !'*Journal.md' --context-viewer=horizontal @dashArgs -- $pattern $obsPath
}

function igj() {
    $obsPath = zoxide query obs
    $parsed = Get-SearchArgs -InputArgs $args
    $pureTokens = @($parsed.PureTokens)
    $dashArgs = @($parsed.DashArgs)
    $build = Build-PatternFromPureTokens -PureTokens $pureTokens
    $pattern = $build.Pattern
    $dashArgs += $build.ExtraDash
    & ig -g '*Journal.md' --context-viewer=horizontal @dashArgs -- $pattern $obsPath
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
    wsl $args --cd /home/golk
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
        $str = $str -replace '^"|"$', '' -replace "^'|'$", ''
        
        if (Test-Path -LiteralPath $str) { return @{ Path = $str; Line = $null; Col = $null } }
        # Handle path:line or path:line:col
        if ($str -match "^(.+):(\d+)(?::(\d+))?$") {
            $p = $matches[1]
            if (Test-Path -LiteralPath $p) {
                return @{ Path = $p; Line = $matches[2]; Col = $matches[3] }
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
function rrr {
    just rr ($args.Length ? "$($args -join ' ')" : $null)
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

function rei {
    just ei ($args.Length ? "$($args -join ' ')" : $null)
}

Set-Alias -Name r -Value just -Scope Global -Option AllScope

# INFO: more alias.
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
    $processedArgs = foreach ($arg in $args) {
        if ($arg -ceq '-p') {
            '--color=always'
        }
        else {
            $arg
        }
    }

    eza --hyperlink --icons=always $processedArgs 
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


# INFO: mpv related

Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class Win32DragDrop {
    public const uint WM_DROPFILES = 0x0233;
    public const uint GMEM_MOVEABLE = 0x0002;
    public const uint GMEM_ZEROINIT = 0x0040;

    [DllImport("user32.dll")]
    public static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);

    [DllImport("kernel32.dll")]
    public static extern IntPtr GlobalAlloc(uint uFlags, UIntPtr dwBytes);

    [DllImport("kernel32.dll")]
    public static extern IntPtr GlobalLock(IntPtr hMem);

    [DllImport("kernel32.dll")]
    public static extern bool GlobalUnlock(IntPtr hMem);
    
    [StructLayout(LayoutKind.Sequential)]
    public struct POINT {
        public int X;
        public int Y;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DROPFILES {
        public int pFiles;
        public POINT pt;
        public bool fNC;
        public bool fWide;
    }

    public static void DropFile(IntPtr hWnd, string filePath) {
        if (hWnd == IntPtr.Zero) return;

        byte[] bytes = Encoding.Unicode.GetBytes(filePath);
        // structure size + string length + double null
        int dataSize = 20 + bytes.Length + 2; 
        
        IntPtr hGlobal = GlobalAlloc(GMEM_MOVEABLE | GMEM_ZEROINIT, (UIntPtr)dataSize);
        if (hGlobal == IntPtr.Zero) return;

        IntPtr pData = GlobalLock(hGlobal);
        try {
            DROPFILES df = new DROPFILES();
            df.pFiles = 20; // Offset where files list starts
            df.fWide = true; // Unicode
            
            Marshal.StructureToPtr(df, pData, false);
            // safe pointer arithmetic for older .NET
            IntPtr strDest = new IntPtr(pData.ToInt64() + 20);
            Marshal.Copy(bytes, 0, strDest, bytes.Length);
        }
        finally {
            GlobalUnlock(hGlobal);
        }

        PostMessage(hWnd, WM_DROPFILES, hGlobal, IntPtr.Zero);
    }
}
"@

function Send-MpvCommand {
    param([string]$Command)
    
    # Find MPV
    $mpvProc = Get-Process -Name mpv -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
    if (-not $mpvProc) {
        Write-Warning "MPV is not running."
        return
    }

    # Focus MPV
    [QuickWin32]::SetForegroundWindow($mpvProc.MainWindowHandle)
    Start-Sleep -Milliseconds 200

    # Open console
    [System.Windows.Forms.SendKeys]::SendWait("``") 
    Start-Sleep -Milliseconds 100
    
    # Type command
    [System.Windows.Forms.SendKeys]::SendWait($Command)
    Start-Sleep -Milliseconds 100
    
    # Execute
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}{ESC}")
}

function Add-LyricFile {
    param([string]$Pattern, $delay)
    
    $audioDirQuery = "3-audio"
    
    # Resolve directory
    try {
        $baseDir = (zoxide query $audioDirQuery)
    }
    catch {
        Write-Warning "Could not resolve '$audioDirQuery' with zoxide."
        return
    }

    if (-not $baseDir -or -not (Test-Path $baseDir)) {
        Write-Warning "Directory not found for query '$audioDirQuery'."
        return
    }
    
    # Try to find the file
    $files = Get-ChildItem -Path $baseDir -Recurse -File -Filter "*$Pattern*" | Where-Object { $_.Extension -eq ".lrc" -and $_.Name -notmatch "orig\.lrc$" }
    
    $targetFile = $files | Select-Object -First 1
    
    if (-not $targetFile) {
        Write-Warning "No matching lyric file found."
        return
    }
    
    $filePath = $targetFile.FullName
    Write-Host "Dropping: $filePath" -ForegroundColor Cyan
    
    $normalizedPath = $filePath.Replace('\', '/')
    $command = "sub-add `"$normalizedPath`""

    Send-MpvCommand -Command $command

    if ($delay -ne $null) {
        $command = "set sub-delay $delay/1000"
        Send-MpvCommand -Command $Command
    }
        

}

function Add-NextTrack {
    param([string]$Pattern)
    
    $audioDirQuery = "3-audio"
    
    # Resolve directory
    try {
        $baseDir = (zoxide query $audioDirQuery)
    }
    catch {
        Write-Warning "Could not resolve '$audioDirQuery' with zoxide."
        return
    }

    if (-not $baseDir -or -not (Test-Path $baseDir)) {
        Write-Warning "Directory not found for query '$audioDirQuery'."
        return
    }
    
    # Try to find the file
    $targetFile = Get-ChildItem -Path $baseDir -Recurse -File -Filter "*$Pattern*" | Where-Object { $_.Extension -match "\.(mkv|webm)$" } | Select-Object -First 1
    
    if (-not $targetFile) {
        Write-Warning "No matching audio file found."
        return
    }
    
    $filePath = $targetFile.FullName
    Write-Host "Queueing next: $filePath" -ForegroundColor Cyan
    
    $normalizedPath = $filePath.Replace('\', '/')
    $command = "loadfile `"$normalizedPath`" insert-next"

    Send-MpvCommand -Command $command
}

Set-Alias -Name Add-Track -Value Add-NextTrack

# HACK: a wrapper for bat
function b {
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [object]$InputObject,
        [Parameter(ValueFromRemainingArguments = $true)]
        [object[]]$RemainingArgs
    )

    begin {
        $buffer = [System.Collections.Generic.List[object]]::new()
    }

    process {
        if ($null -ne $InputObject) { $buffer.Add($InputObject) }
    }

    end {
        if ($buffer.Count -gt 0) {
            $buffer.ToArray() | bat @RemainingArgs
            return
        }

        if ($RemainingArgs | Where-Object { $_ -is [string] -and $_ -match '\.xlsx$' } | Select-Object -First 1) {
            Write-Host "Warning: abnormal file type (xlsx), using xleak instead" -ForegroundColor Yellow
            xleak @RemainingArgs
            return
        }

        bat @RemainingArgs
    }
}
