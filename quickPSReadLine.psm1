using namespace System.Console
using namespace System.Management.Automation
using namespace System.Management.Automation.Language
# $RLModule = [Microsoft.PowerShell.PSConsoleReadLine]

function Invoke-PSReadLineWrapToken {
    param(
        [Parameter(Mandatory)]
        [string]$Open,
        [Parameter(Mandatory)]
        [string]$Close
    )

    $selectionStart = $null
    $selectionLength = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    if ($selectionStart -ne -1) {
        $selectedText = $line.Substring($selectionStart, $selectionLength)
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, "$Open$selectedText$Close")
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + $Open.Length + $Close.Length)
        return
    }

    $ast = $null
    $tokens = $null
    $errors = $null
    $parsedCursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$parsedCursor)
    if ($null -ne $ast.Extent) {
        $line = $ast.Extent.Text
    }

    $nearestToken = $tokens | Where-Object {
        $_.Extent.StartOffset -lt $_.Extent.EndOffset -and
        $_.Extent.StartOffset -le $parsedCursor -and
        $_.Extent.EndOffset -ge $parsedCursor
    } | Select-Object -First 1

    if (-not $nearestToken) {
        $nearestToken = $tokens | Where-Object {
            $_.Extent.StartOffset -lt $_.Extent.EndOffset
        } | Sort-Object {
            [Math]::Abs($_.Extent.StartOffset - $parsedCursor)
        } | Select-Object -First 1
    }

    if ($nearestToken -and
        $nearestToken.Extent.StartOffset -ge 0 -and
        $nearestToken.Extent.EndOffset -le $line.Length) {
        $start = $nearestToken.Extent.StartOffset
        $length = $nearestToken.Extent.EndOffset - $start
        $text = $nearestToken.Extent.Text
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace($start, $length, "$Open$text$Close")
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($start + $length + $Open.Length + $Close.Length)
        return
    }

    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$Open$Close")
    [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + $Open.Length)
}

$ggSearchParameters = @{
    Key              = 'Ctrl+shift+alt+w' # limbo
    BriefDescription = 'Web Search Mode'
    LongDescription  = 'Maybe other search function, but who knows.'
    ScriptBlock      = {
        param($key, $arg)
        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        
        # HACK: have to perform one silent check to route those.
        $searchFunction = "Search-DuckDuckGo" 
        # rg -q "$($line -join ' ')" $HOME/hw/obs && Set-Variable -Name searchFunction -Value "rgj"
       
        $process_string = {
            param($line)
            $SearchWithQuery = ""
            # HACK: strip off any related search function.
            
            if ($line -match "[a-z]") {
                $SearchWithQuery = "$searchFunction $line"
            }
            else {
                $SearchWithQuery = "$searchFunction $(Get-History -Count 1)"
            }
            return $SearchWithQuery
        }

        [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, $process_string.Invoke($line))
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
}

$VaultSearchParameters = @{
    Key              = 'Ctrl+s' # 'Ctrl+s,Ctrl+s'
    BriefDescription = 'Vault Search Mode'
    LongDescription  = 'Maybe other search function, but who knows.'
    ScriptBlock      = {
        param($key, $arg)
        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line,
            [ref]$cursor)
        $searchFunction = "rgj" 
        $SearchWithQuery = ""

        # WARN: First time I used ScriptBlock 
        $process_string = {
            param($line)
            if ($line -match '^(?i)(?:ConvertTo-KeyComboText|cq)\s+(?<combo>.+)$') {
                $converter = $Matches[0] -replace '\s+$', ''
                if ($converter -notmatch '(?i)\s-Style\s') {
                    $converter += ' -Style Search'
                }
                return "$searchFunction `"`$($converter)`""
            }
            $matchesSearchFunction = "rgj|rgo|ig"
            if ($line -match "^($matchesSearchFunction)") {
                # TODO: further enhanced by adding different flag at this point.
                switch -Regex ($line) {
                    "^(?!.*-w$)" { $SearchWithQuery = "$line -w"; break }
                    "^rgj" { $SearchWithQuery = $line -replace "^rgj", "rgo"; break }
                    "^rgo" { $SearchWithQuery = $line -replace "-w$", ""; break }
                    "^igj" { $SearchWithQuery = $line -replace "^igj", "ig"; break }
                }
            }
            else {
                # TODO: more term to replace with search.
                if ($line -match "scoop\s\w+\b") { 
                    $SearchWithQuery = $line -replace $Matches.Values[0], "rgj" 
                }
                else {
                    $SearchWithQuery = "$searchFunction $line"
                }
            } 
            return $SearchWithQuery
        }
        if ($line -match "[a-z]") {
            $SearchWithQuery = $process_string.Invoke($line)
        }
        else {
            $lineContent = $(Get-History -Count 1)
            $SearchWithQuery = $process_string.Invoke($lineContent)
        }       
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, "$SearchWithQuery")
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
}

$quickZoxide = {
    param($key, $arg)
    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line,
        [ref]$cursor)
    $searchFunction = "zi"
    $SearchWithQuery = ""

    $process_string = {
        param($line)
        $jumpTable = @{
            'cd'   = 'cdb'
            'cdb'  = 'cdi'
            'cdi'  = 'cdbi'
            'cdbi' = 'cd'
            'z'    = 'zb'
            'zb'   = 'zi'
            'zi'   = 'zbi'
            'zbi'  = 'z'
            'zq'   = 'zqb'
            'zqb'  = 'zqi'
            'zqi'  = 'zqbi'
            'zqbi' = 'zq'
        }
        $existedCd = ($jumpTable.Keys | Sort-Object Length -Descending) -join '|'

        switch -Regex ($line) {
            "^(${existedCd})(\s|$)" {
                $matchString = $Matches[1]
                $SearchWithQuery = $line -replace "^${matchString}(?=\s|$)", $jumpTable[$matchString]
                break
            }
            default {
                $SearchWithQuery = "$searchFunction $line"
                break;
            }
        }
        return $SearchWithQuery
    }
    if ($line -match "[a-z]") {
        $SearchWithQuery = $process_string.Invoke($line)
    }
    else {
        $lineContent = $(Get-History -Count 1)
        $SearchWithQuery = $process_string.Invoke($lineContent)
    }       
    [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, "$SearchWithQuery")
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

$DoubleQuotesNestedBracketParameter = @{
    Key              = "ctrl+shift+Oem7"
    BriefDescription = 'quote and parentheses the selection or nearest token'
    LongDescription  = 'Wraps selected text in parentheses; if no selection, wraps the token nearest to the cursor. Cursor is placed after the closing parenthesis.'
    ScriptBlock      = {
        param($key, $arg)

        $selectionStart = $null
        $selectionLength = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        if ($selectionStart -ne -1) {
            $selectedText = $line.SubString($selectionStart, $selectionLength)
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, "`"`$`($selectedText`)`"")
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 4)
        }
        else {
            $ast = $null
            $tokens = $null
            $errors = $null
            $cursor = $null
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)
            $line = if ($ast.Extent) { $ast.Extent.Text } else { '' }
            $nearestToken = $tokens | Where-Object {
                $_.Extent.StartOffset -le $cursor -and $_.Extent.EndOffset -ge $cursor
            } | Select-Object -First 1

            if (-not $nearestToken) {
                # If no token is under the cursor, find the closest token
                $nearestToken = $tokens | Sort-Object {
                    [Math]::Abs($_.Extent.StartOffset - $cursor)
                } | Select-Object -First 1
            }

            if ($nearestToken -and 
                $nearestToken.Extent.StartOffset -ge 0 -and 
                $nearestToken.Extent.StartOffset -le $line.Length -and 
                $nearestToken.Extent.EndOffset -le $line.Length) {
                $start = $nearestToken.Extent.StartOffset
                $length = $nearestToken.Extent.EndOffset - $start
                $text = $nearestToken.Extent.Text
                [Microsoft.PowerShell.PSConsoleReadLine]::Replace($start, $length, "`"`$`($text`)`"")
                [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($start + $length + 4)
            }
            else {
                # Fallback: insert () at cursor
                [Microsoft.PowerShell.PSConsoleReadLine]::Insert('"$()"')
                [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 3)
            }
        }
    }
}


$QuickZoxideParameters = @{
    Key              = @('alt+z', 'ctrl+shift+z')
    BriefDescription = 'Quick zoxide Mode'
    LongDescription  = 'quick zoxide opened.'
    ScriptBlock      = $quickZoxide
}

