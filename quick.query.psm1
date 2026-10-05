# Key-combo vocabulary and translators shared by Kanata, PSReadLine, VS Code,
# and other keybinding tools.

$script:KeyComboDictionary = [ordered]@{
    Modifiers = [ordered]@{
        ctrl   = @('C', 'Ctrl', 'Control', 'Ctl', 'lctl', 'lctrl', 'LeftCtrl', 'LCtrl')
        rctrl  = @('RC', 'RCtrl', 'rctl', 'rctrl', 'RightCtrl')
        meta   = @('M', 'Meta', 'lmet', 'lmeta', 'LeftMeta', 'Win', 'Windows', 'Super', 'GUI', 'Command', 'Cmd')
        rmeta  = @('RM', 'RMeta', 'rmet', 'rmeta', 'RightMeta')
        alt    = @('A', 'Alt', 'Option', 'lalt', 'LeftAlt')
        ralt   = @('RA', 'RAlt', 'ralt', 'AltGr', 'AG', 'RightAlt')
        shift  = @('S', 'Shift', 'lsft', 'lshift', 'LeftShift')
        rshift = @('RS', 'RShift', 'rsft', 'rshift', 'RightShift')
    }
    Keys = [ordered]@{
        esc    = @('Esc', 'Escape')
        ret    = @('Enter', 'Return', 'Ret', 'Ent')
        tab    = @('Tab')
        bspc   = @('Backspace', 'Back', 'BS', 'Bspc')
        del    = @('Delete', 'Del')
        ins    = @('Insert', 'Ins')
        spc    = @('Space', 'Spacebar', 'SPC')
        pgup   = @('PageUp', 'PgUp', 'Prior')
        pgdn   = @('PageDown', 'PgDn', 'Next')
        left   = @('Left', 'LeftArrow', 'ArrowLeft', 'Lft')
        right  = @('Right', 'RightArrow', 'ArrowRight', 'Rght')
        up     = @('Up', 'UpArrow', 'ArrowUp')
        down   = @('Down', 'DownArrow', 'ArrowDown')
        home   = @('Home')
        end    = @('End')
        kprt   = @('PrintScreen', 'PrtSc', 'PrtScn', 'Snapshot', 'KPrt')
        pause  = @('Pause', 'Break', 'Brk')
        caps   = @('CapsLock', 'Caps')
        nlck   = @('NumLock', 'Num')
        scrlck = @('ScrollLock', 'Scroll')
        grv    = @('Grv', 'Backquote', 'Oem3')
        min    = @('Minus', 'OemMinus')
        eql    = @('Equal', 'OemPlus')
        lbrc   = @('BracketLeft', 'LeftBracket', 'Oem4')
        rbrc   = @('BracketRight', 'RightBracket', 'Oem6')
        bksl   = @('Backslash', 'Oem5')
        scln   = @('Semicolon', 'Oem1')
        apo    = @('Quote', 'Apostrophe', 'Oem7')
        comm   = @('Comma', 'OemComma')
        dot    = @('Period', 'Dot', 'OemPeriod')
        slash  = @('Slash', 'Oem2')
    }
}

foreach ($number in 1..24) {
    $name = "f$number"
    $script:KeyComboDictionary.Keys[$name] = @("F$number", $name)
}
foreach ($number in 0..9) {
    $name = "kp$number"
    $script:KeyComboDictionary.Keys[$name] = @("NumPad$number", $name)
}
foreach ($key in @('kp/', 'kp*', 'kp-', 'kp+', 'kp.')) {
    $script:KeyComboDictionary.Keys[$key] = @($key)
}

$script:KeyComboModifierOrder = @('ctrl', 'rctrl', 'meta', 'rmeta', 'alt', 'ralt', 'shift', 'rshift')

function Get-KeyComboAliasMaps {
    $modifiers = @{}
    foreach ($canonical in $script:KeyComboDictionary.Modifiers.Keys) {
        foreach ($alias in $script:KeyComboDictionary.Modifiers[$canonical]) {
            $modifiers[$alias.ToLowerInvariant()] = $canonical
        }
    }
    $keys = @{}
    foreach ($canonical in $script:KeyComboDictionary.Keys.Keys) {
        foreach ($alias in $script:KeyComboDictionary.Keys[$canonical]) {
            $keys[$alias.ToLowerInvariant()] = $canonical
        }
    }
    [PSCustomObject]@{ Modifiers = $modifiers; Keys = $keys }
}

