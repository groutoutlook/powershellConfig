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
    p7 && Import-MoreModule 
}

$global:scriptingModuleList = @(
    "D:\ProgramDataD\MiscLang\24.01-PowerShell\proj\PSD1.Config.Utils\Psd1.Filesystem.Utils.psd1"
    # "PSTimers"
)


function Import-MoreModule {
    Invoke-Expression (&posh-fzf init | Out-String)
    Set-PSReadLineKeyHandler -Key 'Ctrl+r' -ScriptBlock { Invoke-PoshFzfSelectHistory }
    foreach ($module in $global:extraModuleList) {
        Import-Module -Name (Join-Path $env:p7settingDir $module) -Scope Global
    }
    foreach ($module in $global:scriptingModuleList) {
        Import-Module -Name $module -Scope Global
    }
}

Set-Alias -Name p7mod -Value Import-MoreModule


function :m {
    Restart-ModuleList -ModuleList $global:personalModuleList -ModulePath $env:p7settingDir
}

Set-Alias :mo Restart-ModuleList 

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
$global:JrnlTable = @{
    "swc"         = "$vaultPath//note_software//CLI.Terminal.Software.Journal.md"
    "prog"        = "$vaultPath//note_algo_lang//ProgrammingJournal.md"
    "tlm"         = "$vaultPath//note_entertainment//Device.Journal.md"
    "lhack"       = "$vaultPath//note_Knowledge//LifeHackJournal.md"
    "para"        = "$vaultPath//note_entertainment//Device.Journal.md"
    "eco"         = "$vaultPath//note_Knowledge//EconomyJournal.md"
    "bus"         = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "file"        = "$vaultPath//note_IDEAndTools//File-Format.Journal.md"
    "itf"         = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "default"     = "$vaultPath//MainJournal.md"
    "tip"         = "$vaultPath//note_Knowledge//LifeHackJournal.md"
    "cl"          = "$vaultPath//note_software//CLI.Terminal.Software.Journal.md"
    "proto"       = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "like"        = "$vaultPath//note_entertainment//PersonalJournal.md"
    "people"      = "$vaultPath//note_Business//ConnectionJournal.md"
    "diary"       = "$vaultPath//note_entertainment//Diary.Journal.md"
    "ms"          = "$vaultPath//note_entertainment//MusicJournal.md"
    "viap"        = "$vaultPath//note_Embedded//PCBJournal.md"
    "wf"          = "$vaultPath//note_Business//WorkflowJournal.md"
    "netw"        = "$vaultPath//note_algo_lang//Network.Journal.md"
    "triv"        = "$vaultPath//note_Knowledge//Trivia.Knowledge.Journal.md"
    "peo"         = "$vaultPath//note_Business//ConnectionJournal.md"
    "webui"       = "$vaultPath//note_os_web//Web.UI.Journal.md"
    "life"        = "$vaultPath//note_Knowledge//LifeJournal.md"
    "idea"        = "$vaultPath//note_Business//IdeaJournal.md"
    "gui"         = "$vaultPath//note_software//GUI.Software.Journal.md"
    "news"        = "$vaultPath//note_Knowledge//NewsJournal.md"
    "geom"        = "$vaultPath//note_algo_lang//Math.Journal.md"
    "module"      = "$vaultPath//note_Embedded//ChipsetJournal.md"
    "gra"         = "$vaultPath//note_algo_lang//GraphicUIJournal.md"
    "swg"         = "$vaultPath//note_software//GUI.Software.Journal.md"
    "event"       = "$vaultPath//note_Knowledge//EventJournal.md"
    "blend"       = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "oic"         = "$vaultPath//note_Embedded//Others.IC.Journal.md"
    "interest"    = "$vaultPath//note_entertainment//PersonalJournal.md"
    "chip"        = "$vaultPath//note_Embedded//ChipsetJournal.md"
    "edit"        = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "swgui"       = "$vaultPath//note_software//GUI.Software.Journal.md"
    "qt"          = "$vaultPath//note_Knowledge//QuoteJournal.md"
    "graph"       = "$vaultPath//note_algo_lang//GraphicUIJournal.md"
    "soc"         = "$vaultPath//note_Embedded//ChipsetJournal.md"
    "pers"        = "$vaultPath//note_entertainment//PersonalJournal.md"
    "pic"         = "$vaultPath//note_Embedded//Passive.IC.Journal.md"
    "asset"       = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "wire"        = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "fm"          = "$vaultPath//note_IDEAndTools//File-Format.Journal.md"
    "fi"          = "$vaultPath//note_Embedded//FirmwareJournal.md"
    "book"        = "$vaultPath//note_Knowledge//ReadAndListenJournal.md"
    "cad"         = "$vaultPath//note_IDEAndTools//CADJournal.md"
    "alge"        = "$vaultPath//note_algo_lang//Algebra.Math.Journal.md"
    "music"       = "$vaultPath//note_entertainment//MusicJournal.md"
    "elec"        = "$vaultPath//note_Embedded//Electric.Journal.md"
    "lang"        = "$vaultPath//note_algo_lang//LangJournal.md"
    "wui"         = "$vaultPath//note_os_web//Web.UI.Journal.md"
    "day"         = "$vaultPath//note_entertainment//Diary.Journal.md"
    "model"       = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "net"         = "$vaultPath//note_algo_lang//Network.Journal.md"
    "psy"         = "$vaultPath//note_Knowledge//LifeJournal.md"
    "cash"        = "$vaultPath//note_Business//MoneyJournal.md"
    "draw"        = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "sec"         = "$vaultPath//note_algo_lang//Info.Security.Journal.md"
    "busy"        = "$vaultPath//note_Business//WorkJournal.md"
    "ic"          = "$vaultPath//note_Embedded//ChipsetJournal.md"
    "wprog"       = "$vaultPath//note_os_web//WebProgJournal.md"
    "mech"        = "$vaultPath//note_IDEAndTools//CADJournal.md"
    "social"      = "$vaultPath//note_Business//ConnectionJournal.md"
    "backend"     = "$vaultPath//note_os_web//Server.Network.Journal.md"
    "ltip"        = "$vaultPath//note_Knowledge//LifeHackJournal.md"
    "wpro"        = "$vaultPath//note_os_web//WebProgJournal.md"
    "ecad"        = "$vaultPath//note_Embedded//EDAJournal.md"
    "stm"         = "$vaultPath//note_Embedded//FirmwareJournal.md"
    "new"         = "$vaultPath//note_Knowledge//NewsJournal.md"
    "mcu"         = "$vaultPath//note_Embedded//MCU.IC.Journal.md"
    "infosec"     = "$vaultPath//note_algo_lang//Info.Security.Journal.md"
    "vocab"       = "$vaultPath//note_Knowledge//VocabJournal.md"
    "math"        = "$vaultPath//note_algo_lang//Math.Journal.md"
    "video"       = "$vaultPath//note_entertainment//VideoJournal.md"
    "html"        = "$vaultPath//note_os_web//Web.UI.Journal.md"
    "comp"        = "$vaultPath//note_Embedded//ComponentJournal.md"
    "meme"        = "$vaultPath//note_Knowledge//WholesomeJournal.md"
    "ev"          = "$vaultPath//note_Knowledge//EventJournal.md"
    "web"         = "$vaultPath//note_software//WebJournal.md"
    "gsw"         = "$vaultPath//note_software//GUI.Software.Journal.md"
    "std"         = "$vaultPath//note_algo_lang//LangJournal.md"
    "acc"         = "$vaultPath//note_Knowledge//secret//AccountJournal.md"
    ":3"          = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "rule"        = "$vaultPath//note_Business//WorkflowJournal.md"
    "prt"         = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "wsdk"        = "$vaultPath//note_os_web//SDK-Framework.Web.Journal.md"
    "prot"        = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "three"       = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "slang"       = "$vaultPath//note_Knowledge//PhraseJournal.md"
    "acro"        = "$vaultPath//note_Knowledge//AcronymJournal.md"
    "api"         = "$vaultPath//note_algo_lang//LibraryJournal.md"
    "cli"         = "$vaultPath//note_software//CLI.Terminal.Software.Journal.md"
    "frontend"    = "$vaultPath//note_os_web//UIJournal.md"
    "ee"          = "$vaultPath//note_Embedded//Electric.Journal.md"
    "sv"          = "$vaultPath//note_os_web//Server.Network.Journal.md"
    "pw"          = "$vaultPath//note_Knowledge//secret//AccountJournal.md"
    "freecad"     = "$vaultPath//note_IDEAndTools//CADJournal.md"
    "vk"          = "$vaultPath//note_algo_lang//GraphicUIJournal.md"
    "fw"          = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
    "task"        = "$vaultPath//note_Business//WorkJournal.md"
    "buildsystem" = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
    "stem"        = "$vaultPath//note_algo_lang//STEMJournal.md"
    "econ"        = "$vaultPath//note_Knowledge//EconomyJournal.md"
    "media"       = "$vaultPath//note_Knowledge//NewsJournal.md"
    "come"        = "$vaultPath//note_Knowledge//WholesomeJournal.md"
    "ide"         = "$vaultPath//note_IDEAndTools//IDE.Journal.md"
    "laugh"       = "$vaultPath//note_Knowledge//WholesomeJournal.md"
    "pp"          = "$vaultPath//note_Business//ConnectionJournal.md"
    "daily"       = "$vaultPath//note_entertainment//Diary.Journal.md"
    "art"         = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "place"       = "$vaultPath//note_Knowledge//PlacesJournal.md"
    "pol"         = "$vaultPath//note_Knowledge//NewsJournal.md"
    "is"          = "$vaultPath//note_algo_lang//Info.Security.Journal.md"
    "conn"        = "$vaultPath//note_Business//ConnectionJournal.md"
    "emb"         = "$vaultPath//note_Embedded//FirmwareJournal.md"
    "vid"         = "$vaultPath//note_entertainment//VideoJournal.md"
    "pcba"        = "$vaultPath//note_Embedded//PCBJournal.md"
    "vc"          = "$vaultPath//note_Knowledge//VocabJournal.md"
    "ety"         = "$vaultPath//note_Knowledge//PhraseJournal.md"
    "eda"         = "$vaultPath//note_Embedded//EDAJournal.md"
    "be"          = "$vaultPath//note_os_web//Server.Network.Journal.md"
    "swt"         = "$vaultPath//note_software//TUI.Terminal.Software.Journal.md"
    "etym"        = "$vaultPath//note_Knowledge//PhraseJournal.md"
    "sdk"         = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
    "soft"        = "$vaultPath//note_software//SoftwareJournal.md"
    "windows"     = "$vaultPath//note_software//OSJournal.md"
    "per"         = "$vaultPath//note_entertainment//PersonalJournal.md"
    "kicad"       = "$vaultPath//note_Embedded//EDAJournal.md"
    "uiweb"       = "$vaultPath//note_os_web//Web.UI.Journal.md"
    "inte"        = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "hack"        = "$vaultPath//note_Knowledge//LifeHackJournal.md"
    "num"         = "$vaultPath//note_algo_lang//Math.Journal.md"
    "build"       = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
    "wfr"         = "$vaultPath//note_os_web//SDK-Framework.Web.Journal.md"
    "csci"        = "$vaultPath//note_algo_lang//CompSciJournal.md"
    "taobao"      = "$vaultPath//note_Items//TaobaoJournal.md"
    "phr"         = "$vaultPath//note_Knowledge//PhraseJournal.md"
    "fe"          = "$vaultPath//note_os_web//UIJournal.md"
    "item"        = "$vaultPath//note_Items//OtherItemsJournal.md"
    "bs"          = "$vaultPath//note_Business//WorkJournal.md"
    "gpu"         = "$vaultPath//note_algo_lang//GraphicUIJournal.md"
    "tu"          = "$vaultPath//note_software//TUI.Terminal.Software.Journal.md"
    "self"        = "$vaultPath//note_entertainment//PersonalJournal.md"
    "pcb"         = "$vaultPath//note_Embedded//PCBJournal.md"
    "linux"       = "$vaultPath//note_software//OSJournal.md"
    "blog"        = "$vaultPath//note_Knowledge//ReadAndListenJournal.md"
    "quote"       = "$vaultPath//note_Knowledge//QuoteJournal.md"
    "nw"          = "$vaultPath//note_algo_lang//Network.Journal.md"
    "other"       = "$vaultPath//note_Knowledge//OtherKnowledgeJournal.md"
    ":1688"       = "$vaultPath//note_Items//1688Journal.md"
    "wfw"         = "$vaultPath//note_os_web//SDK-Framework.Web.Journal.md"
    "css"         = "$vaultPath//note_os_web//Web.UI.Journal.md"
    "srv"         = "$vaultPath//note_os_web//Server.Network.Journal.md"
    "wasm"        = "$vaultPath//note_os_web//WebProgJournal.md"
    "cve"         = "$vaultPath//note_algo_lang//Info.Security.Journal.md"
    "dev"         = "$vaultPath//note_entertainment//Device.Journal.md"
    "hard"        = "$vaultPath//note_Embedded//HardwareJournal.md"
    "ui"          = "$vaultPath//note_os_web//UIJournal.md"
    "sw"          = "$vaultPath//note_software//SoftwareJournal.md"
    "humor"       = "$vaultPath//note_Knowledge//WholesomeJournal.md"
    "pger"        = "$vaultPath//note_Business//ConnectionJournal.md"
    "cpp"         = "$vaultPath//note_algo_lang//LangJournal.md"
    "physic"      = "$vaultPath//note_algo_lang//STEMJournal.md"
    "fiw"         = "$vaultPath//note_Embedded//FirmwareJournal.md"
    "workflow"    = "$vaultPath//note_Business//WorkflowJournal.md"
    "ali"         = "$vaultPath//note_Items//1688Journal.md"
    "myrule"      = "$vaultPath//note_Business//WorkflowJournal.md"
    ":1"          = "$vaultPath//note_Items//1688Journal.md"
    "matrix"      = "$vaultPath//note_algo_lang//Algebra.Math.Journal.md"
    "style"       = "$vaultPath//note_Business//WorkflowJournal.md"
    "money"       = "$vaultPath//note_Business//MoneyJournal.md"
    "vul"         = "$vaultPath//note_algo_lang//GraphicUIJournal.md"
    "work"        = "$vaultPath//note_Business//WorkJournal.md"
    "tui"         = "$vaultPath//note_software//TUI.Terminal.Software.Journal.md"
    "isec"        = "$vaultPath//note_algo_lang//Info.Security.Journal.md"
    "shape"       = "$vaultPath//note_algo_lang//Math.Journal.md"
    "cad3d"       = "$vaultPath//note_IDEAndTools//CADJournal.md"
    "frame"       = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
    "phrase"      = "$vaultPath//note_Knowledge//PhraseJournal.md"
    "til"         = "$vaultPath//note_Knowledge//OtherKnowledgeJournal.md"
    "cs"          = "$vaultPath//note_algo_lang//CompSciJournal.md"
    "embed"       = "$vaultPath//note_Embedded//FirmwareJournal.md"
    "hw"          = "$vaultPath//note_Embedded//HardwareJournal.md"
    "read"        = "$vaultPath//note_Knowledge//ReadAndListenJournal.md"
    "server"      = "$vaultPath//note_os_web//Server.Network.Journal.md"
    "os"          = "$vaultPath//note_software//OSJournal.md"
    "lib"         = "$vaultPath//note_algo_lang//LibraryJournal.md"
    "fcad"        = "$vaultPath//note_IDEAndTools//CADJournal.md"
    "wlib"        = "$vaultPath//note_os_web//WebAPIJournal.md"
    "misc"        = "$vaultPath//note_Knowledge//Trivia.Knowledge.Journal.md"
    "fr"          = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
    "firm"        = "$vaultPath//note_Embedded//FirmwareJournal.md"
    "wapi"        = "$vaultPath//note_os_web//WebAPIJournal.md"
    ":3d"         = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
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