# Setup for (!s)
$IterateCommandParameters = @{
    Key              = 'Alt+s'
    BriefDescription = 'iterate commands in the current line.'
    LongDescription  = 'want to be like alt a'
    ScriptBlock      = {
        param($key, $arg)   # The arguments are ignored in this example

        $ast = $null
        $tokens = $null
        $errors = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState(
            [ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor
        )
        # INFO: filtering with FindAll API.
        # HACK: dont understand the type and member syntaxes at all.read blog then?
        # [Abstract Syntax Tree - powershell.one](https://powershell.one/powershell-internals/parsing-and-tokenization/abstract-syntax-tree)

        $asts = $ast.FindAll( {
                $args[0] -is [System.Management.Automation.Language.ExpressionAst] `
                    -and $args[0].Parent -is [System.Management.Automation.Language.CommandAst]
                # -and $args[0].Parent -is [System.Management.Automation.Language.ExpressionAst]
                # -and $args[0].Extent.StartOffset -ne $args[0].Parent.Extent.StartOffset
            }, $true)

        if ($asts.Count -eq 0) {
            $lastCommand = (Get-History -Count 1).CommandLine
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $ast.Extent.Text.Length, $lastCommand)
            [Microsoft.PowerShell.PSConsoleReadLine]::Ding()
            return
        }

        $nextAst = $null

        if ($null -ne $arg) {
            $nextAst = $asts[$arg - 1]
        }
        else {
            foreach ($ast in $asts) {
                if ($ast.Extent.StartOffset -ge $cursor) {
                    $nextAst = $ast
                    break
                }
            }

            if ($null -eq $nextAst) {
                $nextAst = $asts[0]
            }
        }

        $startOffsetAdjustment = 0
        $endOffsetAdjustment = 0

        if ($nextAst -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
            $nextAst.StringConstantType -ne [System.Management.Automation.Language.StringConstantType]::BareWord) {
            $startOffsetAdjustment = 1
            $endOffsetAdjustment = 2
        }

        # INFO: jump to next symbols
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($nextAst.Extent.StartOffset + $startOffsetAdjustment)
        [Microsoft.PowerShell.PSConsoleReadLine]::SetMark($null, $null)
        [Microsoft.PowerShell.PSConsoleReadLine]::SelectForwardChar($null, ($nextAst.Extent.EndOffset - $nextAst.Extent.StartOffset) - $endOffsetAdjustment)
    }
}

$IterateCommandReverseParameters = @{
    Key              = 'Alt+a'
    BriefDescription = 'reverse iterate commands in the current line.'
    LongDescription  = 'Reverse order of Alt+s.'
    ScriptBlock      = {
        param($key, $arg)   # The arguments are ignored in this example

        $ast = $null
        $tokens = $null
        $errors = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState(
            [ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor
        )

        $asts = $ast.FindAll( {
                $args[0] -is [System.Management.Automation.Language.ExpressionAst] `
                    -and $args[0].Parent -is [System.Management.Automation.Language.CommandAst]
            }, $true)

        if ($asts.Count -eq 0) {
            $lastCommand = (Get-History -Count 1).CommandLine
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $ast.Extent.Text.Length, $lastCommand)
            [Microsoft.PowerShell.PSConsoleReadLine]::Ding()
            return
        }

        $nextAst = $null

        if ($null -ne $arg) {
            $nextAst = $asts[$asts.Count - $arg]
        }
        else {
            $selectionStart = $null
            $selectionLength = $null
            [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

            $cursorAnchor = $cursor
            if ($selectionStart -ne -1) {
                $cursorAnchor = $selectionStart
            }

            for ($i = $asts.Count - 1; $i -ge 0; $i--) {
                if ($asts[$i].Extent.StartOffset -lt $cursorAnchor) {
                    $nextAst = $asts[$i]
                    break
                }
            }

            if ($null -eq $nextAst) {
                $nextAst = $asts[$asts.Count - 1]
            }
        }

        $startOffsetAdjustment = 0
        $endOffsetAdjustment = 0

        if ($nextAst -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
            $nextAst.StringConstantType -ne [System.Management.Automation.Language.StringConstantType]::BareWord) {
            $startOffsetAdjustment = 1
            $endOffsetAdjustment = 2
        }

        # INFO: jump to previous symbols
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($nextAst.Extent.StartOffset + $startOffsetAdjustment)
        [Microsoft.PowerShell.PSConsoleReadLine]::SetMark($null, $null)
        [Microsoft.PowerShell.PSConsoleReadLine]::SelectForwardChar($null, ($nextAst.Extent.EndOffset - $nextAst.Extent.StartOffset) - $endOffsetAdjustment)
    }
}

$MoveSelectionToNextPhraseParameters = @{
    Key              = 'Alt+Shift+RightArrow'
    BriefDescription = 'move selection to the next phrase'
    LongDescription  = 'Swap the selected text with the next PowerShell command argument.'
    ScriptBlock      = {
        param($key, $arg)

        $selectionStart = $null
        $selectionLength = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)
        if ($selectionStart -lt 0 -or $selectionLength -le 0) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Ding()
            return
        }

        $line = $null
        $cursor = $null
        $ast = $null
        $tokens = $null
        $errors = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState(
            [ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor
        )

        $phrases = @(
            foreach ($commandAst in $ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.CommandAst]
                }, $true)) {
                @($commandAst.CommandElements | Select-Object -Skip 1) |
                    Where-Object { $_ -is [System.Management.Automation.Language.ExpressionAst] }
            }
        ) | Sort-Object { $_.Extent.StartOffset }
        if ($phrases.Count -lt 2) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Ding()
            return
        }

        $line = $ast.Extent.Text
        $selectedIndex = -1
        for ($i = 0; $i -lt $phrases.Count; $i++) {
            if ($selectionStart -ge $phrases[$i].Extent.StartOffset -and
                $selectionStart + $selectionLength -le $phrases[$i].Extent.EndOffset) {
                $selectedIndex = $i
                break
            }
        }
        if ($selectedIndex -lt 0) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Ding()
            return
        }

        $phraseTexts = @($phrases | ForEach-Object { $_.Extent.Text })
        $targetIndex = if ($selectedIndex -lt $phrases.Count - 1) { $selectedIndex + 1 } else { 0 }
        if ($selectedIndex -eq $phrases.Count - 1) {
            $newValues = @($phraseTexts[$selectedIndex]) + @($phraseTexts[0..($phrases.Count - 2)])
        }
        else {
            $newValues = @($phraseTexts)
            $newValues[$selectedIndex] = $phraseTexts[$targetIndex]
            $newValues[$targetIndex] = $phraseTexts[$selectedIndex]
        }

        $builder = [System.Text.StringBuilder]::new()
        $offset = 0
        $movedSelectionStart = $null
        for ($i = 0; $i -lt $phrases.Count; $i++) {
            $start = $phrases[$i].Extent.StartOffset
            $end = $phrases[$i].Extent.EndOffset
            [void]$builder.Append($line.Substring($offset, $start - $offset))
            if ($i -eq $targetIndex) { $movedSelectionStart = $builder.Length }
            [void]$builder.Append($newValues[$i])
            $offset = $end
        }
        [void]$builder.Append($line.Substring($offset))
        $newLine = $builder.ToString()
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, $newLine)
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($movedSelectionStart)
        [Microsoft.PowerShell.PSConsoleReadLine]::SetMark($null, $null)
        [Microsoft.PowerShell.PSConsoleReadLine]::SelectForwardChar($null, $phraseTexts[$selectedIndex].Length)
    }
}

$MoveSelectionToPreviousPhraseParameters = @{
    Key              = 'Alt+Shift+LeftArrow'
    BriefDescription = 'move selection to the previous phrase'
    LongDescription  = 'Swap the selected text with the previous PowerShell command argument.'
    ScriptBlock      = {
        param($key, $arg)

        $selectionStart = $null
        $selectionLength = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)
        if ($selectionStart -lt 0 -or $selectionLength -le 0) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Ding()
            return
        }

        $cursor = $null
        $ast = $null
        $tokens = $null
        $errors = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState(
            [ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor
        )

        $phrases = @(
            foreach ($commandAst in $ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.CommandAst]
                }, $true)) {
                @($commandAst.CommandElements | Select-Object -Skip 1) |
                    Where-Object { $_ -is [System.Management.Automation.Language.ExpressionAst] }
            }
        ) | Sort-Object { $_.Extent.StartOffset }
        if ($phrases.Count -lt 2) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Ding()
            return
        }

        $line = $ast.Extent.Text
        $selectedIndex = -1
        for ($i = 0; $i -lt $phrases.Count; $i++) {
            if ($selectionStart -ge $phrases[$i].Extent.StartOffset -and
                $selectionStart + $selectionLength -le $phrases[$i].Extent.EndOffset) {
                $selectedIndex = $i
                break
            }
        }
        if ($selectedIndex -lt 0) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Ding()
            return
        }

        $phraseTexts = @($phrases | ForEach-Object { $_.Extent.Text })
        $targetIndex = if ($selectedIndex -gt 0) { $selectedIndex - 1 } else { $phrases.Count - 1 }
        if ($selectedIndex -eq 0) {
            $newValues = @($phraseTexts[1..($phrases.Count - 1)]) + @($phraseTexts[$selectedIndex])
        }
        else {
            $newValues = @($phraseTexts)
            $newValues[$selectedIndex] = $phraseTexts[$targetIndex]
            $newValues[$targetIndex] = $phraseTexts[$selectedIndex]
        }

        $builder = [System.Text.StringBuilder]::new()
        $offset = 0
        $movedSelectionStart = $null
        for ($i = 0; $i -lt $phrases.Count; $i++) {
            $start = $phrases[$i].Extent.StartOffset
            $end = $phrases[$i].Extent.EndOffset
            [void]$builder.Append($line.Substring($offset, $start - $offset))
            if ($i -eq $targetIndex) { $movedSelectionStart = $builder.Length }
            [void]$builder.Append($newValues[$i])
            $offset = $end
        }
        [void]$builder.Append($line.Substring($offset))
        $newLine = $builder.ToString()
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, $newLine)
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($movedSelectionStart)
        [Microsoft.PowerShell.PSConsoleReadLine]::SetMark($null, $null)
        [Microsoft.PowerShell.PSConsoleReadLine]::SelectForwardChar($null, $phraseTexts[$selectedIndex].Length)
    }
}

# Setup for (^O)
$omniSearchParameters = @{
    Key              = 'Ctrl+o'
    BriefDescription = 'Obsidian Mode'
    LongDescription  = 'Search Obsidian.'
    ScriptBlock      = {
        param($key, $arg)   # The arguments are ignored in this example

        # GetBufferState gives us the command line (with the cursor position)
        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line,
            [ref]$cursor)
        $searchFunction = ":obsidian" # omniSearchObsidian
        if ($line -match "[a-z]") {
            $SearchWithQuery = "$searchFunction $line"
        }
        else {
            $SearchWithQuery = "$searchFunction $(Get-History -Count 1)"
        }
 
        #Store to history for future use.
        [Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory($line)
        [Microsoft.PowerShell.PSConsoleReadLine]::CancelLine()
        Invoke-Expression $SearchWithQuery
        # Can InvertLine() here to return empty line.
      
    }
}