function Get-KeyComboDictionary {
    [CmdletBinding()]
    param(
        [ValidateSet('All', 'Modifiers', 'Keys')]
        [string]$Category = 'All',
        [switch]$Raw
    )

    $categories = if ($Category -eq 'All') { @('Modifiers', 'Keys') } else { @($Category) }
    if ($Raw) {
        $raw = [ordered]@{}
        foreach ($name in $categories) { $raw[$name] = $script:KeyComboDictionary[$name] }
        return ,$raw
    }
    foreach ($name in $categories) {
        foreach ($canonical in $script:KeyComboDictionary[$name].Keys) {
            foreach ($alias in $script:KeyComboDictionary[$name][$canonical]) {
                [PSCustomObject]@{ Category = $name; Canonical = $canonical; Alias = $alias }
            }
        }
    }
}

function Resolve-KeyComboCanonical {
    param([Parameter(Mandatory)][string]$Value)

    $maps = Get-KeyComboAliasMaps
    $prefixNames = @($maps.Modifiers.Keys | Sort-Object Length -Descending | ForEach-Object { [regex]::Escape($_) }) -join '|'
    $sequence = $Value.Trim() -replace '\s*->\s*', ',' -replace '\s*>\s*', ','
    $segments = $sequence -split '\s*,\s*' | Where-Object { $_ -and $_.Trim() }
    $events = foreach ($segment in $segments) {
        $segment = $segment.Trim() -replace '^\[?\d+(?:\.\d+)?\s*(?:ms|s)\]?\s+', ''
        $segment = $segment -replace '\s*\+\s*', '+'
        $parts = @($segment -split '\s+' | Where-Object { $_ })
        $modifierPrefix = if ($parts.Count -gt 1) { @($parts[0..($parts.Count - 2)] | Where-Object { $maps.Modifiers.ContainsKey($_.ToLowerInvariant()) }).Count -eq ($parts.Count - 1) } else { $false }
        if ($modifierPrefix) { $parts -join '+' }
        elseif ($parts.Count -gt 1 -and @($parts | Where-Object { $_ -match '[-+]' }).Count -eq $parts.Count) { $parts }
        else { $segment }
    }

    $normalized = foreach ($event in $events) {
        $tokens = @($event -split '\+')
        if ($tokens.Count -gt 1 -and $tokens[-1] -eq '' -and $tokens[-2] -match '(?i)(?:^|-)kp$') {
            $tokens = @($tokens[0..($tokens.Count - 2)])
            $tokens[-1] = "$($tokens[-1])+"
        }
        $parts = [System.Collections.Generic.List[string]]::new()
        for ($i = 0; $i -lt $tokens.Count; $i++) {
            $token = $tokens[$i].Trim()
            if (-not $token) { continue }

            # Kanata's chained prefix form: C-M-A-S-kp1, including RC-/RM-/RA-/RS-.
            while ($true) {
                $prefix = [regex]::Match($token, "^(?<modifier>$prefixNames)-+(?<key>.+)$", 'IgnoreCase')
                if (-not $prefix.Success) { break }
                $prefixName = $maps.Modifiers[$prefix.Groups['modifier'].Value.ToLowerInvariant()]
                if (-not $prefixName) { break }
                $parts.Add($prefixName)
                $token = $prefix.Groups['key'].Value
            }

            $modifierName = $maps.Modifiers[$token.ToLowerInvariant()]
            if ($i -lt ($tokens.Count - 1) -and $modifierName) {
                $parts.Add($modifierName)
                continue
            }

            $keyName = $maps.Keys[$token.ToLowerInvariant()]
            if (-not $keyName -and $token -match '^(?:f\d{1,2}|kp(?:\d|[+*/.-]))$') {
                $keyName = $token.ToLowerInvariant()
            }
            if (-not $keyName -and $token -match '^oem\d+$') { $keyName = $token.ToLowerInvariant() }
            if (-not $keyName -and $token.Length -eq 1 -and $token -match '[A-Za-z]') { $keyName = $token.ToLowerInvariant() }
            if (-not $keyName) { $keyName = $token }
            $parts.Add($keyName)
        }

        $ordered = foreach ($modifier in $script:KeyComboModifierOrder) {
            $parts | Where-Object { $_ -eq $modifier } | Select-Object -First 1
        }
        $key = $parts | Where-Object { $script:KeyComboModifierOrder -notcontains $_ } | Select-Object -Last 1
        if ($key) { (@($ordered) + $key) -join '+' } else { $ordered -join '+' }
    }
    $normalized -join ', '
}

