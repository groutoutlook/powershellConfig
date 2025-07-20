function :q {
    Stop-Process -Id $pid
}
function :a {
    $old_dirs = Get-Location
    $old_pid = $pid
    if ($null -ne $args) {
        $tempdir = zq "$($args -join " ")"
        if ($tempdir -eq "$HOME\hw\obs") { $tempdir = $null }
    }
    if ($old_dirs.Path -ne $HOME) {
        $final_path = $tempdir ?? $old_dirs
        pwsh -Noexit -wd "$final_path" -Command "p7 && p7mod" 
    }
    else {
        pwsh -Noexit -wd "$HOME/hw/obs" -Command "p7 && p7mod" 
    }
    Stop-Process -Id $old_pid 
}

function :r {
    p7 && p7mod 
}

function :m {
    Restart-ModuleList
}

function :backup($Verbose = $null) {
    Import-Module -Name $env:dotfilesRepo\BackupModule.psm1
    Backup-Environment $Verbose && Backup-Extensive $Verbose
}
Set-Alias -Name :bak -Value :backup
# NOTE: neovim trigger function.
function :v {
    if ($args[$args.Length - 1] -eq "g") {
        # "^gui")
        $codeEditor = "neovide --frame none -- "
        $parsedArgs = $args[0..($args.Length - 2)]
    }
    else {
        $codeEditor = "nvim"
        $parsedArgs = $args
    }
  
    $parsedArgs = @($parsedArgs | ForEach-Object { 
            $_ -split ":", "" -split " ", "" 
        })
    # echo ($parsedArgs).Psobject
    # INFO: check if more than 2 elements and final element is number, then modify.
    # I havent thought of a better deal right now.
    if ($parsedArgs.Count -ge 2 -and $parsedArgs[-1] -match "^\d+") {
        if ($parsedArgs[0] -eq "") {
            $parsedArgs[0] = $null
        }
        $finalIndex = $parsedArgs.Count - 2
        $lineNumber = ($Matches.Values)

        if ($parsedArgs[0] -match "^\p{L}$") {
            $parsedArgs[0] = $parsedArgs[0] + ":" + $parsedArgs[1]
            $parsedArgs[1] = $null
            $processedArgs = `
                "`"$($parsedArgs[0..$finalIndex] -join ' ')`""                              `
                + " +" + "$lineNumber" 
        }
        else {
            $processedArgs = `
                "`"$($parsedArgs[0..$finalIndex] -join ' ')`""                              `
                + " +" + "$lineNumber"
        }
        # echo ($processedArgs).Psobject
    }
    else {
        $processedArgs = $parsedArgs[0]
    }

    if ($null -eq $processedArgs ) {
        Invoke-Expression "$codeEditor ." # -c "lua require('resession')" -c "call feedkeys(`"<leader>..`")"
    }
    else {
        if ($processedArgs -match "^ls") {
            Invoke-Expression "$codeEditor -c `"lua require('resession').load()`""
        }
        elseif ($processedArgs -match "^last") {
            Invoke-Expression "$codeEditor -c `"lua require('resession').load 'Last Session'`""
        }
        else {
            Invoke-Expression "$codeEditor $processedArgs" # -c "lua require('resession')" -c "call feedkeys(`"<leader>..`")"
        }
    }

}
function :vl {
    :v last "$args"
}