# INFO: search character at current word.
# $CharacterSearchParameters = @{
#   Key = 'F4'
#   BriefDescription = 'Character Surfing'
#   LongDescription = 'Surfing char.'
#   ScriptBlock = {
#     param($key, $arg)   # The arguments are ignored in this example
#     #
#     #   $ast = $null
#     #   $tokens = $null
#     #   $errors = $null
#     #   $cursor = $null
#     #   [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)
#     $line = $null
#     $cursor = $null
#     [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line,
#       [ref]$cursor)
#     # New-Variable -Name consoleKey -type [System.ConsoleKeyInfo]
#     # $consoleKey = "a" -as [System.ConsoleKeyInfo]
#     # HACK: [ConsoleKeyInfo(Char, ConsoleKey, Boolean, Boolean, Boolean) Constructor (System) | Microsoft Learn](https://learn.microsoft.com/en-us/dotnet/api/system.consolekeyinfo.-ctor?view=net-8.0#system-consolekeyinfo-ctor(system-char-system-consolekey-system-boolean-system-boolean-system-boolean))
#     if($cursor -ge ($line.length - 2))
#     {
#       $cursor = 0
#       $conkey = [System.ConsoleKey]::Parse(($line[$cursor]).ToString())
#       $consoleKey = (New-Object -TypeName System.ConsoleKeyInfo -ArgumentList (
#           $line[$cursor], $conkey,$false,$false,$false))
#       [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor)
#       [Microsoft.PowerShell.PSConsoleReadLine]::CharacterSearch($consoleKey ,1)
#     } else
#     {
#
#       $conkey = [System.ConsoleKey]::Parse(($line[$cursor]).ToString())
#       $consoleKey = (New-Object -TypeName System.ConsoleKeyInfo -ArgumentList (
#           $line[$cursor], $conkey,$false,$false,$false))
#       [Microsoft.PowerShell.PSConsoleReadLine]::CharacterSearch($consoleKey,1)
#     }
#
#   }
# }


$JrnlParameters = @{
    Key              = 'Ctrl+j'
    BriefDescription = 'Jrnl edit back?'
    LongDescription  = 'draft.'
    ScriptBlock      = {
        param($key, $arg)   # The arguments are ignored in this example
        <#
    .SYNOPSIS
    
    .DESCRIPTION

    .PARAMETERS

    .EXAMPLES


    #>
        # GetBufferState gives us the command line (with the cursor position)
        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line,
            [ref]$cursor)
        $defaultValue = 2
        $line = $line.Trim()
        $editPattern = '\d+e$'
        if ($line -match "^j\s*$") {
            # INFO: most recent jrnl 
            $defaultValue = 8
            $SearchWithQuery = Get-Content -Tail 40 (Get-PSReadLineOption).HistorySavePath `
            | Where-Object { $_ -match '^j\s+(?:\w|\:)' }
            $SearchWithQuery = $SearchWithQuery[-1] -replace $editPattern, ''
      
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, "$SearchWithQuery $($defaultValue)e")
        }
        elseif ($line -match "^j\s*") {
            if ($line -match $editPattern) {
                # INFO: if there are 
                $defaultValue = 8
                $startPosition = $line `
                | Select-String -Pattern  $editPattern `
                | ForEach-Object { $_.Matches }
                if ($startPosition.Index -ne 0) {
                    [Microsoft.PowerShell.PSConsoleReadLine]::Replace($startPosition.Index, $startPosition.Count, "6e")
                }
                else {
                    [Microsoft.PowerShell.PSConsoleReadLine]::Insert(" $($defaultValue)e ")
                }
            }
            else {
                [Microsoft.PowerShell.PSConsoleReadLine]::Insert(" $($defaultValue)e")
            }
        }
        
        else {

            $finalOptions = $null
            $checkHistory = (Get-History `
                | Sort-Object -Property CommandLine -Unique `
                | Select-Object -ExpandProperty CommandLine `
                | Select-String -Pattern '^j +' )
            if (($checkHistory).Length -lt 2) {
                $historySource = (Get-Content -Tail 200 (Get-PSReadLineOption).HistorySavePath `
                    | Select-String -Pattern '^j +' )
            }
            else {
                $historySource = $checkHistory
            }
      
            $historySource `
            | fzf --query '^j '`
            | ForEach-Object { $finalOptions = $_ + " $($defaultValue)e" }

            [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$finalOptions")
        }
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
}



$HistorySearchGlobalParameters = @{
    Key              = 'Ctrl+Shift+j'
    BriefDescription = 'Jrnl edit back?'
    LongDescription  = 'draft.'
    ScriptBlock      = {
        param($key, $arg)   # The arguments are ignored in this example

        # GetBufferState gives us the command line (with the cursor position)
        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line,
            [ref]$cursor)
        $finalOptions = $null
        $defaultValue = 8

        # NOTE: should have used LSP for this instead.
        $line = $line.Trim()
        $originalCommand = $line -split " "

        if ($originalCommand.Count -lt 2) {
            Get-Content -Tail 200 (Get-PSReadLineOption).HistorySavePath `
            | Select-String -Pattern '^j\s+(?:\w|\:)' `
            | fzf --query '^j ' `
            | ForEach-Object { $finalOptions = $_ + " $($defaultValue)e" }
        }
        else {
            $finalOptions = " 6 | b -lmd"
        }
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$finalOptions")
    
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
}

# Custom implementation of the ViEditVisually PSReadLine function.
$openEditorParameters = @{
    Key              = 'ctrl+x,ctrl+e' 
    BriefDescription = 'Set-LocationWhere the paste directory.'
    LongDescription  = 'Invoke cdwhere with the current directory in the command line'
    ScriptBlock      = {
        param($key, $arg)
        [Microsoft.PowerShell.PSConsoleReadLine]::ViEditVisually()
    }
}

function Edit-PipedContent {
    param(
        [Parameter(ValueFromPipeline = $true)]
        [string[]]$InputObject
    )
    
    begin { $content = @() }
    process { $content += $InputObject }
    end {
        $tempFile = [System.IO.Path]::GetTempFileName()
        $content | Out-File -FilePath $tempFile -Encoding UTF8
        
        # Edit with your preferred editor
        & $env:EDITOR $tempFile
        
        # Read back the edited content
        Get-Content $tempFile
        Remove-Item $tempFile
    }
}

# Custom implementation that uses ViEditVisually with piped content
$pipeEditorParameters = @{
    Key              = 'alt+x' 
    BriefDescription = 'pipe -> editor'
    LongDescription  = 'pipe results of a command to ViEditVisually.'
    ScriptBlock      = {
        param($key, $arg)
        
        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        
        # Determine source command - prioritize current line like your existing pattern
        $sourceCommand = if (-not [string]::IsNullOrWhiteSpace($line)) {
            $line
        }
        else { 
            (Get-History -Count 1).CommandLine 
        }
        
        # Create command that captures output and puts it in buffer for ViEditVisually
        $__output = ($sourceCommand) | Invoke-Expression | Out-String
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($__output)
        [Microsoft.PowerShell.PSConsoleReadLine]::ViEditVisually()
    }
}

$rgToNvimParameters = @{
    Key              = 'Alt+v'
    BriefDescription = 'open `ig`'
    LongDescription  = 'Invoke ig in place of rg.'
    ScriptBlock      = {
        param($key, $arg)   # The arguments are ignored in this example

        # GetBufferState gives us the command line (with the cursor position)
        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line,
            [ref]$cursor)
        $line.Trim()
        if ($line -match '^rg') {
            # INFO: Replace could actually increase the length of original strings.
            # So I could be longer than the start.
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, 2, "ig")
        }
        elseif ($line -match '^id') {
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, 2, "iid")
        }
        else {
            # INFO: check history for the latest match commands
            $SearchWithQuery = Get-History -Count 40 `
            | Sort-Object -Property Id -Descending `
            | Where-Object { $_.CommandLine -match "^(rg|id)" }
            | Select-Object -Index 0 `

            if ($SearchWithQuery -match '^rg') {
                $SearchWithQuery = $SearchWithQuery -replace '^rg', "ig"
            }
            elseif ($SearchWithQuery -match '^id') {
                $SearchWithQuery = $SearchWithQuery -replace '^id', "iid"
            }
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($SearchWithQuery)
        }
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
      
    }
}


$rgToRggParameters = @{
    Key              = 'Ctrl+h'
    BriefDescription = 'replace in `rgr`'
    LongDescription  = 'Invoke rgr in place of rg.'
    ScriptBlock      = {
        param($key, $arg)   # The arguments are ignored in this example

        # GetBufferState gives us the command line (with the cursor position)
        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line,
            [ref]$cursor)
        $matchFunction = "rg|rgj"
        $injectSearch = {
            param($command)
            $command -match "^($matchFunction)\s"
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $Matches[0].Length, "rgr ")
        }
        if ($line -match "^($matchFunction)") {
            $injectSearch.Invoke($line)
        }
        else {
            $SearchWithQuery = Get-History -Count 40 `
            | Sort-Object -Property Id -Descending `
            | Where-Object { $_.CommandLine -match "^($matchFunction)" }
            | Select-Object -Index 0 `

            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($SearchWithQuery)
            $injectSearch.Invoke($SearchWithQuery)
        }
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
      
    }
}