function ConvertFrom-KeyComboCanonical {
    param(
        [Parameter(Mandatory)][string]$Canonical,
        [ValidateSet('Canonical', 'Plus', 'Search', 'Kanata', 'PSReadLine', 'VSCode', 'Vim', 'Emacs', 'Helix', 'Nushell')]
        [string]$Style
    )

    $modifierNames = @{
        Kanata    = @{ ctrl = 'C'; rctrl = 'RC'; meta = 'M'; rmeta = 'RM'; alt = 'A'; ralt = 'RA'; shift = 'S'; rshift = 'RS' }
        PSReadLine = @{ ctrl = 'Ctrl'; rctrl = 'Ctrl'; meta = 'Win'; rmeta = 'Win'; alt = 'Alt'; ralt = 'Alt'; shift = 'Shift'; rshift = 'Shift' }
        VSCode    = @{ ctrl = 'ctrl'; rctrl = 'ctrl'; meta = 'meta'; rmeta = 'meta'; alt = 'alt'; ralt = 'alt'; shift = 'shift'; rshift = 'shift' }
        Vim       = @{ ctrl = 'C'; rctrl = 'C'; meta = 'M'; rmeta = 'M'; alt = 'A'; ralt = 'A'; shift = 'S'; rshift = 'S' }
        Emacs     = @{ ctrl = 'C'; rctrl = 'C'; meta = 'M'; rmeta = 'M'; alt = 'A'; ralt = 'A'; shift = 'S'; rshift = 'S' }
        Helix     = @{ ctrl = 'C'; rctrl = 'C'; meta = 'M'; rmeta = 'M'; alt = 'A'; ralt = 'A'; shift = 'S'; rshift = 'S' }
    }
    $keyNames = @{
        PSReadLine = @{ esc = 'Escape'; ret = 'Enter'; bspc = 'Backspace'; spc = 'Spacebar'; pgup = 'PageUp'; pgdn = 'PageDown'; left = 'LeftArrow'; right = 'RightArrow'; up = 'UpArrow'; down = 'DownArrow'; kp0 = 'NumPad0'; kp1 = 'NumPad1'; kp2 = 'NumPad2'; kp3 = 'NumPad3'; kp4 = 'NumPad4'; kp5 = 'NumPad5'; kp6 = 'NumPad6'; kp7 = 'NumPad7'; kp8 = 'NumPad8'; kp9 = 'NumPad9' }
        VSCode = @{ esc = 'escape'; ret = 'enter'; bspc = 'backspace'; spc = 'space'; pgup = 'pageup'; pgdn = 'pagedown'; left = 'left'; right = 'right'; up = 'up'; down = 'down'; kp0 = 'num0'; kp1 = 'num1'; kp2 = 'num2'; kp3 = 'num3'; kp4 = 'num4'; kp5 = 'num5'; kp6 = 'num6'; kp7 = 'num7'; kp8 = 'num8'; kp9 = 'num9'; 'kp+' = 'numadd'; 'kp-' = 'numsub'; 'kp*' = 'multiply'; 'kp/' = 'divide'; 'kp.' = 'decimal' }
        Vim     = @{ esc = '<Esc>'; ret = '<CR>'; tab = '<Tab>'; bspc = '<BS>'; del = '<Del>'; ins = '<Insert>'; spc = '<Space>'; pgup = '<PageUp>'; pgdn = '<PageDown>'; left = '<Left>'; right = '<Right>'; up = '<Up>'; down = '<Down>'; home = '<Home>'; end = '<End>' }
        Emacs   = @{ esc = 'ESC'; ret = 'RET'; tab = 'TAB'; bspc = 'DEL'; del = 'DELETE'; spc = 'SPC'; left = '<left>'; right = '<right>'; up = '<up>'; down = '<down>' }
        Helix   = @{ esc = 'esc'; ret = 'ret'; tab = 'tab'; bspc = 'backspace'; del = 'delete'; spc = 'space'; left = 'left'; right = 'right'; up = 'up'; down = 'down'; home = 'home'; end = 'end'; pgup = 'pageup'; pgdn = 'pagedown' }
        Nushell = @{ esc = 'esc'; ret = 'enter'; tab = 'tab'; bspc = 'backspace'; del = 'delete'; ins = 'insert'; spc = 'space'; left = 'left'; right = 'right'; up = 'up'; down = 'down'; home = 'home'; end = 'end'; pgup = 'pageup'; pgdn = 'pagedown' }
    }

    $rendered = foreach ($chord in ($Canonical -split '\s*,\s*')) {
        $remaining = $chord
        $modifiers = foreach ($modifier in $script:KeyComboModifierOrder) {
            $prefix = "$modifier+"
            if ($remaining.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                $remaining = $remaining.Substring($prefix.Length)
                $modifier
            }
        }
        $key = if ($Style -eq 'Canonical') {
            $remaining
        }
        elseif ($keyNames.ContainsKey($Style) -and $keyNames[$Style].ContainsKey($remaining)) {
            $keyNames[$Style][$remaining]
        }
        else {
            $remaining
        }
        if ($Style -eq 'Canonical') {
            $canonicalModifiers = @($modifiers | ForEach-Object { $modifierNames.PSReadLine[$_] })
            if ($key -match '^f\d+$') { $key = $key.ToUpperInvariant() }
            elseif ($keyNames.PSReadLine.ContainsKey($key)) { $key = $keyNames.PSReadLine[$key] }
            ($canonicalModifiers + $key) -join '+'
        }
        elseif ($Style -eq 'Plus') {
            (@($modifiers) + $key) -join '+'
        }
        elseif ($Style -eq 'Search') {
            ((@($modifiers) + $key) -join '+') -replace '\+', '\+'
        }
        elseif ($Style -eq 'Kanata') {
            (@($modifiers | ForEach-Object { "$($modifierNames.Kanata[$_])-" }) -join '') + $key
        }
        elseif ($Style -eq 'Vim') {
            $vimKey = $key -replace '^<|>$', ''
            if ($modifiers.Count -eq 0 -and $vimKey -match '^[a-z0-9]$') { $vimKey } else { "<$((@($modifiers | ForEach-Object { $modifierNames.Vim[$_] }) -join '-') + $(if ($modifiers.Count) { '-' } else { '' }) + $vimKey)>" }
        }
        elseif ($Style -eq 'Emacs') {
            if ($modifiers.Count) { (@($modifiers | ForEach-Object { "$($modifierNames.Emacs[$_])-" }) -join '') + $key } else { $key }
        }
        elseif ($Style -eq 'Helix') {
            if ($modifiers.Count) { (@($modifiers | ForEach-Object { "$($modifierNames.Helix[$_])-" }) -join '') + $key } else { $key }
        }
        elseif ($Style -eq 'Nushell') {
            $nushellModifiers = @($modifiers | ForEach-Object {
                switch -Regex ($_) {
                    '^r?ctrl$' { 'control'; break }
                    '^r?meta$' { 'meta'; break }
                    '^r?alt$' { 'alt'; break }
                    '^r?shift$' { 'shift'; break }
                }
            } | Select-Object -Unique)
            $modifierText = if ($nushellModifiers.Count) { $nushellModifiers -join '_' } else { 'none' }
            if ($key -match '^[a-z0-9]$') { $nuKey = "char_$key" }
            elseif ($key -match '^f\d+$') { $nuKey = $key }
            elseif ($keyNames.Nushell.ContainsKey($key)) { $nuKey = $keyNames.Nushell[$key] }
            else { $nuKey = $key }
            "modifier: $modifierText, keycode: $nuKey"
        }
        else {
            (@($modifiers | ForEach-Object { $modifierNames[$Style][$_] }) + $key) -join '+'
        }
    }
    if ($Style -in @('Plus', 'Search', 'Kanata', 'Vim', 'Emacs', 'Helix', 'Canonical')) { $rendered -join ' ' } else { $rendered -join ', ' }
}