# INFO: Quick pwsh_profiles session. better checkout [root dir]($env:LOCALAPPDATA\nvim-data\session)
# Fall back to default symlink on highway if it's not the complex `nvim`
$sessionMap = @{
    "pw"  = "pwsh"
    "nv"  = "nvim"
    "nu"  = "nushell"
    "es"  = "espanso"
    "ob"  = "obsidian"
    "m"   = "mouse"
    "k"   = "kanata"
    "ka"  = "kanata"
    "vk"  = "vulkan-samples"
    "wts" = "wt_shader"
}
function :vs {
    if ($null -eq $args[0]) {
        $inputString = "pw"  
    }
    else {
        $inputString = $args[0]
    }
    $processedString = $sessionMap[$inputString]
  
    if ($null -eq $processedString) {
        Write-Host "What do you want?" -ForegroundColor Yellow
        # :v ls "$args"
        :vl
    }
    else {
        if ($null -eq $env:nvim_appname) {
            # $codeEditor = "neovide --frame none -- "
            $codeEditor = "nvim"
            Invoke-Expression "$codeEditor -c `"lua require('resession').load '$processedString'`""
        }
        else {
            Invoke-Expression "$env:EDITOR ~/hw/$processedString"
        }
    } 
}

# TODO: one day I will try to make them parse the yaml text instead of this clunky hash table.
# HACK: As today I could `Get-UniqueEntryJrnl table | Set-Clipboard`
$global:vaultName = "MainVault"
$global:vaultPath = "D://ProgramDataD//Notes//Obsidian//$vaultName"
$JrnlTable = @{
    "emb"      = "$vaultPath//note_Embedded//FirmwareJournal.md"
    "draw"     = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "viap"     = "$vaultPath//note_Embedded//PCB_Standard//PCBJournal.md"
    "peo"      = "$vaultPath//note_Business//ConnectionJournal.md"
    "cve"      = "$vaultPath//note_algo_lang//Info.Security.Journal.md"
    "vid"      = "$vaultPath//note_entertainment//VideoJournal.md"
    "pp"       = "$vaultPath//note_Business//ConnectionJournal.md"
    "vul"      = "$vaultPath//note_algo_lang//GraphicUIJournal.md"
    "api"      = "$vaultPath//note_algo_lang//LibraryJournal.md"
    "book"     = "$vaultPath//note_Knowledge//ReadAndListenJournal.md"
    "swt"      = "$vaultPath//note_software//TUI.Terminal.Software.Journal.md"
    "lhack"    = "$vaultPath//note_Knowledge//LifeHackJournal.md"
    ":3"       = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "lang"     = "$vaultPath//note_algo_lang//LangJournal.md"
    "inte"     = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "mech"     = "$vaultPath//note_IDEAndTools//CADJournal.md"
    "daily"    = "$vaultPath//note_entertainment//Diary.Journal.md"
    "webui"    = "$vaultPath//note_os_web//UIJournal.md"
    "infosec"  = "$vaultPath//note_algo_lang//Info.Security.Journal.md"
    "people"   = "$vaultPath//note_Business//ConnectionJournal.md"
    "firm"     = "$vaultPath//note_Embedded//FirmwareJournal.md"
    ":1688"    = "$vaultPath//note_Items//1688Journal.md"
    "ety"      = "$vaultPath//note_Knowledge//PhraseJournal.md"
    "fcad"     = "$vaultPath//note_IDEAndTools//CADJournal.md"
    "blog"     = "$vaultPath//note_Knowledge//ReadAndListenJournal.md"
    "tip"      = "$vaultPath//note_Knowledge//LifeHackJournal.md"
    "wfr"      = "$vaultPath//note_os_web//SDK-Framework.Web.Journal.md"
    "video"    = "$vaultPath//note_entertainment//VideoJournal.md"
    "blend"    = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "ee"       = "$vaultPath//note_Embedded//Electric.Journal.md"
    "build"    = "$vaultPath//note_algo_lang//ProgrammingJournal.md"
    "econ"     = "$vaultPath//note_Knowledge//EconomyJournal.md"
    "bs"       = "$vaultPath//note_Business//WorkJournal.md"
    "swgui"    = "$vaultPath//note_software//GUI.Software.Journal.md"
    "ic"       = "$vaultPath//note_Embedded//ChipsetJournal.md"
    "stm"      = "$vaultPath//note_Embedded//FirmwareJournal.md"
    "graph"    = "$vaultPath//note_algo_lang//GraphicUIJournal.md"
    "wasm"     = "$vaultPath//note_os_web//WebProgJournal.md"
    "diary"    = "$vaultPath//note_entertainment//Diary.Journal.md"
    "web"      = "$vaultPath//note_software//WebJournal.md"
    "acro"     = "$vaultPath//note_Knowledge//AcronymJournal.md"
    "cad"      = "$vaultPath//note_IDEAndToolsCADJournal.md"
    "pol"      = "$vaultPath//note_Knowledge//NewsJournal.md"
    "math"     = "$vaultPath//note_algo_lang//STEMJournal.md"
    "self"     = "$vaultPath//note_entertainment//PersonalJournal.md"
    "gpu"      = "$vaultPath//note_algo_lang//GraphicUIJournal.md"
    "file"     = "$vaultPath//note_IDEAndTools//File-Format.Journal.md"
    "three"    = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "hack"     = "$vaultPath//note_Knowledge//LifeHackJournal.md"
    "ms"       = "$vaultPath//note_entertainment//MusicJournal.md"
    "comp"     = "$vaultPath//note_Embedded//ComponentJournal.md"
    "fw"       = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
    "cl"       = "$vaultPath//note_software//CLI.Terminal.Software.Journal.md"
    "asset"    = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "mcu"      = "$vaultPath//note_Embedded//MCU.IC.Journal.md"
    "proto"    = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "rule"     = "$vaultPath//note_Business//WorkflowJournal.md"
    "wire"     = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "come"     = "$vaultPath//note_Knowledge//WholesomeJournal.md"
    "embed"    = "$vaultPath//note_Embedded//FirmwareJournal.md"
    "stem"     = "$vaultPath//note_algo_lang//STEMJournal.md"
    "linux"    = "$vaultPath//note_software//OSJournal.md"
    "social"   = "$vaultPath//note_Business//ConnectionJournal.md"
    "soft"     = "$vaultPath//note_software//SoftwareJournal.md"
    "hw"       = "$vaultPath//note_Embedded//HardwareJournal.md"
    "soc"      = "$vaultPath//note_Embedded//ChipsetJournal.md"
    "life"     = "$vaultPath//note_Knowledge//LifeJournal.md"
    "ltip"     = "$vaultPath//note_Knowledge//LifeHackJournal.md"
    "like"     = "$vaultPath//note_entertainment//PersonalJournal.md"
    "sdk"      = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
    "psy"      = "$vaultPath//note_Knowledge//LifeJournal.md"
    "lib"      = "$vaultPath//note_algo_lang//LibraryJournal.md"
    "eco"      = "$vaultPath//note_Knowledge//EconomyJournal.md"
    "wf"       = "$vaultPath//note_Business//WorkflowJournal.md"
    "gsw"      = "$vaultPath//note_software//GUI.Software.Journal.md"
    "laugh"    = "$vaultPath//note_Knowledge//WholesomeJournal.md"
    "style"    = "$vaultPath//note_Business//WorkflowJournal.md"
    "other"    = "$vaultPath//note_Knowledge//OtherKnowledgeJournal.md"
    "eda"      = "$vaultPath//note_Embedded//note_EDA//EDAJournal.md"
    "interest" = "$vaultPath//note_entertainment//PersonalJournal.md"
    "net"      = "$vaultPath//note_algo_lang//Network.Journal.md"
    "wapi"     = "$vaultPath//note_os_web//WebAPIJournal.md"
    "os"       = "$vaultPath//note_software//OSJournal.md"
    "fr"       = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
    "model"    = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "physic"   = "$vaultPath//note_algo_lang//STEMJournal.md"
    "oic"      = "$vaultPath//note_Embedded//Others.IC.Journal.md"
    "wfw"      = "$vaultPath//note_os_web//SDK-Framework.Web.Journal.md"
    "bus"      = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "busy"     = "$vaultPath//note_Business//WorkJournal.md"
    "nw"       = "$vaultPath//note_algo_lang//Network.Journal.md"
    "quote"    = "$vaultPath//note_Knowledge//QuoteJournal.md"
    "til"      = "$vaultPath//note_Knowledge//OtherKnowledgeJournal.md"
    "frame"    = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
    "pger"     = "$vaultPath//note_Business//ConnectionJournal.md"
    "ev"       = "$vaultPath//note_Knowledge//EventJournal.md"
    "pw"       = "$vaultPath//note_Knowledge//secret//AccountJournal.md"
    "qt"       = "$vaultPath//note_Knowledge//QuoteJournal.md"
    "freecad"  = "$vaultPath//note_IDEAndTools//CADJournal.md"
    "pcb"      = "$vaultPath//note_Embedded//PCB_Standard//PCBJournal.md"
    "sw"       = "$vaultPath//note_software//SoftwareJournal.md"
    "sec"      = "$vaultPath//note_algo_lang//Info.Security.Journal.md"
    "csci"     = "$vaultPath//note_algo_lang//CompSciJournal.md"
    "edit"     = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "windows"  = "$vaultPath//note_software//OSJournal.md"
    "module"   = "$vaultPath//note_Embedded//ChipsetJournal.md"
    "pic"      = "$vaultPath//note_Embedded//Passive.IC.Journal.md"
    "per"      = "$vaultPath//note_entertainment//PersonalJournal.md"
    "idea"     = "$vaultPath//note_Business//IdeaJournal.md"
    "pers"     = "$vaultPath//note_entertainment//PersonalJournal.md"
    "task"     = "$vaultPath//note_Business//WorkJournal.md"
    "ecad"     = "$vaultPath//note_Embedded//note_EDA//EDAJournal.md"
    "etym"     = "$vaultPath//note_Knowledge//PhraseJournal.md"
    "isec"     = "$vaultPath//note_algo_lang//Info.Security.Journal.md"
    "workflow" = "$vaultPath//note_Business//WorkflowJournal.md"
    "vc"       = "$vaultPath//note_Knowledge//VocabJournal.md"
    "elec"     = "$vaultPath//note_Embedded//Electric.Journal.md"
    "chip"     = "$vaultPath//note_Embedded//ChipsetJournal.md"
    "default"  = "$vaultPath//MainJournal.md"
    "slang"    = "$vaultPath//note_Knowledge//PhraseJournal.md"
    "acc"      = "$vaultPath//note_Knowledge//secret//AccountJournal.md"
    ":3d"      = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "news"     = "$vaultPath//note_Knowledge//NewsJournal.md"
    "ui"       = "$vaultPath//note_os_web//UIJournal.md"
    "wlib"     = "$vaultPath//note_os_web//WebAPIJournal.md"
    "money"    = "$vaultPath//note_Business//MoneyJournal.md"
    "pcba"     = "$vaultPath//note_Embedded//PCB_Standard//PCBJournal.md"
    "swg"      = "$vaultPath//note_software//GUI.Software.Journal.md"
    "gui"      = "$vaultPath//note_software//GUI.Software.Journal.md"
    "html"     = "$vaultPath//note_os_web//UIJournal.md"
    "tu"       = "$vaultPath//note_software//TUI.Terminal.Software.Journal.md"
    "wpro"     = "$vaultPath//note_os_web//WebProgJournal.md"
    "wui"      = "$vaultPath//note_os_web//UIJournal.md"
    "cash"     = "$vaultPath//note_Business//MoneyJournal.md"
    "taobao"   = "$vaultPath//note_Items//TaobaoJournal.md"
    "vocab"    = "$vaultPath//note_Knowledge//VocabJournal.md"
    "new"      = "$vaultPath//note_Knowledge//NewsJournal.md"
    "phr"      = "$vaultPath//note_Knowledge//PhraseJournal.md"
    "prot"     = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "vk"       = "$vaultPath//note_algo_lang//GraphicUIJournal.md"
    "myrule"   = "$vaultPath//note_Business//WorkflowJournal.md"
    "place"    = "$vaultPath//note_Knowledge//PlacesJournal.md"
    "netw"     = "$vaultPath//note_algo_lang//Network.Journal.md"
    "conn"     = "$vaultPath//note_Business//ConnectionJournal.md"
    "cs"       = "$vaultPath//note_algo_lang//CompSciJournal.md"
    "tui"      = "$vaultPath//note_software//TUI.Terminal.Software.Journal.md"
    "cli"      = "$vaultPath//note_software//CLI.Terminal.Software.Journal.md"
    ":1"       = "$vaultPath//note_Items//1688Journal.md"
    "fiw"      = "$vaultPath//note_Embedded//FirmwareJournal.md"
    "itf"      = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "cad3d"    = "$vaultPath//note_IDEAndTools//CADJournal.md"
    "media"    = "$vaultPath//note_Knowledge//NewsJournal.md"
    "ali"      = "$vaultPath//note_Items//1688Journal.md"
    "ide"      = "$vaultPath//note_IDEAndTools//IDE.Journal.md"
    "music"    = "$vaultPath//note_entertainment//MusicJournal.md"
    "wsdk"     = "$vaultPath//note_os_web//SDK-Framework.Web.Journal.md"
    "fi"       = "$vaultPath//note_Embedded//FirmwareJournal.md"
    "fm"       = "$vaultPath//note_IDEAndTools//File-Format.Journal.md"
    "art"      = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "day"      = "$vaultPath//note_entertainment//Diary.Journal.md"
    "is"       = "$vaultPath//note_algo_lang//Info.Security.Journal.md"
    "humor"    = "$vaultPath//note_Knowledge//WholesomeJournal.md"
    "hard"     = "$vaultPath//note_Embedded//HardwareJournal.md"
    "event"    = "$vaultPath//note_Knowledge//EventJournal.md"
    "prog"     = "$vaultPath//note_algo_lang//ProgrammingJournal.md"
    "swc"      = "$vaultPath//note_software//CLI.Terminal.Software.Journal.md"
    "meme"     = "$vaultPath//note_Knowledge//WholesomeJournal.md"
    "kicad"    = "$vaultPath//note_Embedded//note_EDA//EDAJournal.md"
    "wprog"    = "$vaultPath//note_os_web//WebProgJournal.md"
    "read"     = "$vaultPath//note_Knowledge//ReadAndListenJournal.md"
    "phrase"   = "$vaultPath//note_Knowledge//PhraseJournal.md"
    "uiweb"    = "$vaultPath//note_os_web//UIJournal.md"
    "work"     = "$vaultPath//note_Business//WorkJournal.md"
    "gra"      = "$vaultPath//note_algo_lang//GraphicUIJournal.md"
    "item"     = "$vaultPath//note_Items//OtherItemsJournal.md"
}

# NOTE: Obsidian trigger function.
# TODO: might as well implemented workspace open (Advanced)URI and something extreme.
function :obsidian(
    [Parameter(Mandatory = $false)]
    [System.String[]]
    [Alias("s")]
    $String
) {
    if ($null -eq $string) {
        Show-Window Obsidian
        return
    }
    else {
        $inputString = $String[0]
        $phrase = $JrnlTable[$inputString]
        if ($phrase -eq $null) {
            # Second chance to match the phrase.
      
            if (($inputString -match "j$") -or ($inputString -match " $")) {
                $clippedPhrase = $inputString -replace " $" -replace "j$" 
                $phrase = $JrnlTable[$clippedPhrase]
            }
        } 

        if ($phrase -eq $null) {
            omniSearchObsidian "$($String -join ' ')" | Out-Null
        }
        else {
            ((Start-Process "obsidian://open?path=$phrase")  &) | Out-Null
        }
    }
}

# # INFO: switch workspace.
# $workspaceNameTable = @{
#     "j"  = "Journal-code-eda"
#     "jc" = "Journal-code-eda"
#     "o"  = "Obs-Nvim"
#     "on" = "Obs-Nvim"
# }
# function :ow {
#     $defaultWorkspace = "Obs-Nvim"
#
#     # Prepare arguments  
#     $argument = $args -join " "
#     $workspaceName = $workspaceNameTable[$argument] ?? "$defaultWorkspace"
#
#     $originalURI = "obsidian://advanced-uri?vault=$global:vaultName&workspace=$workspaceName" 	
#     (Start-Process "$originalURI" &) | Out-Null
# }
#
Set-Alias -Name :o -Value :obsidian
# Set-Alias -Name :oo -Value obsidian-cli

# TODO: make the note taking add the #tag on it. so I could enter the note and start wrting on it right away without adding tag.
function :jrnl {
    $argument = $args
    if ($argument.Count -eq 0) {
        & jrnl
        return
    }
    $argLast = $argument[-1]
    switch -Regex ($argLast) {
        "^\d+$" {
            $matchValue = $_
            $argument[-1] = " -$matchValue"
        }
        "^last|^lt" {
            $day = [regex]::Match($argLast, "\d*$").Value
            if ($day -eq "") { $day = 2 }
            else { $day = [int]$day }
            $fromDate = (Get-Date).AddDays(-$day)
            $trimDate = Get-Date $fromDate -Format "yyyy/MM/dd"
            $argument[-1] = " -from $trimDate"
        }
        "^tg|^tag" {
            Write-Output "TAGGGG Work."
            # Additional logic for tags can be added here if needed
        }
        "^\d+e" {
            $matchValue = [regex]::Match($argLast, "^\d+").Value
            $argument[-1] = " -$matchValue --edit"
        }
        "^\d+d" {
            $matchValue = [regex]::Match($argLast, "^\d+").Value
            $argument[-1] = " -$matchValue --delete"
        }
    }
    Invoke-Expression "jrnl $argument"

}
Set-Alias -Name j -Value :jrnl

# INFO: call `Get-UniqueEntryJrnl table` to get current jrnltable list.
function Get-UniqueEntryJrnl {
    $jrnlYamlPath = "~/.config/jrnl/jrnl.yaml"
    # INFO : Import a heavy specialized module here for YAML processing. 
    Import-Module powershell-yaml  
    #[System.Collections.ArrayList]$ResultList = @()
    $all_list = @()
    $os_list = ConvertFrom-Yaml -Yaml (Get-Content -Raw $jrnlYamlPath)
    $initial_keys_list = $os_list.journals.Keys

    # HACK: Convert / or // to \ in journal paths for Windows compatibility
    $final_dir = $os_list.journals.Values.Values | Where-Object { $_ -match "~[\\/]+hw[\\/]+obs[\\/]*" } | ForEach-Object { $_ -replace "~[\\/]+hw[\\/]+obs[\\/]*", "`$vaultPath//" -replace '[\\/]+', '//' }
    # $final_dir = $os_list.journals.Values.Values | Where-Object {$_ -match "~/hw/obs"}
    # INFO: Could also create a hashTable of keys and value here.
    if ($args[0] -match "^table") {
        $myHash = @{}
        $initial_keys_list | ForEach-Object -Begin { $i = 0 } -Process {
            $myHash["`'$_`'"] = "`'$($final_dir[$i])`'"
            $i++
        }
        return $myHash  | ConvertTo-Yaml | % { $_ -replace "'", "" -replace '": "', '"= "' }
    }
  
    $final_dir = $final_dir | Sort-Object | Get-Unique
    [System.Collections.ArrayList]$finalDir = $final_Dir
    foreach ($shortName in $initial_keys_list) {
        $matchedPath = $os_list.journals[$shortName].Journal
        if ($matchedPath -in $finalDir) {
            $finalDir.Remove($matchedPath)
            if ($shortName -ne "acc") {
                $all_list += $shortName
            }
        }
    }
    return $all_list
}
# NOTE: Espanso powershell wrapper.
$espansoAlias = @{
    "st" = "status"
    "e"  = "editInNvimSession"
}

function :e {
    $argument = ""
    # Prepare arguments 
    $defaultArgs = $espansoAlias["e"]
    if ($args.Length -eq 0) {
        $argument = "$defaultArgs "
    }
    else {
        foreach ($arg in $args) {
            $postProcessArgument = $espansoAlias[$arg] ?? $arg 
            $argument += "$postProcessArgument "
        }
    }
    if ($argument -eq "$defaultArgs ") {
        $espansoNvimSession = "espanso"
        $codeEditor = "neovide --frame none -- "
        Invoke-Expression "$codeEditor -c 'lua require(`"resession`").load `"$espansoNvimSession`"'"
    }
    else {
        Invoke-Expression "espanso $argument"
    }
}

# INFO: function to switch between applications. Right now it's based on the Show-Window function.
function :s {
    Show-Window "$args"
}
function :k {
    if ($args.Length -eq 0) {
        kanata --help
    }
    else {
        $dashArgs = ($args | Where-Object { $_ -like '-*' }) -join " "
        $pureStringArgs = ($args | Where-Object { $_ -notlike '-*' }) -join " "
        Invoke-Expression "kanata $pureStringArgs $dashArgs"
    }
}