$quickEscParameters = @{
    Key              = 'Ctrl+k'
    BriefDescription = 'Open Kicad'
    LongDescription  = 'Reserved key combo. Havent thought of any useful function to use with its'
    ScriptBlock      = {
        param($key, $arg)   # The arguments are ignored in this example

        # GetBufferState gives us the command line (with the cursor position)
        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line,
            [ref]$cursor)
        #Store to history for future use.
        # Can InvertLine() here to return empty line.
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
      
    }
}

$sudoRunParameters = @{
    Key              = 'Ctrl+shift+x'
    BriefDescription = 'Execute as sudo (in pwsh).'
    LongDescription  = 'Call sudo on current command or latest command in history.'
    ScriptBlock      =
    {
        param($key, $arg)   # The arguments are ignored in this example

        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line,
            [ref]$cursor)
        
        # INFO: I literally buffer a history in here.
        $historyAlternative = "$(Get-History -Count 1)"
        if ($line.Trim(), $historyAlternative -match "^(cd|z|zb|zq|zqb)[bi]?\s") {
            # HACK: fat finger...
            $quickZoxide.Invoke($key, $arg)
        }
        else {
            $invokeFunction = "Invoke-SudoPwsh"
            if ($line -match "[a-z]") {
                $invokeCommand = "$invokeFunction `'$line`'"
            }
            else {
                if ($historyAlternative.Trim() -match "^($invokeFunction)") {
                    $invokeCommand = "$historyAlternative"
                }
                else {

                    $invokeCommand = "$invokeFunction `'$historyAlternative`'"
                }
            }

            # HACK: Just revert the line and brute force printing the line again in console.
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, $invokeCommand)
            [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
        }
    }
}


# HACK: combine both Bakwardkillword and forwardkillword(alt+D) 
$smartKillWordParameters = @{
    Key              = 'Ctrl+Backspace', 'Ctrl+w'
    BriefDescription = 'Smarter kill word '
    LongDescription  = 'Call sudo on current command or latest command in history.'
    ScriptBlock      = {
        param($key, $arg)   # The arguments are ignored in this example

        # GetBufferState gives us the command line (with the cursor position)
        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line,
            [ref]$cursor)
     
        #Info 
        if ($cursor -eq 0) {
            [Microsoft.PowerShell.PSConsoleReadLine]::KillWord()
        }
        else {
            [Microsoft.PowerShell.PSConsoleReadLine]::BackwardKillWord()
        }
    }
}

$ExtraKillWord1Parameters = @{
    Key              = @('Alt+w', 'alt+d')
    BriefDescription = 'Smarter kill word '
    LongDescription  = 'Kill Forward, but hit ceiling then kill backward.'
    ScriptBlock      = {
        param($key, $arg)   # The arguments are ignored in this example

        # GetBufferState gives us the command line (with the cursor position)
        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line,
            [ref]$cursor)
     
        #Info 
        if ($cursor -ge ($line.length - 2)) {
            [Microsoft.PowerShell.PSConsoleReadLine]::BackwardKillWord()
        }
        else {
            [Microsoft.PowerShell.PSConsoleReadLine]::KillWord()
        }
    }
}

$helpParameter = @{
    Key              = 'Ctrl+b'
    BriefDescription = 'help'
    LongDescription  = 'As brief.'
    ScriptBlock      = {
        param($key, $arg)

        $selectionStart = $null
        $selectionLength = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        
        if ($line.Length -eq 0) {
            $line = "$((Get-History -Count 1).CommandLine)"
            $cursor = $null
        }

        $pipeAll = "*>&1 | b -lhelp"
        $mundaneHelpPattern = "help $pipeAll"
        $otherhelppattern = "--help $pipeAll"
        $helpPattern = "-h $pipeAll"
        $plainPipe = "\|\s*?b"

        switch ($line) {
            { $_.EndsWith($helpPattern) -eq $true } {
                $finalString = $_.Replace($helpPattern, $otherHelpPattern)
                break
            }
            { $_.EndsWith($otherHelpPattern) -eq $true } {
                $finalString = $_.Replace($otherHelpPattern, $mundaneHelpPattern)
                break
            }            
            { $_.EndsWith($mundaneHelpPattern) -eq $true } {
                $finalString = $_.Replace($mundaneHelpPattern, $helpPattern)
                break
            }
            { $_.EndsWith($pipeAll) -eq $true } {
                $finalString = $_.Replace($pipeAll, "| b")
                break
            }
            { $_ -match $plainPipe } {
                $finalString = $_ | Select-String -Pattern $plainPipe | % { $_.Line.replace($_.Matches.Value, $pipeAll) }
            }
            default {
                $finalString = $_ + " $helpPattern"
            }
        }

        if ($null -ne $cursor) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, "$finalString")
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($line.Length - 1)
        }
        else {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($finalString)
        }
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
        if ($?) {
            Write-Host "nope."
        }
    }
}


$MathExpressionParameter = @{
    Key              = 'Alt+m'
    BriefDescription = 'parentheses the selection'
    LongDescription  = 'As brief.'
    ScriptBlock      = {
        param($key, $arg)

        $selectionStart = $null
        $selectionLength = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        if ($selectionStart -ne -1) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, 'bc "' + $line.SubString($selectionStart, $selectionLength) + '"')
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
        }
        else {
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, 'bc "' + $line + '"')
            [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
        }
  
    }

}


$ParenthesesParameter = @{
    Key              = 'Alt+0'
    BriefDescription = 'parentheses the selection or nearest token'
    LongDescription  = 'Wraps selected text in parentheses; if no selection, wraps the token nearest to the cursor. Cursor is placed after the closing parenthesis.'
    ScriptBlock      = {
        param($key, $arg)
        Invoke-PSReadLineWrapToken -Open '(' -Close ')'
    }
}

$ParenthesesAllParameter = @{
    Key              = 'Ctrl+9'
    BriefDescription = 'parentheses the selection or nearest token'
    LongDescription  = 'Wraps selected text in parentheses; if no selection, wraps the token nearest to the cursor. Cursor is placed after the closing parenthesis.'
    ScriptBlock      = {
        param($key, $arg)
        Invoke-PSReadLineWrapToken -Open '(' -Close ')'
    }
}

$SquareBracketsParameter = @{
    # PSReadLine identifies Ctrl+[ as Ctrl+Oem4 on Windows consoles.
    Key              = 'Ctrl+Oem4'
    BriefDescription = 'brackets the selection or nearest token'
    LongDescription  = 'Wraps selected text in square brackets; if no selection, wraps the token nearest to the cursor. Cursor is placed after the closing bracket.'
    ScriptBlock      = {
        param($key, $arg)
        Invoke-PSReadLineWrapToken -Open '[' -Close ']'
    }
}

$DoubleQuotesParameter = @{
    Key              = "Ctrl+'"
    BriefDescription = 'parentheses the selection or nearest token'
    LongDescription  = 'Wraps selected text in parentheses; if no selection, wraps the token nearest to the cursor. Cursor is placed after the closing parenthesis.'
    ScriptBlock      = {
        param($key, $arg)

        $selectionStart = $null
        $selectionLength = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        if ($selectionStart -ne -1) {
            $selectedText = $line.SubString($selectionStart, $selectionLength)
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, "`"$selectedText`"")
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
        }
        else {
            $ast = $null
            $tokens = $null
            $errors = $null
            $cursor = $null
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)
            $line = if ($ast.Extent) { $ast.Extent.Text } else { '' }
            $nearestToken = $tokens | Where-Object {
                $_.Extent.StartOffset -le $cursor -and $_.Extent.EndOffset -ge $cursor
            } | Select-Object -First 1

            if (-not $nearestToken) {
                # If no token is under the cursor, find the closest token
                $nearestToken = $tokens | Sort-Object {
                    [Math]::Abs($_.Extent.StartOffset - $cursor)
                } | Select-Object -First 1
            }

            if ($nearestToken -and 
                $nearestToken.Extent.StartOffset -ge 0 -and 
                $nearestToken.Extent.StartOffset -le $line.Length -and 
                $nearestToken.Extent.EndOffset -le $line.Length) {
                $start = $nearestToken.Extent.StartOffset
                $length = $nearestToken.Extent.EndOffset - $start
                $text = $nearestToken.Extent.Text
                [Microsoft.PowerShell.PSConsoleReadLine]::Replace($start, $length, "`"$text`"")
                [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($start + $length + 1)
            }
            else {
                # Fallback: insert () at cursor
                [Microsoft.PowerShell.PSConsoleReadLine]::Insert('""')
                [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
            }
        }
    }
}


$CalculatorParameter = @{
    Key              = "Ctrl+="
    BriefDescription = 'bc and fend things.'
    LongDescription  = 'Wraps selected text in parentheses for bc'
    ScriptBlock      = {
        param($key, $arg)

        $selectionStart = $null
        $selectionLength = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        if ($selectionStart -ne -1) {
            $selectedText = $line.SubString($selectionStart, $selectionLength)
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, "bc `"$selectedText`"")
            if ($line.Length -eq $selectionLength) { 
                [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine() 
            }
            else {
                [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
            }
        }
        else {
            $ast = $null
            $tokens = $null
            $errors = $null
            $cursor = $null
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)
            $line = if ($ast.Extent) { $ast.Extent.Text } else { '' }
            $nearestToken = $tokens | Where-Object {
                $_.Extent.StartOffset -le $cursor -and $_.Extent.EndOffset -ge $cursor
            } | Select-Object -First 1

            if (-not $nearestToken) {
                # If no token is under the cursor, find the closest token
                $nearestToken = $tokens | Sort-Object {
                    [Math]::Abs($_.Extent.StartOffset - $cursor)
                } | Select-Object -First 1
            }

            if ($nearestToken -and 
                $nearestToken.Extent.StartOffset -ge 0 -and 
                $nearestToken.Extent.StartOffset -le $line.Length -and 
                $nearestToken.Extent.EndOffset -le $line.Length) {
                $start = $nearestToken.Extent.StartOffset
                $length = $nearestToken.Extent.EndOffset - $start
                $text = $nearestToken.Extent.Text
                [Microsoft.PowerShell.PSConsoleReadLine]::Replace($start, $length, "bc `"$text`"")
                [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($start + $length + 1)
            }
            else {
                [Microsoft.PowerShell.PSConsoleReadLine]::Insert('bc ""')
                # move cursor in between the quotes
                [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 4)
            }
        }
    }
}

# TODO: all this should have the nearest match function implemented in alt+0 and alt+9

$WrapPipeParameter = @{
    Key              = 'Ctrl+\'
    BriefDescription = 'wrap in pipe (|%{<selected one> $_})'
    LongDescription  = 'As brief.'
    ScriptBlock      = {
        param($key, $arg)

        $selectionStart = $null
        $selectionLength = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        if ($selectionStart -ne -1) {
            # Wrap selected text in |%{}
            $selectedText = $line.SubString($selectionStart, $selectionLength)
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, "|%{$selectedText `$_}")
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 4)
        }
        else {
            # Append |%{} at the end and place cursor between braces
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($line.Length, 0, "|%{ `$_}")
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($line.Length + 3)
        }
    }
}

