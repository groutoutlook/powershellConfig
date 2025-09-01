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

# NOTE: neovim trigger function.
function :v {
    $codeEditor = "nvim"
    $parsedArgs = $args
  
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
    "os"          = "$vaultPath//note_software//OSJournal.md"
    "wui"         = "$vaultPath//note_os_web//Web.UI.Journal.md"
    "res"         = "$vaultPath//note_Embedded//Passive.IC.Journal.md"
    "oth"         = "$vaultPath//note_Knowledge//Other.Knowledge.Journal.md"
    "hack"        = "$vaultPath//note_Knowledge//LifeHackJournal.md"
    "phrase"      = "$vaultPath//note_Knowledge//PhraseJournal.md"
    "sec"         = "$vaultPath//note_algo_lang//Info.Security.Journal.md"
    "nw"          = "$vaultPath//note_algo_lang//Network.Journal.md"
    "sdk"         = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
    "place"       = "$vaultPath//note_Knowledge//PlacesJournal.md"
    "event"       = "$vaultPath//note_Knowledge//EventJournal.md"
    "tu"          = "$vaultPath//note_software//TUI.Terminal.Software.Journal.md"
    "matrix"      = "$vaultPath//note_algo_lang//Algebra.Math.Journal.md"
    "quote"       = "$vaultPath//note_Knowledge//QuoteJournal.md"
    "soc"         = "$vaultPath//note_Embedded//ChipsetJournal.md"
    "swg"         = "$vaultPath//note_software//GUI.Software.Journal.md"
    "num"         = "$vaultPath//note_algo_lang//Math.Journal.md"
    "gui"         = "$vaultPath//note_software//GUI.Software.Journal.md"
    "wire"        = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "come"        = "$vaultPath//note_Knowledge//WholesomeJournal.md"
    "psy"         = "$vaultPath//note_Knowledge//LifeJournal.md"
    "til"         = "$vaultPath//note_Knowledge//TIL.Knowledge.Journal.md"
    "bs"          = "$vaultPath//note_Business//WorkJournal.md"
    "uiweb"       = "$vaultPath//note_os_web//Web.UI.Journal.md"
    "webui"       = "$vaultPath//note_os_web//Web.UI.Journal.md"
    "csci"        = "$vaultPath//note_algo_lang//CompSciJournal.md"
    "qt"          = "$vaultPath//note_Knowledge//QuoteJournal.md"
    "netw"        = "$vaultPath//note_algo_lang//Network.Journal.md"
    "diary"       = "$vaultPath//note_entertainment//Diary.Journal.md"
    "peo"         = "$vaultPath//note_Business//ConnectionJournal.md"
    "math"        = "$vaultPath//note_algo_lang//Math.Journal.md"
    "day"         = "$vaultPath//note_entertainment//Diary.Journal.md"
    "build"       = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
    "vc"          = "$vaultPath//note_Knowledge//VocabJournal.md"
    "laugh"       = "$vaultPath//note_Knowledge//WholesomeJournal.md"
    "css"         = "$vaultPath//note_os_web//Web.UI.Journal.md"
    "taobao"      = "$vaultPath//note_Items//TaobaoJournal.md"
    "stm"         = "$vaultPath//note_Embedded//FirmwareJournal.md"
    "ocom"        = "$vaultPath//note_Embedded//Others.IC.Journal.md"
    "workflow"    = "$vaultPath//note_Business//WorkflowJournal.md"
    "work"        = "$vaultPath//note_Business//WorkJournal.md"
    "cad"         = "$vaultPath//note_IDEAndTools//CADJournal.md"
    "hard"        = "$vaultPath//note_Embedded//HardwareJournal.md"
    "geom"        = "$vaultPath//note_algo_lang//Math.Journal.md"
    "sv"          = "$vaultPath//note_os_web//Server.Network.Journal.md"
    "lang"        = "$vaultPath//note_algo_lang//LangJournal.md"
    "art"         = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "tip"         = "$vaultPath//note_Knowledge//TIL.Knowledge.Journal.md"
    "firm"        = "$vaultPath//note_Embedded//FirmwareJournal.md"
    "pers"        = "$vaultPath//note_entertainment//PersonalJournal.md"
    "pass"        = "$vaultPath//note_Embedded//Passive.IC.Journal.md"
    "embed"       = "$vaultPath//note_Embedded//FirmwareJournal.md"
    "prt"         = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "fw"          = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
    "wf"          = "$vaultPath//note_Business//WorkflowJournal.md"
    "kicad"       = "$vaultPath//note_Embedded//EDAJournal.md"
    "linux"       = "$vaultPath//note_software//OSJournal.md"
    "tlm"         = "$vaultPath//note_entertainment//Device.Journal.md"
    "icother"     = "$vaultPath//note_Embedded//Others.IC.Journal.md"
    "acro"        = "$vaultPath//note_Knowledge//AcronymJournal.md"
    "daily"       = "$vaultPath//note_entertainment//Diary.Journal.md"
    "frame"       = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
    "pw"          = "$vaultPath//note_Knowledge//secret//AccountJournal.md"
    "money"       = "$vaultPath//note_Business//MoneyJournal.md"
    "blog"        = "$vaultPath//note_Knowledge//ReadAndListenJournal.md"
    "tui"         = "$vaultPath//note_software//TUI.Terminal.Software.Journal.md"
    "model"       = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "fiw"         = "$vaultPath//note_Embedded//FirmwareJournal.md"
    "alge"        = "$vaultPath//note_algo_lang//Algebra.Math.Journal.md"
    "prog"        = "$vaultPath//note_algo_lang//ProgrammingJournal.md"
    "bus"         = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "fe"          = "$vaultPath//note_os_web//UIJournal.md"
    "swt"         = "$vaultPath//note_software//TUI.Terminal.Software.Journal.md"
    "viap"        = "$vaultPath//note_Embedded//PCBJournal.md"
    "cap"         = "$vaultPath//note_Embedded//Passive.IC.Journal.md"
    "srv"         = "$vaultPath//note_os_web//Server.Network.Journal.md"
    "meme"        = "$vaultPath//note_Knowledge//WholesomeJournal.md"
    "wpro"        = "$vaultPath//note_os_web//WebProgJournal.md"
    "ide"         = "$vaultPath//note_IDEAndTools//IDE.Journal.md"
    "vid"         = "$vaultPath//note_entertainment//VideoJournal.md"
    "asset"       = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "cpp"         = "$vaultPath//note_algo_lang//LangJournal.md"
    "people"      = "$vaultPath//note_Business//ConnectionJournal.md"
    "draw"        = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "tele"        = "$vaultPath//note_entertainment//Device.Journal.md"
    "sw"          = "$vaultPath//note_software//SoftwareJournal.md"
    "mcu"         = "$vaultPath//note_Embedded//MCU.IC.Journal.md"
    "fr"          = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
    "net"         = "$vaultPath//note_algo_lang//Network.Journal.md"
    "cve"         = "$vaultPath//note_algo_lang//Info.Security.Journal.md"
    "ietf"        = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "pger"        = "$vaultPath//note_Business//ConnectionJournal.md"
    "pp"          = "$vaultPath//note_Business//ConnectionJournal.md"
    "wlib"        = "$vaultPath//note_os_web//WebAPIJournal.md"
    "lhack"       = "$vaultPath//note_Knowledge//LifeHackJournal.md"
    "soft"        = "$vaultPath//note_software//SoftwareJournal.md"
    "api"         = "$vaultPath//note_algo_lang//LibraryJournal.md"
    "ui"          = "$vaultPath//note_os_web//UIJournal.md"
    "ltip"        = "$vaultPath//note_Knowledge//LifeHackJournal.md"
    "myrule"      = "$vaultPath//note_Business//WorkflowJournal.md"
    "ico"         = "$vaultPath//note_Embedded//Others.IC.Journal.md"
    ":1"          = "$vaultPath//note_Items//1688Journal.md"
    "wprog"       = "$vaultPath//note_os_web//WebProgJournal.md"
    "fcad"        = "$vaultPath//note_IDEAndTools//CADJournal.md"
    "pcb"         = "$vaultPath//note_Embedded//PCBJournal.md"
    "html"        = "$vaultPath//note_os_web//Web.UI.Journal.md"
    "fi"          = "$vaultPath//note_Embedded//FirmwareJournal.md"
    "be"          = "$vaultPath//note_os_web//Server.Network.Journal.md"
    "gpu"         = "$vaultPath//note_algo_lang//GraphicUIJournal.md"
    "item"        = "$vaultPath//note_Items//OtherItemsJournal.md"
    "social"      = "$vaultPath//note_Business//ConnectionJournal.md"
    "chip"        = "$vaultPath//note_Embedded//ChipsetJournal.md"
    "ms"          = "$vaultPath//note_entertainment//MusicJournal.md"
    "pcba"        = "$vaultPath//note_Embedded//PCBJournal.md"
    "std"         = "$vaultPath//note_algo_lang//LangJournal.md"
    "vk"          = "$vaultPath//note_algo_lang//GraphicUIJournal.md"
    "mech"        = "$vaultPath//note_IDEAndTools//CADJournal.md"
    "cs"          = "$vaultPath//note_algo_lang//CompSciJournal.md"
    "task"        = "$vaultPath//note_Business//WorkJournal.md"
    "read"        = "$vaultPath//note_Knowledge//ReadAndListenJournal.md"
    "news"        = "$vaultPath//note_Knowledge//NewsJournal.md"
    "like"        = "$vaultPath//note_entertainment//PersonalJournal.md"
    "phr"         = "$vaultPath//note_Knowledge//PhraseJournal.md"
    "swgui"       = "$vaultPath//note_software//GUI.Software.Journal.md"
    "life"        = "$vaultPath//note_Knowledge//LifeJournal.md"
    "freecad"     = "$vaultPath//note_IDEAndTools//CADJournal.md"
    "media"       = "$vaultPath//note_Knowledge//NewsJournal.md"
    "ali"         = "$vaultPath//note_Items//1688Journal.md"
    "emb"         = "$vaultPath//note_Embedded//FirmwareJournal.md"
    "ic"          = "$vaultPath//note_Embedded//ChipsetJournal.md"
    "wsdk"        = "$vaultPath//note_os_web//SDK-Framework.Web.Journal.md"
    "music"       = "$vaultPath//note_entertainment//MusicJournal.md"
    "inte"        = "$vaultPath//note_Embedded//ProtocolJournal.md"
    ":3d"         = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "three"       = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "module"      = "$vaultPath//note_Embedded//ChipsetJournal.md"
    "misc"        = "$vaultPath//note_Knowledge//Trivia.Knowledge.Journal.md"
    "file"        = "$vaultPath//note_IDEAndTools//File-Format.Journal.md"
    "ee"          = "$vaultPath//note_Embedded//Electric.Journal.md"
    "slang"       = "$vaultPath//note_Knowledge//PhraseJournal.md"
    "wfw"         = "$vaultPath//note_os_web//SDK-Framework.Web.Journal.md"
    "interest"    = "$vaultPath//note_entertainment//PersonalJournal.md"
    "wfr"         = "$vaultPath//note_os_web//SDK-Framework.Web.Journal.md"
    "vul"         = "$vaultPath//note_algo_lang//GraphicUIJournal.md"
    "new"         = "$vaultPath//note_Knowledge//NewsJournal.md"
    "shape"       = "$vaultPath//note_algo_lang//Math.Journal.md"
    "frontend"    = "$vaultPath//note_os_web//UIJournal.md"
    ":1688"       = "$vaultPath//note_Items//1688Journal.md"
    "rule"        = "$vaultPath//note_Business//WorkflowJournal.md"
    "isec"        = "$vaultPath//note_algo_lang//Info.Security.Journal.md"
    "blend"       = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "book"        = "$vaultPath//note_Knowledge//ReadAndListenJournal.md"
    "conn"        = "$vaultPath//note_Business//ConnectionJournal.md"
    "buildsystem" = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
    "edit"        = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "pcom"        = "$vaultPath//note_Embedded//Passive.IC.Journal.md"
    "proto"       = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "infosec"     = "$vaultPath//note_algo_lang//Info.Security.Journal.md"
    "physic"      = "$vaultPath//note_algo_lang//STEMJournal.md"
    "prot"        = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "etym"        = "$vaultPath//note_Knowledge//PhraseJournal.md"
    "server"      = "$vaultPath//note_os_web//Server.Network.Journal.md"
    "busy"        = "$vaultPath//note_Business//WorkJournal.md"
    ":3"          = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "vocab"       = "$vaultPath//note_Knowledge//VocabJournal.md"
    "hw"          = "$vaultPath//note_Embedded//HardwareJournal.md"
    "fm"          = "$vaultPath//note_IDEAndTools//File-Format.Journal.md"
    "per"         = "$vaultPath//note_entertainment//PersonalJournal.md"
    "windows"     = "$vaultPath//note_software//OSJournal.md"
    "para"        = "$vaultPath//note_entertainment//Device.Journal.md"
    "triv"        = "$vaultPath//note_Knowledge//Trivia.Knowledge.Journal.md"
    "wapi"        = "$vaultPath//note_os_web//WebAPIJournal.md"
    "other"       = "$vaultPath//note_Knowledge//Other.Knowledge.Journal.md"
    "ecad"        = "$vaultPath//note_Embedded//EDAJournal.md"
    "cli"         = "$vaultPath//note_software//CLI.Terminal.Software.Journal.md"
    "video"       = "$vaultPath//note_entertainment//VideoJournal.md"
    "pic"         = "$vaultPath//note_Embedded//Passive.IC.Journal.md"
    "ev"          = "$vaultPath//note_Knowledge//EventJournal.md"
    "cl"          = "$vaultPath//note_software//CLI.Terminal.Software.Journal.md"
    "stem"        = "$vaultPath//note_algo_lang//STEMJournal.md"
    "comp"        = "$vaultPath//note_Embedded//ComponentJournal.md"
    "eda"         = "$vaultPath//note_Embedded//EDAJournal.md"
    "idea"        = "$vaultPath//note_Business//IdeaJournal.md"
    "oic"         = "$vaultPath//note_Embedded//Others.IC.Journal.md"
    "dev"         = "$vaultPath//note_entertainment//Device.Journal.md"
    "swc"         = "$vaultPath//note_software//CLI.Terminal.Software.Journal.md"
    "cash"        = "$vaultPath//note_Business//MoneyJournal.md"
    "eco"         = "$vaultPath//note_Knowledge//EconomyJournal.md"
    "is"          = "$vaultPath//note_algo_lang//Info.Security.Journal.md"
    "web"         = "$vaultPath//note_software//WebJournal.md"
    "wasm"        = "$vaultPath//note_os_web//WebProgJournal.md"
    "backend"     = "$vaultPath//note_os_web//Server.Network.Journal.md"
    "graph"       = "$vaultPath//note_algo_lang//GraphicUIJournal.md"
    "humor"       = "$vaultPath//note_Knowledge//WholesomeJournal.md"
    "acc"         = "$vaultPath//note_Knowledge//secret//AccountJournal.md"
    "econ"        = "$vaultPath//note_Knowledge//EconomyJournal.md"
    "style"       = "$vaultPath//note_Business//WorkflowJournal.md"
    "default"     = "$vaultPath//MainJournal.md"
    "gsw"         = "$vaultPath//note_software//GUI.Software.Journal.md"
    "pol"         = "$vaultPath//note_Knowledge//NewsJournal.md"
    "cad3d"       = "$vaultPath//note_IDEAndTools//CADJournal.md"
    "self"        = "$vaultPath//note_entertainment//PersonalJournal.md"
    "lib"         = "$vaultPath//note_algo_lang//LibraryJournal.md"
    "know"        = "$vaultPath//note_Knowledge//Other.Knowledge.Journal.md"
    "ety"         = "$vaultPath//note_Knowledge//PhraseJournal.md"
    "elec"        = "$vaultPath//note_Embedded//Electric.Journal.md"
    "gra"         = "$vaultPath//note_algo_lang//GraphicUIJournal.md"
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
Set-Alias -Name :o -Value :obsidian

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
        :vs es
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
