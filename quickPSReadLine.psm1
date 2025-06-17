using namespace System.Console
using namespace System.Management.Automation
using namespace System.Management.Automation.Language
# $RLModule = [Microsoft.PowerShell.PSConsoleReadLine]
$ggSearchParameters = @{
    Key              = 'Ctrl+s'
    BriefDescription = 'Web Search Mode'
    LongDescription  = 'Maybe other search function, but who knows.'
    ScriptBlock      = {
        param($key, $arg)
        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        
        $searchFunction = "Search-DuckDuckGo" 
        $SearchWithQuery = ""
        if ($line -match "[a-z]") {
            $SearchWithQuery = "$searchFunction $line"
        }
        else {
            $SearchWithQuery = "$searchFunction $(Get-History -Count 1)"
        }

        $process_string = {
        param($line)

        }

        [Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory($line)
        Invoke-Expression $SearchWithQuery
    }
}

$VaultSearchParameters = @{
    Key              = 'Ctrl+shift+s'
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
        $existedCd = "cd|z|zq"
        switch -Regex ($line) {
            "^(${existedCd})i\s" {
                $matchString = $Matches[0]
                $SearchWithQuery = $line -replace "${matchString}", "zz "
                break;
            }
            "^(${existedCd})(\s|$)" {
                $matchString = $Matches[1]
                $SearchWithQuery = $line -replace "^${matchString}(\s|$)", "${matchString}i "
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
    # Key              = 'Ctrl+shift+z'
    Key              = 'alt+x'
    BriefDescription = 'Quick zoxide Mode'
    LongDescription  = 'quick zoxide opened.'
    ScriptBlock      = $quickZoxide
}

$QuickZoxide_2_Parameters = @{
    Key              = 'Ctrl+shift+z'
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
    

        Get-Content -Tail 200 (Get-PSReadLineOption).HistorySavePath `
        | Select-String -Pattern '^j\s+(?:\w|\:)' `
        | fzf --query '^j ' `
        | ForEach-Object { $finalOptions = $_ + " $($defaultValue)e" }

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

# $cdHandlerParameters = @{
#   Key = 'Alt+x'
#   BriefDescription = 'Set-LocationWhere the paste directory.'
#   LongDescription = 'Invoke cdwhere with the current directory in the command line'
#   ScriptBlock = {
#     param($key, $arg)   # The arguments are ignored in this example
#
#     # GetBufferState gives us the command line (with the cursor position)
#     $line = $null
#     $cursor = $null
#     [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line,
#       [ref]$cursor)
#     $invokeFunction = "Set-LocationWhere"
#     $Query = "$invokeFunction `'$line`'"
#     #Store to history for future use.
#
#     [Microsoft.PowerShell.PSConsoleReadLine]::BeginningOfLine()
#     [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$invokeFunction `'")
#     [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
#     [Microsoft.PowerShell.PSConsoleReadLine]::Insert("`'")
#     # [Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory($Query)
#     #Store to history for future use.
#     # Can InvertLine() here to return empty line.
#     [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
#       
#   }
# }
#



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
        if ($line -match '^rg') {
            # INFO: Replace could actually increase the length of original strings.
            # So I could be longer than the start.
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, 2, "ig")
        }
        else {
            # INFO: check history for the latest match commands
            $SearchWithQuery = Get-History -Count 40 `
            | Sort-Object -Property Id -Descending `
            | Where-Object { $_.CommandLine -match "^rg" }
            | Select-Object -Index 0 `

            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($SearchWithQuery)
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, 2, "ig")
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

        # GetBufferState gives us the command line (with the cursor position)
        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line,
            [ref]$cursor)
        $invokeFunction = "Invoke-SudoPwsh"
        if ($line -match "[a-z]") {
            $invokeCommand = "$invokeFunction `"$line`""
        }
        else {
            $invokeCommand = "$invokeFunction `"$(Get-History -Count 1)`""
        }

        # Invoke-Expression $invokeCommand
    
        # HACK: Just revert the line and brute force printing the line again in console.
        # Ugly way but worked.
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::BeginningOfLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$invokeCommand")
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
      
    }
}


# HACK: combine both Bakwardkillword and forwardkillword(alt+D) 
$smartKillWordParameters = @{
    Key              = 'Ctrl+w'
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


## HACK: combine both Bakwardkillword and forwardkillword(alt+D) 
$ExtraKillWordParameters = @{
    Key              = 'Ctrl+Backspace'
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
    Key              = 'Alt+w'
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
    Key              = 'ctrl+b'
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

        $pipeAll = "*>&1 | b"
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

        $selectionStart = $null
        $selectionLength = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        if ($selectionStart -ne -1) {
            $selectedText = $line.SubString($selectionStart, $selectionLength)
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, "($selectedText)")
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
                [Microsoft.PowerShell.PSConsoleReadLine]::Replace($start, $length, "($text)")
                [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($start + $length + 1)
            }
            else {
                # Fallback: insert () at cursor
                [Microsoft.PowerShell.PSConsoleReadLine]::Insert('()')
                [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
            }
        }
    }
}

$ParenthesesAllParameter = @{
    Key              = 'Alt+9'
    BriefDescription = 'parentheses all or the selection'
    LongDescription  = 'Wraps the selected text or the entire line in parentheses.'
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
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, "($selectedText)")
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
        }
        else {
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, "($line)")
            [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
        }
    }
}

$DoubleQuotesParameter = @{
    Key              = "Alt+'"
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


$WrapPipeParameter = @{
    Key              = 'Alt+\'
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

$ctrlBracket_Parameters = @{
    # HACK: on the key code, using [System.Console]::ReadKey() -> `[` as Oem4.
    Key              = 'ctrl+Oem4'
    BriefDescription = 'ctrl+['
    LongDescription  = 'This is only included when in ViMode,in command(normal) mode'
    ViMode           = "Insert"
    ScriptBlock      = {
        param($key, $arg)   
        [Microsoft.PowerShell.PSConsoleReadLine]::ViCommandMode()
    }
}
# INFO: Common Windows/Vi Mode Key handlers
$HandlerParameters = @(
    $ggSearchParameters
    , $VaultSearchParameters
    , $QuickZoxideParameters
    , $QuickZoxide_2_Parameters
    , $omniSearchParameters
    , $JrnlParameters 
    , $HistorySearchGlobalParameters
    , $sudoRunParameters
    , $smartKillWordParameters
    , $ExtraKillWordParameters
    , $ExtraKillWord1Parameters
    , $ParenthesesParameter
    , $ParenthesesAllParameter
    , $DoubleQuotesParameter
    , $DoubleQuotesNestedBracketParameter
    , $wrappipeparameter
    , $rgToNvimParameters
    , $rgToRggParameters
    , $IterateCommandParameters
    , $OptionsSwitchParameters
    , $openEditorParameters
    , $GlobalEditorSwitch
    , $MathExpressionParameter
    , $helpParameter
)
# INFO: Unique for Vi mode.
$ViHandlerParameters = @(
    $OptionsSwitch_Command_Parameters
    , $twoKeyEscape_k_Parameters 
    , $twoKeyEscape_j_Parameters 
    , $ctrlBracket_Parameters
)
# INFO: Default of Windows PSReadLineOptions
$PSReadLineOptions_Windows = @{
    EditMode                      = "Windows"
    HistoryNoDuplicates           = $true
    HistorySearchCursorMovesToEnd = $true
    PredictionViewStyle           = "ListView"
    Colors                        = @{
        "Command" = "#f9f1a5"
    }
}

$PSReadLineOptions_Vi = @{
    EditMode                      = "Vi"
    HistoryNoDuplicates           = $true
    HistorySearchCursorMovesToEnd = $true
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

function setAllHandler() {
    # INFO: custom default keyhandler.
    foreach ($handler in $HandlerParameters) {
        Set-PSReadLineKeyHandler @handler
    }
    # INFO: Add Vi Handler.
    $currentMode = (Get-PSReadLineOption).EditMode 
    if ($currentMode -eq "Vi") {
        foreach ($handler in $ViHandlerParameters) {
            Set-PSReadLineKeyHandler @handler
        }
        Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r' -TabExpansion -AltCCommand $null
        Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }
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
    }
    else {
        Set-PSReadLineOption @PSReadLineOptions_Windows
    }
}

# HACK: preset of the initial settings.
Set-PSReadLineOption @PSReadLineOptions_Windows
setAllHandler