$ToggleCaseParameter = @{
    Key              = 'Alt+`'
    BriefDescription = 'Toggle case of selection or line'
    LongDescription  = 'Toggles the case (Upper/Lower) of the selected text. If no selection, toggles the entire current line.'
    ScriptBlock      = {
        param($key, $arg)

        $selectionStart = $null
        $selectionLength = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

        if ($selectionStart -ne -1) {
            # There is a selection
            $selectedText = $line.Substring($selectionStart, $selectionLength)
            $toggledText = if ($selectedText -cmatch '^[A-Z]') {
                # If first char is uppercase → make whole selection lowercase
                $selectedText.ToLower()
            }
            else {
                # Otherwise → make whole selection uppercase
                $selectedText.ToUpper()
            }

            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, $toggledText)
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength)
        }
        else {
            # No selection → toggle the entire line
            $toggledLine = if ($line -cmatch '^[A-Z]') {
                $line.ToLower()
            }
            else {
                $line.ToUpper()
            }

            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, $toggledLine)
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor)
        }
    }
}



$SelectPipeParameter = @{
    Key              = 'Ctrl+Shift+|'
    BriefDescription = 'wrap in pipe (| select)'
    LongDescription  = 'As brief.'
    ScriptBlock      = {
        param($key, $arg)

        $selectionStart = $null
        $selectionLength = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        if ($selectionStart -ne -1) {
            $selectedText = $line.SubString($selectionStart, $selectionLength)
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, "| select $selectedText ")
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 9)
        }
        else {
            # Append |%{} at the end and place cursor between braces
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($line.Length, 0, "| select ")
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($line.Length + 9)
        }
    }
}


$WherePipeParameter = @{
    Key              = 'Ctrl+/'
    BriefDescription = 'wrap in pipe (| ? -eq )'
    LongDescription  = 'As brief.'
    ScriptBlock      = {
        param($key, $arg)

        $selectionStart = $null
        $selectionLength = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        if ($selectionStart -ne -1) {
            $selectedText = $line.SubString($selectionStart, $selectionLength)
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, "| ? $selectedText -eq ")
            # HACK: only fill in the RHS here...
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 9)
        }
        else {
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($line.Length, 0, "| ?  -eq")
            # NOTE: Missing LHS so we fill them first.
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($line.Length + 4)
        }
    }
}

$ExchangePointAndMarkParameters = @{
    Key              = 'Alt+;'
    BriefDescription = 'exchange cursor and selection anchor'
    LongDescription  = 'Swap the cursor position with the selection anchor while keeping the selection.'
    ScriptBlock      = {
        param($key, $arg)

        $selectionStart = $null
        $selectionLength = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)
        if ($selectionStart -lt 0 -or $selectionLength -le 0) {
            [Microsoft.PowerShell.PSConsoleReadLine]::SetMark($null, $null)
            return
        }

        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        $selectionEnd = $selectionStart + $selectionLength
        $cursorAtStart = $cursor -eq $selectionStart

        # Recreate the same range with the active end reversed. SetMark is
        # used after moving because moving the point clears the old selection.
        if ($cursorAtStart) {
            # The current point is at the start; select forward so the new
            # point ends at the other side of the same range.
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart)
            [Microsoft.PowerShell.PSConsoleReadLine]::SetMark($null, $null)
            [Microsoft.PowerShell.PSConsoleReadLine]::SelectForwardChar($null, $selectionLength)
        }
        else {
            # The current point is at the end; select backward so the new
            # point ends at the other side of the same range.
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionEnd)
            [Microsoft.PowerShell.PSConsoleReadLine]::SetMark($null, $null)
            [Microsoft.PowerShell.PSConsoleReadLine]::SelectBackwardChar($null, $selectionLength)
        }
    }
}



$GlobalEditorSwitch = @{
    Key              = 'Ctrl+Shift+e,Ctrl+Shift+e'
    BriefDescription = 'Change $env:nvim_appname to something else'
    LongDescription  = 'I think I need to work on changing $env:EDITOR as well.'
    ScriptBlock      = {
        param($key, $arg)
        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        if ($env:nvim_appname -eq $null) {
            Write-Host "`nNow minimal" -NoNewline
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor)
            $env:nvim_appname = "viniv"
            $env:EDITOR = "hx"
        }
        else {
            Write-Host "`nNow complex" -NoNewline
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor)
            $env:nvim_appname = $null
        }
    } 
}

# INFO: switch between windows mode and vi mode. for easier navigation
$OptionsSwitchParameters = @{
    Key              = 'Ctrl+x,Ctrl+x'
    BriefDescription = 'toggle vi navigation'
    LongDescription  = 'as I mimic the behaviour in zsh'
    ScriptBlock      = {
        param($key, $arg)   # The arguments are ignored in this example
        OptionsSwitch 
        setAllHandler
        # HACK: set the ctrl+r and ctrl+t
        # MoreTerminalModule

        # INFO: this ensure some color is re-rendered so I can specify the mode.
        [Microsoft.PowerShell.PSConsoleReadLine]::ClearScreen()
    }
}


# INFO: Start Command Mode commands.
$OptionsSwitch_Command_Parameters = @{
    Key              = 'Ctrl+x,Ctrl+x'
    BriefDescription = 'toggle vi navigation in command(normal) mode'
    LongDescription  = 'This is only included when in ViMode,in command(normal) mode'
    ViMode           = "Command"
    ScriptBlock      = {
        param($key, $arg)  
        OptionsSwitch 
        setAllHandler
        # MoreTerminalModule
        [Microsoft.PowerShell.PSConsoleReadLine]::ClearScreen()
    }
}

# HACK: Solution [at here as today](https://github.com/PowerShell/PSReadLine/issues/1701#issuecomment-1019386349)
$j_timer = New-Object System.Diagnostics.Stopwatch

$twoKeyEscape_k_Parameters = @{
    Key              = 'k'
    BriefDescription = 'jk escape'
    LongDescription  = 'This is only included when in ViMode,in command(normal) mode'
    ViMode           = "Insert"
    ScriptBlock      = {
        param($key, $arg)   
        if (!$j_timer.IsRunning -or $j_timer.ElapsedMilliseconds -gt 500) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("k")
        }
        else {
            [Microsoft.PowerShell.PSConsoleReadLine]::ViCommandMode()
            $line = $null
            $cursor = $null
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
            [Microsoft.PowerShell.PSConsoleReadLine]::Delete($cursor, 1)
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor - 1)
        }

    }
}


$twoKeyEscape_j_Parameters = @{
    Key              = 'j'
    BriefDescription = 'jk/jj escape'
    LongDescription  = 'This is only included when in ViMode,in command(normal) mode'
    ViMode           = "Insert"
    ScriptBlock      = {
        param($key, $arg)   
        if (!$j_timer.IsRunning -or $j_timer.ElapsedMilliseconds -gt 500) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("j")
            $j_timer.Restart()
            return # HACK: return right before anything got executed below.
        }
    
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("j")
        [Microsoft.PowerShell.PSConsoleReadLine]::ViCommandMode()

        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        [Microsoft.PowerShell.PSConsoleReadLine]::Delete($cursor - 1, 2)
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor - 2)
    
    }
}