function ConvertTo-KeyComboText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [object]$InputObject,
        [ValidateSet('Canonical', 'Plus', 'Search', 'Kanata', 'PSReadLine', 'VSCode', 'Vim', 'Emacs', 'Helix', 'Nushell', 'All')]
        [string]$Style = 'Canonical',
        [Alias('ForPipe')]
        [switch]$Pipe,
        [Alias('AllStyles', 'V')]
        [switch]$Table
    )

    process {
        if ($Pipe) { $Style = 'Plus' }
        elseif ($Table) { $Style = 'All' }
        if ($InputObject -is [System.ConsoleKeyInfo] -or
            ($InputObject.PSObject.Properties['Key'] -and $InputObject.PSObject.Properties['Modifiers'])) {
            $key = $InputObject.Key.ToString()
            $modifiers = [System.ConsoleModifiers]$InputObject.Modifiers
            $prefix = @()
            if ($modifiers -band [System.ConsoleModifiers]::Control) { $prefix += 'ctrl' }
            if ($modifiers -band [System.ConsoleModifiers]::Alt) { $prefix += 'alt' }
            if ($modifiers -band [System.ConsoleModifiers]::Shift) { $prefix += 'shift' }
            if ($key -match '^D([0-9])$') { $key = $Matches[1] }
            elseif ($key -match '^NumPad([0-9])$') { $key = "kp$($Matches[1])" }
            elseif ($key -match '^Oem(\d+)$') { $key = "oem$($Matches[1])" }
            elseif ($key.Length -eq 1 -and $key -match '[A-Za-z]') { $key = $key.ToLowerInvariant() }
            $canonical = ((@($prefix) + $key) -join '+')
        }
        else {
            $canonical = Resolve-KeyComboCanonical ([string]$InputObject)
        }

        if ($Style -eq 'All') {
            $result = [PSCustomObject]@{
                Canonical  = ConvertFrom-KeyComboCanonical $canonical -Style Canonical
                Plus       = ConvertFrom-KeyComboCanonical $canonical -Style Plus
                Search     = ConvertFrom-KeyComboCanonical $canonical -Style Search
                Kanata     = ConvertFrom-KeyComboCanonical $canonical -Style Kanata
                PSReadLine = ConvertFrom-KeyComboCanonical $canonical -Style PSReadLine
                VSCode     = ConvertFrom-KeyComboCanonical $canonical -Style VSCode
                Vim        = ConvertFrom-KeyComboCanonical $canonical -Style Vim
                Emacs      = ConvertFrom-KeyComboCanonical $canonical -Style Emacs
                Helix      = ConvertFrom-KeyComboCanonical $canonical -Style Helix
                Nushell    = ConvertFrom-KeyComboCanonical $canonical -Style Nushell
            }
            $result.PSTypeNames.Insert(0, 'PowerShellConfig.KeyComboTranslation')
            $result
        }
        else {
            ConvertFrom-KeyComboCanonical $canonical -Style $Style
        }
    }
}

