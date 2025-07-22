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
    "net"         = "$vaultPath//note_algo_lang//Network.Journal.md"
    "embed"       = "$vaultPath//note_Embedded//FirmwareJournal.md"
    "hard"        = "$vaultPath//note_Embedded//HardwareJournal.md"
    "per"         = "$vaultPath//note_entertainment//PersonalJournal.md"
    "swc"         = "$vaultPath//note_software//CLI.Terminal.Software.Journal.md"
    "inte"        = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "fm"          = "$vaultPath//note_IDEAndTools//File-Format.Journal.md"
    "tip"         = "$vaultPath//note_Knowledge//LifeHackJournal.md"
    "ic"          = "$vaultPath//note_Embedded//ChipsetJournal.md"
    "news"        = "$vaultPath//note_Knowledge//NewsJournal.md"
    "viap"        = "$vaultPath//note_Embedded//PCBJournal.md"
    "blog"        = "$vaultPath//note_Knowledge//ReadAndListenJournal.md"
    "cash"        = "$vaultPath//note_Business//MoneyJournal.md"
    "vul"         = "$vaultPath//note_algo_lang//GraphicUIJournal.md"
    "cs"          = "$vaultPath//note_algo_lang//CompSciJournal.md"
    "buildsystem" = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
    "firm"        = "$vaultPath//note_Embedded//FirmwareJournal.md"
    "task"        = "$vaultPath//note_Business//WorkJournal.md"
    "os"          = "$vaultPath//note_software//OSJournal.md"
    "rule"        = "$vaultPath//note_Business//WorkflowJournal.md"
    "video"       = "$vaultPath//note_entertainment//VideoJournal.md"
    "fi"          = "$vaultPath//note_Embedded//FirmwareJournal.md"
    "tui"         = "$vaultPath//note_software//TUI.Terminal.Software.Journal.md"
    "three"       = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "freecad"     = "$vaultPath//note_IDEAndTools//CADJournal.md"
    "ms"          = "$vaultPath//note_entertainment//MusicJournal.md"
    "backend"     = "$vaultPath//note_os_web//Server.Network.Journal.md"
    "kicad"       = "$vaultPath//note_Embedded//EDAJournal.md"
    "cad3d"       = "$vaultPath//note_IDEAndTools//CADJournal.md"
    "laugh"       = "$vaultPath//note_Knowledge//WholesomeJournal.md"
    "frontend"    = "$vaultPath//note_os_web//UIJournal.md"
    "physic"      = "$vaultPath//note_algo_lang//STEMJournal.md"
    "vid"         = "$vaultPath//note_entertainment//VideoJournal.md"
    "bus"         = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "oic"         = "$vaultPath//note_Embedded//Others.IC.Journal.md"
    "conn"        = "$vaultPath//note_Business//ConnectionJournal.md"
    "isec"        = "$vaultPath//note_algo_lang//Info.Security.Journal.md"
    "asset"       = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "wsdk"        = "$vaultPath//note_os_web//SDK-Framework.Web.Journal.md"
    "sv"          = "$vaultPath//note_os_web//Server.Network.Journal.md"
    "soft"        = "$vaultPath//note_software//SoftwareJournal.md"
    "vc"          = "$vaultPath//note_Knowledge//VocabJournal.md"
    "wui"         = "$vaultPath//note_os_web//UIJournal.md"
    "lhack"       = "$vaultPath//note_Knowledge//LifeHackJournal.md"
    "like"        = "$vaultPath//note_entertainment//PersonalJournal.md"
    "nw"          = "$vaultPath//note_algo_lang//Network.Journal.md"
    "sec"         = "$vaultPath//note_algo_lang//Info.Security.Journal.md"
    "ltip"        = "$vaultPath//note_Knowledge//LifeHackJournal.md"
    "acro"        = "$vaultPath//note_Knowledge//AcronymJournal.md"
    "fcad"        = "$vaultPath//note_IDEAndTools//CADJournal.md"
    "linux"       = "$vaultPath//note_software//OSJournal.md"
    "pol"         = "$vaultPath//note_Knowledge//NewsJournal.md"
    "people"      = "$vaultPath//note_Business//ConnectionJournal.md"
    "fr"          = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
    "humor"       = "$vaultPath//note_Knowledge//WholesomeJournal.md"
    "ee"          = "$vaultPath//note_Embedded//Electric.Journal.md"
    "wf"          = "$vaultPath//note_Business//WorkflowJournal.md"
    "fiw"         = "$vaultPath//note_Embedded//FirmwareJournal.md"
    "pers"        = "$vaultPath//note_entertainment//PersonalJournal.md"
    "tu"          = "$vaultPath//note_software//TUI.Terminal.Software.Journal.md"
    "hack"        = "$vaultPath//note_Knowledge//LifeHackJournal.md"
    "etym"        = "$vaultPath//note_Knowledge//PhraseJournal.md"
    "eda"         = "$vaultPath//note_Embedded//EDAJournal.md"
    "new"         = "$vaultPath//note_Knowledge//NewsJournal.md"
    "csci"        = "$vaultPath//note_algo_lang//CompSciJournal.md"
    "ali"         = "$vaultPath//note_Items//1688Journal.md"
    "mcu"         = "$vaultPath//note_Embedded//MCU.IC.Journal.md"
    "gra"         = "$vaultPath//note_algo_lang//GraphicUIJournal.md"
    "sw"          = "$vaultPath//note_software//SoftwareJournal.md"
    "infosec"     = "$vaultPath//note_algo_lang//Info.Security.Journal.md"
    "pcba"        = "$vaultPath//note_Embedded//PCBJournal.md"
    "be"          = "$vaultPath//note_os_web//Server.Network.Journal.md"
    "edit"        = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "ui"          = "$vaultPath//note_os_web//UIJournal.md"
    "wfw"         = "$vaultPath//note_os_web//SDK-Framework.Web.Journal.md"
    "pic"         = "$vaultPath//note_Embedded//Passive.IC.Journal.md"
    "idea"        = "$vaultPath//note_Business//IdeaJournal.md"
    "quote"       = "$vaultPath//note_Knowledge//QuoteJournal.md"
    "meme"        = "$vaultPath//note_Knowledge//WholesomeJournal.md"
    "comp"        = "$vaultPath//note_Embedded//ComponentJournal.md"
    "file"        = "$vaultPath//note_IDEAndTools//File-Format.Journal.md"
    "social"      = "$vaultPath//note_Business//ConnectionJournal.md"
    "blend"       = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "myrule"      = "$vaultPath//note_Business//WorkflowJournal.md"
    "emb"         = "$vaultPath//note_Embedded//FirmwareJournal.md"
    "wprog"       = "$vaultPath//note_os_web//WebProgJournal.md"
    "eco"         = "$vaultPath//note_Knowledge//EconomyJournal.md"
    "cli"         = "$vaultPath//note_software//CLI.Terminal.Software.Journal.md"
    "model"       = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "cl"          = "$vaultPath//note_software//CLI.Terminal.Software.Journal.md"
    "media"       = "$vaultPath//note_Knowledge//NewsJournal.md"
    ":3"          = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "workflow"    = "$vaultPath//note_Business//WorkflowJournal.md"
    "std"         = "$vaultPath//note_algo_lang//LangJournal.md"
    "pger"        = "$vaultPath//note_Business//ConnectionJournal.md"
    "acc"         = "$vaultPath//note_Knowledge//secret//AccountJournal.md"
    "qt"          = "$vaultPath//note_Knowledge//QuoteJournal.md"
    "lang"        = "$vaultPath//note_algo_lang//LangJournal.md"
    "math"        = "$vaultPath//note_algo_lang//STEMJournal.md"
    "style"       = "$vaultPath//note_Business//WorkflowJournal.md"
    "chip"        = "$vaultPath//note_Embedded//ChipsetJournal.md"
    "frame"       = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
    "wlib"        = "$vaultPath//note_os_web//WebAPIJournal.md"
    "slang"       = "$vaultPath//note_Knowledge//PhraseJournal.md"
    "diary"       = "$vaultPath//note_entertainment//Diary.Journal.md"
    "come"        = "$vaultPath//note_Knowledge//WholesomeJournal.md"
    "wapi"        = "$vaultPath//note_os_web//WebAPIJournal.md"
    "work"        = "$vaultPath//note_Business//WorkJournal.md"
    "ecad"        = "$vaultPath//note_Embedded//EDAJournal.md"
    "gpu"         = "$vaultPath//note_algo_lang//GraphicUIJournal.md"
    "til"         = "$vaultPath//note_Knowledge//OtherKnowledgeJournal.md"
    "is"          = "$vaultPath//note_algo_lang//Info.Security.Journal.md"
    "lib"         = "$vaultPath//note_algo_lang//LibraryJournal.md"
    "event"       = "$vaultPath//note_Knowledge//EventJournal.md"
    "elec"        = "$vaultPath//note_Embedded//Electric.Journal.md"
    "stem"        = "$vaultPath//note_algo_lang//STEMJournal.md"
    "netw"        = "$vaultPath//note_algo_lang//Network.Journal.md"
    "money"       = "$vaultPath//note_Business//MoneyJournal.md"
    "phr"         = "$vaultPath//note_Knowledge//PhraseJournal.md"
    "windows"     = "$vaultPath//note_software//OSJournal.md"
    "other"       = "$vaultPath//note_Knowledge//OtherKnowledgeJournal.md"
    "graph"       = "$vaultPath//note_algo_lang//GraphicUIJournal.md"
    "book"        = "$vaultPath//note_Knowledge//ReadAndListenJournal.md"
    "phrase"      = "$vaultPath//note_Knowledge//PhraseJournal.md"
    "html"        = "$vaultPath//note_os_web//UIJournal.md"
    "wire"        = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "daily"       = "$vaultPath//note_entertainment//Diary.Journal.md"
    "module"      = "$vaultPath//note_Embedded//ChipsetJournal.md"
    "build"       = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
    "cpp"         = "$vaultPath//note_algo_lang//LangJournal.md"
    "wasm"        = "$vaultPath//note_os_web//WebProgJournal.md"
    "uiweb"       = "$vaultPath//note_os_web//UIJournal.md"
    "itf"         = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "econ"        = "$vaultPath//note_Knowledge//EconomyJournal.md"
    "proto"       = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "cad"         = "$vaultPath//note_IDEAndToolsCADJournal.md"
    "art"         = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "fe"          = "$vaultPath//note_os_web//UIJournal.md"
    "api"         = "$vaultPath//note_algo_lang//LibraryJournal.md"
    "music"       = "$vaultPath//note_entertainment//MusicJournal.md"
    "ety"         = "$vaultPath//note_Knowledge//PhraseJournal.md"
    "pp"          = "$vaultPath//note_Business//ConnectionJournal.md"
    "self"        = "$vaultPath//note_entertainment//PersonalJournal.md"
    "prog"        = "$vaultPath//note_algo_lang//ProgrammingJournal.md"
    "place"       = "$vaultPath//note_Knowledge//PlacesJournal.md"
    "cve"         = "$vaultPath//note_algo_lang//Info.Security.Journal.md"
    "swgui"       = "$vaultPath//note_software//GUI.Software.Journal.md"
    "pw"          = "$vaultPath//note_Knowledge//secret//AccountJournal.md"
    "sdk"         = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
    "server"      = "$vaultPath//note_os_web//Server.Network.Journal.md"
    "pcb"         = "$vaultPath//note_Embedded//PCBJournal.md"
    "wfr"         = "$vaultPath//note_os_web//SDK-Framework.Web.Journal.md"
    "srv"         = "$vaultPath//note_os_web//Server.Network.Journal.md"
    "ev"          = "$vaultPath//note_Knowledge//EventJournal.md"
    "vk"          = "$vaultPath//note_algo_lang//GraphicUIJournal.md"
    "draw"        = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "gui"         = "$vaultPath//note_software//GUI.Software.Journal.md"
    "bs"          = "$vaultPath//note_Business//WorkJournal.md"
    "taobao"      = "$vaultPath//note_Items//TaobaoJournal.md"
    "soc"         = "$vaultPath//note_Embedded//ChipsetJournal.md"
    "day"         = "$vaultPath//note_entertainment//Diary.Journal.md"
    "ide"         = "$vaultPath//note_IDEAndTools//IDE.Journal.md"
    "prot"        = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "webui"       = "$vaultPath//note_os_web//UIJournal.md"
    "mech"        = "$vaultPath//note_IDEAndTools//CADJournal.md"
    "stm"         = "$vaultPath//note_Embedded//FirmwareJournal.md"
    "peo"         = "$vaultPath//note_Business//ConnectionJournal.md"
    "swt"         = "$vaultPath//note_software//TUI.Terminal.Software.Journal.md"
    ":1688"       = "$vaultPath//note_Items//1688Journal.md"
    "default"     = "$vaultPath//MainJournal.md"
    "fw"          = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
    "swg"         = "$vaultPath//note_software//GUI.Software.Journal.md"
    "web"         = "$vaultPath//note_software//WebJournal.md"
    "read"        = "$vaultPath//note_Knowledge//ReadAndListenJournal.md"
    ":1"          = "$vaultPath//note_Items//1688Journal.md"
    "gsw"         = "$vaultPath//note_software//GUI.Software.Journal.md"
    "hw"          = "$vaultPath//note_Embedded//HardwareJournal.md"
    "busy"        = "$vaultPath//note_Business//WorkJournal.md"
    "psy"         = "$vaultPath//note_Knowledge//LifeJournal.md"
    "wpro"        = "$vaultPath//note_os_web//WebProgJournal.md"
    ":3d"         = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "item"        = "$vaultPath//note_Items//OtherItemsJournal.md"
    "vocab"       = "$vaultPath//note_Knowledge//VocabJournal.md"
    "life"        = "$vaultPath//note_Knowledge//LifeJournal.md"
    "interest"    = "$vaultPath//note_entertainment//PersonalJournal.md"
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