# INFO: Common Windows/Vi Mode Key handlers
$HandlerParameters = @(
    $ggSearchParameters
    , $VaultSearchParameters
    , $QuickZoxideParameters
    , $omniSearchParameters
    , $JrnlParameters 
    , $HistorySearchGlobalParameters
    , $sudoRunParameters
    , $smartKillWordParameters
    , $ExtraKillWord1Parameters
    , $ParenthesesParameter
    , $ParenthesesAllParameter
    , $SquareBracketsParameter
    , $DoubleQuotesParameter
    , $DoubleQuotesNestedBracketParameter
    , $WrapPipeParameter
    , $ToggleCaseParameter
    , $WherePipeParameter
    , $ExchangePointAndMarkParameters
    , $SelectPipeParameter
    , $rgToNvimParameters
    , $rgToRggParameters
    , $IterateCommandParameters
    , $IterateCommandReverseParameters
    , $MoveSelectionToNextPhraseParameters
    , $MoveSelectionToPreviousPhraseParameters
    , $OptionsSwitchParameters
    , $openEditorParameters
    , $pipeEditorParameters
    , $GlobalEditorSwitch
    , $MathExpressionParameter
    , $helpParameter
    , $CalculatorParameter
)
# INFO: Unique for Vi mode.
$ViHandlerParameters = @(
    $OptionsSwitch_Command_Parameters
    , $twoKeyEscape_k_Parameters 
    , $twoKeyEscape_j_Parameters 
)
# INFO: Default of Windows PSReadLineOptions
$PSReadLineOptions_Windows = @{
    EditMode                      = "Windows"
    HistoryNoDuplicates           = $true
    HistorySearchCursorMovesToEnd = $true
    CompletionQueryItems          = 500
    PredictionViewStyle           = "ListView"
    Colors                        = @{
        "Command" = "#f9f1a5"
    }
}

$PSReadLineOptions_Vi = @{
    EditMode                      = "Vi"
    HistoryNoDuplicates           = $true
    HistorySearchCursorMovesToEnd = $true
    CompletionQueryItems          = 500
    PredictionViewStyle           = "ListView"
    Colors                        = @{
        "Command" = "#8181f7"
    }
}
# Define parameters for disabling v, j, k in Vi normal mode
$v_Parameters = @{
    Chord  = 'v'
    ViMode = 'Command'
}

$j_Parameters = @{
    Chord  = 'j'
    ViMode = 'Command'
}

$k_Parameters = @{
    Chord  = 'k'
    ViMode = 'Command'
}

# INFO: Unique for Vi mode.
$ViHandlerRemoveParameters = @(
    $v_Parameters
    , $j_Parameters
    , $k_Parameters
)

# Television PowerShell Integration
# Requires PSReadLine module (usually included by default in PowerShell 5.1+)

function Get-AvailableSpaceBelowPrompt {
    $windowHeight = [Console]::WindowHeight
    $windowTop = [Console]::WindowTop
    $cursorY = [Console]::CursorTop
    $spaceBelow = $windowHeight - ($cursorY - $windowTop)
    return $spaceBelow
}

function Invoke-TvSmartAutocomplete {
    <#
    .SYNOPSIS
        Smart autocomplete using television (tv) based on current command context
    #>
    [CmdletBinding()]
    param()

    # Get the current command line and cursor position
    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    # Get the part before cursor (left buffer)
    $lhs = $line.Substring(0, $cursor)
    $rhs = $line.Substring($cursor)

    # Separate lhs into words to get the last word
    $words = $lhs -split '\s+'
    # Handle trailing space - if last char is space, we're starting a new word
    if ($lhs.Length -gt 0 -and $lhs[-1] -match '\s') {
        $lastWord = ""
    }
    else {
        $lastWord = if ($words.Count -gt 0) { $words[-1] } else { "" }
    }

    # Call tv with autocomplete prompt
    try {
        # Debug file for cursor position tracking
        $debugFile = Join-Path $env:TEMP "tv-pwsh-debug.log"

        # Save the original prompt position
        $originalPromptY = [Console]::CursorTop
        $savedCursorX = [Console]::CursorLeft

        # skip a line to make room for TV's UI
        [Console]::WriteLine()

        # how much space left down
        $spaceBelow = Get-AvailableSpaceBelowPrompt
        $minTVHeight = 15
        $tvScrollLines = 0
        if ($spaceBelow -lt $minTVHeight) {
            # Not enough space below, scroll up
            $tvScrollLines = $minTVHeight - $spaceBelow
        }

        # Escape arguments properly for Windows command-line parsing
        # Backslashes before quotes need to be escaped to prevent them from escaping the quote
        $lhsEscaped = $lhs -replace '\\+$', '$0$0'  # Double trailing backslashes
        $lastWordEscaped = $lastWord -replace '\\+$', '$0$0'  # Double trailing backslashes

        # Use .NET Process class for explicit stream control
        # This ensures stdin comes from console, stdout is captured, and stderr (TUI) goes to console
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "tv"
        $psi.Arguments = "--no-status-bar --inline --autocomplete-prompt `"$lhsEscaped`" --input `"$lastWordEscaped`""
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $false  # Let TUI render to console
        $psi.RedirectStandardInput = $false  # Let process use console directly for input
        $psi.WorkingDirectory = $PWD.Path  # Use current PowerShell working directory

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $psi
        $process.Start() | Out-Null

        # Read stdout
        $output = $process.StandardOutput.ReadToEnd().Trim()
        $process.WaitForExit()

        # Restore cursor to original position
        [Console]::CursorTop = $originalPromptY - $tvScrollLines
        [Console]::CursorLeft = $savedCursorX

        if ($output) {
            # TV returns the full completed path, so we need to remove the lastWord from lhs
            # to avoid duplication
            $lhsWithoutLastWord = if ($lastWord.Length -gt 0) {
                $lhs.Substring(0, $lhs.Length - $lastWord.Length)
            }
            else {
                $lhs
            }

            # Replace the buffer with the completion
            $newLine = $lhsWithoutLastWord + $output + $rhs
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, $newLine)
        }
    }
    catch {
        # Print error if tv is not available or errors occur
        Write-Debug "TV autocomplete failed: $_"
    }
}