Update-TypeData -TypeName 'PowerShellConfig.KeyComboTranslation' `
    -DefaultDisplayPropertySet Canonical, Plus, Search, Kanata, PSReadLine, VSCode, Vim, Emacs, Helix, Nushell -Force

function Find-PSReadLineKeyBinding {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)][string]$Pattern,
        [System.ConsoleKeyInfo]$Key,
        [switch]$Exact
    )
    $query = if ($PSBoundParameters.ContainsKey('Key')) { ConvertTo-KeyComboText $Key } elseif ($PSBoundParameters.ContainsKey('Pattern')) { ConvertTo-KeyComboText $Pattern } else { '' }
    $queryParts = $query -split '\s*,\s*' | ForEach-Object ToLowerInvariant
    foreach ($handler in @(Get-PSReadLineKeyHandler)) {
        $handlerKey = ConvertTo-KeyComboText ([string]$handler.Key)
        $handlerParts = $handlerKey -split '\s*,\s*' | ForEach-Object ToLowerInvariant
        $match = if (-not $query) { $true } elseif ($Exact) { (@($handlerParts) -join ',') -eq (@($queryParts) -join ',') } else { ($handlerParts -join ',') -like "*$($queryParts -join ',')*" }
        if ($match) { $handler }
    }
}

function Search-KeyComboNotes {
    <#
    .SYNOPSIS
        Search journal notes for a key combo using the rgj note searcher.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [object]$Combo
    )

    $query = ConvertTo-KeyComboText $Combo -Style Search
    $rgj = Get-Command rgj -CommandType Function,Alias,Application -ErrorAction SilentlyContinue
    if (-not $rgj) {
        throw "The rgj note-search command is not available. Import CLI-Basic first."
    }
    & $rgj.Name $query
}

Set-Alias -Name cq -Value ConvertTo-KeyComboText
Set-Alias -Name kqn -Value Search-KeyComboNotes
Export-ModuleMember -Function ConvertTo-KeyComboText, ConvertFrom-KeyComboCanonical, Find-PSReadLineKeyBinding, Get-KeyComboDictionary, Search-KeyComboNotes -Alias cq, kqn