function Invoke-TvShellHistory {
    <#
    .SYNOPSIS
        Search shell history using television (tv)
    #>
    [CmdletBinding()]
    param()

    # Get the current command line and cursor position
    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    # Get the part before cursor as search context
    $currentPrompt = $line.Substring(0, $cursor)

    # Call tv with history channel
    try {
        # Debug file for cursor position tracking
        $debugFile = Join-Path $env:TEMP "tv-pwsh-debug.log"

        # Save the original prompt position before any scrolling
        $originalPromptY = [Console]::CursorTop
        $savedCursorX = [Console]::CursorLeft

        # skip a line to make room for TV's UI
        [Console]::WriteLine()

        # how much space left down
        $spaceBelow = Get-AvailableSpaceBelowPrompt
        $minTVHeight = 15
        $tvScrollLines = 0
        if ($spaceBelow -lt $minTVHeight) {
            # Not enough space below, scroll up
            $tvScrollLines = $minTVHeight - $spaceBelow
        }

        # Escape arguments properly for Windows command-line parsing
        $currentPromptEscaped = $currentPrompt -replace '\\+$', '$0$0'  # Double trailing backslashes

        # Use .NET Process class for explicit stream control
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "tv"
        $psi.Arguments = "pwshhist --inline --no-status-bar --input `"$currentPromptEscaped`""
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $false  # Let TUI render to console
        $psi.RedirectStandardInput = $false  # Let process use console directly for input
        $psi.WorkingDirectory = $PWD.Path  # Use current PowerShell working directory

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $psi
        $process.Start() | Out-Null

        # Read stdout (the selected result)
        $output = $process.StandardOutput.ReadToEnd().Trim()
        $process.WaitForExit()

        # Restore cursor to original position
        [Console]::CursorTop = $originalPromptY - $tvScrollLines
        [Console]::CursorLeft = $savedCursorX

        if ($output) {
            # Replace entire line with selected history
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, $output)
        }
    }
    catch {
        # Print error if tv is not available or errors occur
        Write-Debug "TV shell history failed: $_"
    }
}


function Test-CompletionMenuOverflow {
    param(
        [Parameter(Mandatory)]
        [object[]]$CompletionMatches
    )

    $windowWidth = 120
    try {
        if ([Console]::WindowWidth -gt 0) { $windowWidth = [Console]::WindowWidth }
    }
    catch { }
    try {
        $spaceBelow = Get-AvailableSpaceBelowPrompt
    }
    catch {
        $spaceBelow = 20
    }

    $maxMenuItems = [Math]::Min(40, [Math]::Max(8, $spaceBelow - 4))
    $maxItemWidth = [Math]::Max(24, [Math]::Floor($windowWidth / 2))
    $hasLongName = @($CompletionMatches | Where-Object {
            ([string]$_.ListItemText).Length -ge $maxItemWidth
        }).Count -gt 0
    $displayWidth = @($CompletionMatches | ForEach-Object {
            ([string]$_.ListItemText).Length + 2
        } | Measure-Object -Sum).Sum
    $estimatedRows = [Math]::Ceiling($displayWidth / $windowWidth)

    return $CompletionMatches.Count -gt $maxMenuItems -or
        $estimatedRows -gt [Math]::Max(4, $spaceBelow - 2) -or
        $hasLongName
}

function Invoke-PathCompletion {
    param(
        [Parameter(Mandatory)]
        [object]$Key,
        [object]$Argument
    )

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    $completion = [System.Management.Automation.CommandCompletion]::CompleteInput($line, $cursor, $null)
    $pathMatches = @($completion.CompletionMatches | Where-Object {
            $_.ResultType -eq [System.Management.Automation.CompletionResultType]::ProviderContainer -or
            $_.ResultType -eq [System.Management.Automation.CompletionResultType]::ProviderItem
        })

    if ($pathMatches.Count -eq 0 -or -not (Test-CompletionMenuOverflow -CompletionMatches $pathMatches)) {
        [Microsoft.PowerShell.PSConsoleReadLine]::MenuComplete($Key, $Argument)
        return
    }

    Write-Warning ("{0} path completions are too large for the console; using fzf to select one." -f $pathMatches.Count)
    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        Write-Warning 'fzf is not available; path completion was cancelled.'
        return
    }

    $selectedPath = @($pathMatches.CompletionText | & fzf --prompt 'Select path> ' | Select-Object -First 1)
    if ($selectedPath) {
        $selectedPath = [string]$selectedPath[0]
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace(
            $completion.ReplacementIndex,
            $completion.ReplacementLength,
            $selectedPath
        )
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition(
            $completion.ReplacementIndex + $selectedPath.Length
        )
    }
}

function Invoke-DirectoryMenuComplete {
    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    $completion = [System.Management.Automation.CommandCompletion]::CompleteInput($line, $cursor, $null)
    $start = $completion.ReplacementIndex
    $length = $completion.ReplacementLength
    if ($start -gt $cursor -or $start + $length -gt $line.Length) { return }

    $pathPrefix = 'Set-Location -Path '
    $menuLine = $pathPrefix + $line.Substring($start, $cursor - $start)
    $directoryCompletion = [System.Management.Automation.CommandCompletion]::CompleteInput($menuLine, $menuLine.Length, $null)
    $directoryMatches = @($directoryCompletion.CompletionMatches | Where-Object ResultType -eq ProviderContainer)
    if ($directoryMatches.Count -eq 0 -or
        $directoryMatches.Count -ne $directoryCompletion.CompletionMatches.Count) {
        return
    }

    # A large PSReadLine completion menu wraps long names and consumes the
    # prompt.  Use fzf when the candidates cannot reasonably fit below it.
    $useFzf = Test-CompletionMenuOverflow -CompletionMatches $directoryMatches

    $selectedPath = $null
    if ($useFzf) {
        Write-Warning ("{0} directory completions are too large for the console; using fzf to select one." -f $directoryMatches.Count)
        if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
            Write-Warning 'fzf is not available; directory completion was cancelled.'
            return
        }
        $selectedPath = @($directoryMatches.CompletionText | & fzf --prompt 'Select directory> ' | Select-Object -First 1)
        if ($selectedPath) { $selectedPath = [string]$selectedPath[0] }
    }
    else {
        try {
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, $menuLine)
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($menuLine.Length)
            [Microsoft.PowerShell.PSConsoleReadLine]::MenuComplete()

            $completedLine = $null
            $completedCursor = $null
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$completedLine, [ref]$completedCursor)
            if ($completedLine.StartsWith($pathPrefix) -and $completedLine -ne $menuLine) {
                $selectedPath = $completedLine.Substring($pathPrefix.Length)
            }
        }
        finally {
            $currentLine = $null
            $currentCursor = $null
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$currentLine, [ref]$currentCursor)
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $currentLine.Length, $line)
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor)
        }
    }

    if ($null -ne $selectedPath) {
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace($start, $length, $selectedPath)
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($start + $selectedPath.Length)
    }
}

function Add-DirectoryCompletionKeyMapping {
    $readLineType = [Microsoft.PowerShell.PSConsoleReadLine]
    $flags = [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Static -bor [System.Reflection.BindingFlags]::Instance
    $singleton = $readLineType.GetField('_singleton', $flags).GetValue($null)
    $dispatch = $readLineType.GetField('_dispatchTable', $flags).GetValue($singleton)
    $fromKeyInfo = $readLineType.Assembly.GetType('Microsoft.PowerShell.PSKeyInfo').GetMethod('FromConsoleKeyInfo')

    # PSReadLine's chord parser gives Ctrl+Alt+Spacebar a space character, which collides with plain Space.
    $spaceKey = $fromKeyInfo.Invoke($null, @([ConsoleKeyInfo]::new([char]32, [ConsoleKey]::Spacebar, $false, $true, $true)))
    $chordKey = $fromKeyInfo.Invoke($null, @([ConsoleKeyInfo]::new([char]0, [ConsoleKey]::Spacebar, $false, $true, $true)))
    if ($null -eq $script:directoryCompletionKeyHandler) {
        $script:directoryCompletionKeyHandler = $dispatch[$spaceKey]
    }

    foreach ($name in '_dispatchTable', '_viInsKeyMap', '_viCmdKeyMap') {
        $field = $readLineType.GetField($name, $flags)
        if ($null -eq $field) { continue }
        $keyMap = $field.GetValue($(if ($field.IsStatic) { $null } else { $singleton }))
        if ($null -eq $keyMap) { continue }
        $keyMap[$chordKey] = $script:directoryCompletionKeyHandler
        $keyMap[$spaceKey] = $script:directoryCompletionKeyHandler
    }
}

# Common spellings used by PSReadLine, Kanata, terminal emulators, editors,
# and keyboard documentation.  Keep modifier prefixes separate from key names:
# a bare `s` is the S key, while `S-` means Shift in Kanata notation.
$script:KeyComboDictionary = [ordered]@{
    Modifiers = [ordered]@{
        ctrl  = @('C', 'Ctrl', 'Control', 'Ctl', 'lctl', 'lctrl', 'LeftCtrl', 'LCtrl')
        rctrl = @('RC', 'RCtrl', 'rctl', 'rctrl', 'RightCtrl')
        meta  = @('M', 'Meta', 'lmet', 'lmeta', 'LeftMeta', 'Win', 'Windows', 'Super', 'GUI', 'Command', 'Cmd')
        rmeta = @('RM', 'RMeta', 'rmet', 'rmeta', 'RightMeta')
        alt   = @('A', 'Alt', 'Option', 'lalt', 'LeftAlt')
        ralt  = @('RA', 'RAlt', 'ralt', 'AltGr', 'RightAlt', 'AG')
        shift = @('S', 'Shift', 'lsft', 'lshift', 'LeftShift')
        rshift = @('RS', 'RShift', 'rsft', 'rshift', 'RightShift')
    }
    Keys = [ordered]@{
        esc   = @('Esc', 'Escape')
        ret   = @('Enter', 'Return', 'Ret', 'Ent')
        tab   = @('Tab')
        bspc  = @('Backspace', 'Back', 'BS', 'Bspc')
        del   = @('Delete', 'Del')
        ins   = @('Insert', 'Ins')
        spc   = @('Space', 'Spacebar', 'SPC')
        pgup  = @('PageUp', 'PgUp', 'Prior')
        pgdn  = @('PageDown', 'PgDn', 'Next')
        left  = @('Left', 'LeftArrow', 'ArrowLeft', 'Lft')
        right = @('Right', 'RightArrow', 'ArrowRight', 'Rght')
        up    = @('Up', 'UpArrow', 'ArrowUp')
        down  = @('Down', 'DownArrow', 'ArrowDown')
        home  = @('Home')
        end   = @('End')
        pause = @('Pause', 'Break', 'Brk')
        caps  = @('CapsLock', 'Caps')
        nlck  = @('NumLock', 'Num')
        scrlck = @('ScrollLock', 'Scroll')
        grv   = @('Grv', 'Backquote', 'Oem3')
        min   = @('Minus', 'OemMinus')
        eql   = @('Equal', 'OemPlus')
        lbrc  = @('BracketLeft', 'LeftBracket', 'Oem4')
        rbrc  = @('BracketRight', 'RightBracket', 'Oem6')
        bksl  = @('Backslash', 'Oem5')
        scln  = @('Semicolon', 'Oem1')
        apo   = @('Quote', 'Apostrophe', 'Oem7')
        comm  = @('Comma', 'OemComma')
        dot   = @('Period', 'Dot', 'OemPeriod')
        slash = @('Slash', 'Oem2')
        kprt  = @('PrintScreen', 'PrtSc', 'PrtScn', 'Snapshot', 'KPrt')
    }
}

function Get-KeyComboDictionary {
    <#
    .SYNOPSIS
        List the key-combo aliases understood by ConvertTo-KeyComboText.
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('All', 'Modifiers', 'Keys')]
        [string]$Category = 'All',
        [switch]$Raw
    )

    $categories = if ($Category -eq 'All') { @('Modifiers', 'Keys') } else { @($Category) }
    if ($Raw) {
        $rawDictionary = [ordered]@{}
        foreach ($name in $categories) { $rawDictionary[$name] = $script:KeyComboDictionary[$name] }
        return ,$rawDictionary
    }

    foreach ($name in $categories) {
        foreach ($canonical in $script:KeyComboDictionary[$name].Keys) {
            foreach ($alias in $script:KeyComboDictionary[$name][$canonical]) {
                [PSCustomObject]@{
                    Category  = $name
                    Canonical = $canonical
                    Alias     = $alias
                }
            }
        }
    }
}

function ConvertTo-KeyComboText {
    <#
    .SYNOPSIS
        Convert a ConsoleKeyInfo or chord string to searchable text.

    .DESCRIPTION
        PSReadLine gives key handlers a ConsoleKeyInfo object, while keyboard
        remappers such as Kanata commonly provide text such as C-S-p or
        Ctrl+Shift+p.  This cmdlet gives both forms one stable representation.
        Chords in a sequence may be separated with commas or `>`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [object]$InputObject
    )

    begin {
        $modifierAliases = @{}
        foreach ($canonical in $script:KeyComboDictionary.Modifiers.Keys) {
            foreach ($alias in $script:KeyComboDictionary.Modifiers[$canonical]) {
                $modifierAliases[$alias.ToLowerInvariant()] = $canonical
            }
        }
        $keyAliases = @{}
        foreach ($canonical in $script:KeyComboDictionary.Keys.Keys) {
            foreach ($alias in $script:KeyComboDictionary.Keys[$canonical]) {
                $keyAliases[$alias.ToLowerInvariant()] = $canonical
            }
        }

        $formatKeyInfo = {
            param([object]$Value)

            $key = $Value.Key
            $modifiers = [System.ConsoleModifiers]$Value.Modifiers
            $hasShift = [bool]($modifiers -band [System.ConsoleModifiers]::Shift)
            $parts = [System.Collections.Generic.List[string]]::new()
            if ($modifiers -band [System.ConsoleModifiers]::Control) { $parts.Add('Ctrl') }
            if ($modifiers -band [System.ConsoleModifiers]::Alt) { $parts.Add('Alt') }
            if ($hasShift) { $parts.Add('Shift') }

            $keyName = $key.ToString()
            switch -Regex ($keyName) {
                '^D([0-9])$' { $keyName = $Matches[1]; break }
                '^NumPad([0-9])$' { $keyName = "NumPad$($Matches[1])"; break }
                '^Oem' { break }
                default {
                    if ($keyName.Length -eq 1 -and $keyName -match '[A-Za-z]') {
                        $keyName = if ($hasShift) { $keyName.ToUpperInvariant() } else { $keyName.ToLowerInvariant() }
                    }
                }
            }
            $parts.Add($keyName)
            $parts -join '+'
        }

        $formatText = {
            param([string]$Value)

            $sequence = $Value.Trim() -replace '\s*->\s*', ',' -replace '\s*>\s*', ','
            $chords = $sequence -split '\s*,\s*' | Where-Object { $_ -and $_.Trim() }
            $events = foreach ($chord in $chords) {
                # Kanata logs can prefix an event with a timestamp, e.g. "120ms C-a".
                $chord = $chord.Trim() -replace '^\[?\d+(?:\.\d+)?\s*(?:ms|s)\]?\s+', ''
                $chord = $chord -replace '\s*\+\s*', '+'
                $chordParts = @($chord -split '\s+' | Where-Object { $_ })
                if ($chordParts.Count -gt 1 -and @($chordParts | Where-Object { $_ -match '[-+]' }).Count -eq $chordParts.Count) {
                    $chordParts
                }
                else {
                    $chord
                }
            }
            $normalized = foreach ($chord in $events) {
                $tokens = @($chord -split '\+')
                $parts = [System.Collections.Generic.List[string]]::new()
                for ($tokenIndex = 0; $tokenIndex -lt $tokens.Count; $tokenIndex++) {
                    $tokenValue = $tokens[$tokenIndex]
                    $token = $tokenValue.Trim()
                    if (-not $token) { continue }
                    # Kanata accepts chained prefixes such as C-S-p.
                    while ($true) {
                        $kanataMatch = [regex]::Match($token, '^(?<modifier>[CASMW])-+(?<key>.+)$', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
                        if (-not $kanataMatch.Success) { break }
                        $token = $kanataMatch.Groups['key'].Value
                        switch ($kanataMatch.Groups['modifier'].Value.ToUpperInvariant()) {
                            'C' { $parts.Add('ctrl') }
                            'A' { $parts.Add('alt') }
                            'M' { $parts.Add('meta') }
                            'S' { $parts.Add('shift') }
                            'W' { $parts.Add('meta') }
                        }
                    }
                    $isModifierPosition = $tokenIndex -lt ($tokens.Count - 1)
                    $modifierName = $modifierAliases[$token.ToLowerInvariant()]
                    if ($isModifierPosition -and $modifierName) {
                        $parts.Add($modifierName)
                        continue
                    }

                    $keyName = $keyAliases[$token.ToLowerInvariant()]
                    if ($keyName) {
                        $parts.Add($keyName)
                    }
                    elseif ($token -match '^oem(\d+)$') {
                        $parts.Add("Oem$($Matches[1])")
                    }
                    else {
                        $parts.Add($token)
                    }
                }

                $modifiers = @('ctrl', 'rctrl', 'meta', 'rmeta', 'alt', 'ralt', 'shift', 'rshift')
                $ordered = foreach ($modifier in $modifiers) {
                    $parts | Where-Object { $_ -eq $modifier } | Select-Object -First 1
                }
                $keyPart = $parts | Where-Object { $modifiers -notcontains $_ } | Select-Object -Last 1
                if ($keyPart) { @($ordered) + $keyPart -join '+' } else { $ordered -join '+' }
            }
            $normalized -join ', '
        }
    }
    process {
        if ($InputObject -is [System.ConsoleKeyInfo]) {
            & $formatKeyInfo $InputObject
            return
        }

        # PSReadLine's internal PSKeyInfo has the same Key/Modifiers shape.
        if ($InputObject.PSObject.Properties['Key'] -and $InputObject.PSObject.Properties['Modifiers']) {
            & $formatKeyInfo $InputObject
            return
        }

        & $formatText ([string]$InputObject)
    }
}

function Find-PSReadLineKeyBinding {
    <#
    .SYNOPSIS
        Search PSReadLine bindings by a normalized key-combo string.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Pattern,
        [System.ConsoleKeyInfo]$Key,
        [switch]$Exact
    )

    $query = if ($PSBoundParameters.ContainsKey('Key')) {
        ConvertTo-KeyComboText $Key
    }
    elseif ($PSBoundParameters.ContainsKey('Pattern')) {
        ConvertTo-KeyComboText $Pattern
    }
    else {
        ''
    }

    $queryParts = $query -split '\s*,\s*' | ForEach-Object { $_.ToLowerInvariant() }
    $handlers = @(Get-PSReadLineKeyHandler)
    foreach ($handler in $handlers) {
        $handlerKey = ConvertTo-KeyComboText ([string]$handler.Key)
        $handlerParts = $handlerKey -split '\s*,\s*' | ForEach-Object { $_.ToLowerInvariant() }
        $matches = if (-not $query) {
            $true
        }
        elseif ($Exact) {
            (@($handlerParts) -join ',') -eq (@($queryParts) -join ',')
        }
        else {
            $handlerParts -join ',' -like "*$($queryParts -join ',')*"
        }
        if ($matches) { $handler }
    }
}

function setAllHandler() {
    # INFO: custom default keyhandler.
    foreach ($handler in $HandlerParameters) {
        Set-PSReadLineKeyHandler @handler
    }
    # INFO: Add Vi Handler.
    $currentMode = (Get-PSReadLineOption).EditMode 

    # Customize the key bindings to your liking
    Set-PSReadLineKeyHandler -Key 'Ctrl+r' -BriefDescription 'FuzzyHistory' -ScriptBlock {
        if (-not $script:PoshFzfInitialized) {
            Invoke-Expression (&posh-fzf init | Out-String)
            $script:PoshFzfInitialized = $true
        }
        Invoke-PoshFzfSelectHistory
    }
    #Set-PSReadLineKeyHandler -Key 'Ctrl+t' -ScriptBlock { Invoke-PoshFzfSelectItems }
    #Set-PSReadLineKeyHandler -Key 'Alt+c' -ScriptBlock { Invoke-PoshFzfChangeDirectory }
    #Set-PSReadLineKeyHandler -Key 'Ctrl+r' -ScriptBlock { Invoke-TvShellHistory }
    Set-PSReadLineKeyHandler -Key 'Ctrl+t' -ScriptBlock { Invoke-TvSmartAutocomplete }
    Set-PSReadLineKeyHandler -Key 'Ctrl+Spacebar' -BriefDescription 'CompletePathOrFzf' -Description 'Complete paths, using fzf when the completion list is too large' -ScriptBlock {
        param($key, $arg)
        Invoke-PathCompletion -Key $key -Argument $arg
    }
    # PSReadLine normalizes Ctrl+Alt+Spacebar to Spacebar, so preserve plain-space behavior here.
    Set-PSReadLineKeyHandler -Key 'Ctrl+Alt+Spacebar' -BriefDescription 'CompleteDirectory' -Description 'Complete directories using the PSReadLine menu' -ScriptBlock {
        param($key, $arg)
        if (($key.Modifiers -band [ConsoleModifiers]::Control) -and
            ($key.Modifiers -band [ConsoleModifiers]::Alt)) {
            Invoke-DirectoryMenuComplete
        }
        elseif ((Get-PSReadLineOption).EditMode -eq 'Vi' -and
                -not [Microsoft.PowerShell.PSConsoleReadLine]::InViInsertMode()) {
            [Microsoft.PowerShell.PSConsoleReadLine]::ViForwardChar($key, $arg)
        }
        else {
            [Microsoft.PowerShell.PSConsoleReadLine]::SelfInsert($key, $arg)
        }
    }
    Add-DirectoryCompletionKeyMapping
    if ($currentMode -eq "Vi") {
        foreach ($handler in $ViHandlerParameters) {
            Set-PSReadLineKeyHandler @handler
        }
    }
}

function OptionsSwitch() {
    $currentMode = (Get-PSReadLineOption).EditMode 
    if ($currentMode -eq "Windows") {
        # Apply the key handler removals
        Set-PSReadLineOption @PSReadLineOptions_Vi        
        [Microsoft.PowerShell.PSConsoleReadLine]::ViCommandMode()
        foreach ($param in $ViHandlerRemoveParameters) {
            Remove-PSReadLineKeyHandler @param
        }
        Add-DirectoryCompletionKeyMapping
    }
    else {
        Set-PSReadLineOption @PSReadLineOptions_Windows
        Add-DirectoryCompletionKeyMapping
    }
}

# Configure editing bindings immediately; optional integrations initialize on use.
if (-not [Console]::IsInputRedirected -and -not [Console]::IsOutputRedirected) {
    Set-PSReadLineOption @PSReadLineOptions_Windows
    setAllHandler
}

# The shared key-combo commands are provided by quick.query through autoloading.
Export-ModuleMember -Function Invoke-PSReadLineWrapToken, Edit-PipedContent, Get-AvailableSpaceBelowPrompt, Invoke-TvSmartAutocomplete, Invoke-TvShellHistory, Invoke-DirectoryMenuComplete, Add-DirectoryCompletionKeyMapping, setAllHandler, OptionsSwitch
