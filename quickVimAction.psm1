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
":1"         = "$vaultPath//note_Items//1688Journal.md"
":1688"      = "$vaultPath//note_Items//1688Journal.md"
":3"         = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
":3d"        = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
"acc"        = "$vaultPath//note_Knowledge//secret//AccountJournal.md"
"acro"       = "$vaultPath//note_Knowledge//AcronymJournal.md"
"alge"       = "$vaultPath//note_algo_lang//Algebra.Math.Journal.md"
"ali"        = "$vaultPath//note_Items//1688Journal.md"
"api"        = "$vaultPath//note_algo_lang//LibraryJournal.md"
"art"        = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
"asset"      = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
"backend"    = "$vaultPath//note_os_web//Server.Network.Journal.md"
"be"         = "$vaultPath//note_os_web//Server.Network.Journal.md"
"blend"      = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
"blog"       = "$vaultPath//note_Knowledge//ReadAndListenJournal.md"
"book"       = "$vaultPath//note_Knowledge//ReadAndListenJournal.md"
"bs"         = "$vaultPath//note_Business//WorkJournal.md"
"build"      = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
"buildsystem"= "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
"bus"        = "$vaultPath//note_Embedded//ProtocolJournal.md"
"busy"       = "$vaultPath//note_Business//WorkJournal.md"
"cad"        = "$vaultPath//note_IDEAndTools//CADJournal.md"
"cad3d"      = "$vaultPath//note_IDEAndTools//CADJournal.md"
"cap"        = "$vaultPath//note_Embedded//Passive.IC.Journal.md"
"cash"       = "$vaultPath//note_Business//MoneyJournal.md"
"chip"       = "$vaultPath//note_Embedded//ChipsetJournal.md"
"cl"         = "$vaultPath//note_software//CLI.Terminal.Software.Journal.md"
"cli"        = "$vaultPath//note_software//CLI.Terminal.Software.Journal.md"
"come"       = "$vaultPath//note_Knowledge//WholesomeJournal.md"
"comp"       = "$vaultPath//note_Embedded//ComponentJournal.md"
"conn"       = "$vaultPath//note_Business//ConnectionJournal.md"
"cpp"        = "$vaultPath//note_algo_lang//LangJournal.md"
"cs"         = "$vaultPath//note_algo_lang//CompSciJournal.md"
"csci"       = "$vaultPath//note_algo_lang//CompSciJournal.md"
"css"        = "$vaultPath//note_os_web//Web.UI.Journal.md"
"cve"        = "$vaultPath//note_algo_lang//Info.Security.Journal.md"
"daily"      = "$vaultPath//note_entertainment//Diary.Journal.md"
"day"        = "$vaultPath//note_entertainment//Diary.Journal.md"
"default"    = "$vaultPath//MainJournal.md"
"dev"        = "$vaultPath//note_entertainment//Device.Journal.md"
"diary"      = "$vaultPath//note_entertainment//Diary.Journal.md"
"draw"       = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
"ecad"       = "$vaultPath//note_Embedded//EDAJournal.md"
"eco"        = "$vaultPath//note_Knowledge//EconomyJournal.md"
"econ"       = "$vaultPath//note_Knowledge//EconomyJournal.md"
"eda"        = "$vaultPath//note_Embedded//EDAJournal.md"
"edit"       = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
"ee"         = "$vaultPath//note_Embedded//Electric.Journal.md"
"elec"       = "$vaultPath//note_Embedded//Electric.Journal.md"
"emb"        = "$vaultPath//note_Embedded//FirmwareJournal.md"
"embed"      = "$vaultPath//note_Embedded//FirmwareJournal.md"
"ety"        = "$vaultPath//note_Knowledge//PhraseJournal.md"
"etym"       = "$vaultPath//note_Knowledge//PhraseJournal.md"
"ev"         = "$vaultPath//note_Knowledge//EventJournal.md"
"event"      = "$vaultPath//note_Knowledge//EventJournal.md"
"fcad"       = "$vaultPath//note_IDEAndTools//CADJournal.md"
"fe"         = "$vaultPath//note_os_web//UIJournal.md"
"fi"         = "$vaultPath//note_Embedded//FirmwareJournal.md"
"file"       = "$vaultPath//note_IDEAndTools//File-Format.Journal.md"
"firm"       = "$vaultPath//note_Embedded//FirmwareJournal.md"
"fiw"        = "$vaultPath//note_Embedded//FirmwareJournal.md"
"fm"         = "$vaultPath//note_IDEAndTools//File-Format.Journal.md"
"fr"         = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
"frame"      = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
"freecad"    = "$vaultPath//note_IDEAndTools//CADJournal.md"
"frontend"   = "$vaultPath//note_os_web//UIJournal.md"
"fw"         = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
"geom"       = "$vaultPath//note_algo_lang//Math.Journal.md"
"gpu"        = "$vaultPath//note_algo_lang//GraphicUIJournal.md"
"gra"        = "$vaultPath//note_algo_lang//GraphicUIJournal.md"
"graph"      = "$vaultPath//note_algo_lang//GraphicUIJournal.md"
"gsw"        = "$vaultPath//note_software//GUI.Software.Journal.md"
"gui"        = "$vaultPath//note_software//GUI.Software.Journal.md"
"hack"       = "$vaultPath//note_Knowledge//LifeHackJournal.md"
"hard"       = "$vaultPath//note_Embedded//HardwareJournal.md"
"html"       = "$vaultPath//note_os_web//Web.UI.Journal.md"
"humor"      = "$vaultPath//note_Knowledge//WholesomeJournal.md"
"hw"         = "$vaultPath//note_Embedded//HardwareJournal.md"
"ic"         = "$vaultPath//note_Embedded//ChipsetJournal.md"
"ico"        = "$vaultPath//note_Embedded//Others.IC.Journal.md"
"icother"    = "$vaultPath//note_Embedded//Others.IC.Journal.md"
"ide"        = "$vaultPath//note_IDEAndTools//IDE.Journal.md"
"idea"       = "$vaultPath//note_Business//IdeaJournal.md"
"ietf"       = "$vaultPath//note_Embedded//ProtocolJournal.md"
"infosec"    = "$vaultPath//note_algo_lang//Info.Security.Journal.md"
"inte"       = "$vaultPath//note_Embedded//ProtocolJournal.md"
"interest"   = "$vaultPath//note_entertainment//PersonalJournal.md"
"is"         = "$vaultPath//note_algo_lang//Info.Security.Journal.md"
"isec"       = "$vaultPath//note_algo_lang//Info.Security.Journal.md"
"item"       = "$vaultPath//note_Items//OtherItemsJournal.md"
"kicad"      = "$vaultPath//note_Embedded//EDAJournal.md"
"lang"       = "$vaultPath//note_algo_lang//LangJournal.md"
"laugh"      = "$vaultPath//note_Knowledge//WholesomeJournal.md"
"lhack"      = "$vaultPath//note_Knowledge//LifeHackJournal.md"
"lib"        = "$vaultPath//note_algo_lang//LibraryJournal.md"
"life"       = "$vaultPath//note_Knowledge//LifeJournal.md"
"like"       = "$vaultPath//note_entertainment//PersonalJournal.md"
"linux"      = "$vaultPath//note_software//OSJournal.md"
"ltip"       = "$vaultPath//note_Knowledge//LifeHackJournal.md"
"math"       = "$vaultPath//note_algo_lang//Math.Journal.md"
"matrix"     = "$vaultPath//note_algo_lang//Algebra.Math.Journal.md"
"mcu"        = "$vaultPath//note_Embedded//MCU.IC.Journal.md"
"mech"       = "$vaultPath//note_IDEAndTools//CADJournal.md"
"media"      = "$vaultPath//note_Knowledge//NewsJournal.md"
"meme"       = "$vaultPath//note_Knowledge//WholesomeJournal.md"
"misc"       = "$vaultPath//note_Knowledge//Trivia.Knowledge.Journal.md"
"model"      = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
"module"     = "$vaultPath//note_Embedded//ChipsetJournal.md"
"money"      = "$vaultPath//note_Business//MoneyJournal.md"
"ms"         = "$vaultPath//note_entertainment//MusicJournal.md"
"music"      = "$vaultPath//note_entertainment//MusicJournal.md"
"myrule"     = "$vaultPath//note_Business//WorkflowJournal.md"
"net"        = "$vaultPath//note_algo_lang//Network.Journal.md"
"netw"       = "$vaultPath//note_algo_lang//Network.Journal.md"
"new"        = "$vaultPath//note_Knowledge//NewsJournal.md"
"news"       = "$vaultPath//note_Knowledge//NewsJournal.md"
"num"        = "$vaultPath//note_algo_lang//Math.Journal.md"
"nw"         = "$vaultPath//note_algo_lang//Network.Journal.md"
"ocom"       = "$vaultPath//note_Embedded//Others.IC.Journal.md"
"oic"        = "$vaultPath//note_Embedded//Others.IC.Journal.md"
"os"         = "$vaultPath//note_software//OSJournal.md"
"other"      = "$vaultPath//note_Knowledge//Other.Knowledge.Journal.md"
"para"       = "$vaultPath//note_entertainment//Device.Journal.md"
"pass"       = "$vaultPath//note_Embedded//Passive.IC.Journal.md"
"pcb"        = "$vaultPath//note_Embedded//PCBJournal.md"
"pcba"       = "$vaultPath//note_Embedded//PCBJournal.md"
"pcom"       = "$vaultPath//note_Embedded//Passive.IC.Journal.md"
"peo"        = "$vaultPath//note_Business//ConnectionJournal.md"
"people"     = "$vaultPath//note_Business//ConnectionJournal.md"
"per"        = "$vaultPath//note_entertainment//PersonalJournal.md"
"pers"       = "$vaultPath//note_entertainment//PersonalJournal.md"
"pger"       = "$vaultPath//note_Business//ConnectionJournal.md"
"phr"        = "$vaultPath//note_Knowledge//PhraseJournal.md"
"phrase"     = "$vaultPath//note_Knowledge//PhraseJournal.md"
"physic"     = "$vaultPath//note_algo_lang//STEMJournal.md"
"pic"        = "$vaultPath//note_Embedded//Passive.IC.Journal.md"
"place"      = "$vaultPath//note_Knowledge//PlacesJournal.md"
"pol"        = "$vaultPath//note_Knowledge//NewsJournal.md"
"pp"         = "$vaultPath//note_Business//ConnectionJournal.md"
"prog"       = "$vaultPath//note_algo_lang//ProgrammingJournal.md"
"prot"       = "$vaultPath//note_Embedded//ProtocolJournal.md"
"proto"      = "$vaultPath//note_Embedded//ProtocolJournal.md"
"prt"        = "$vaultPath//note_Embedded//ProtocolJournal.md"
"psy"        = "$vaultPath//note_Knowledge//LifeJournal.md"
"pw"         = "$vaultPath//note_Knowledge//secret//AccountJournal.md"
"qt"         = "$vaultPath//note_Knowledge//QuoteJournal.md"
"quote"      = "$vaultPath//note_Knowledge//QuoteJournal.md"
"read"       = "$vaultPath//note_Knowledge//ReadAndListenJournal.md"
"res"        = "$vaultPath//note_Embedded//Passive.IC.Journal.md"
"rule"       = "$vaultPath//note_Business//WorkflowJournal.md"
"sdk"        = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
"sec"        = "$vaultPath//note_algo_lang//Info.Security.Journal.md"
"self"       = "$vaultPath//note_entertainment//PersonalJournal.md"
"server"     = "$vaultPath//note_os_web//Server.Network.Journal.md"
"shape"      = "$vaultPath//note_algo_lang//Math.Journal.md"
"slang"      = "$vaultPath//note_Knowledge//PhraseJournal.md"
"soc"        = "$vaultPath//note_Embedded//ChipsetJournal.md"
"social"     = "$vaultPath//note_Business//ConnectionJournal.md"
"soft"       = "$vaultPath//note_software//SoftwareJournal.md"
"srv"        = "$vaultPath//note_os_web//Server.Network.Journal.md"
"std"        = "$vaultPath//note_algo_lang//LangJournal.md"
"stem"       = "$vaultPath//note_algo_lang//STEMJournal.md"
"stm"        = "$vaultPath//note_Embedded//FirmwareJournal.md"
"style"      = "$vaultPath//note_Business//WorkflowJournal.md"
"sv"         = "$vaultPath//note_os_web//Server.Network.Journal.md"
"sw"         = "$vaultPath//note_software//SoftwareJournal.md"
"swc"        = "$vaultPath//note_software//CLI.Terminal.Software.Journal.md"
"swg"        = "$vaultPath//note_software//GUI.Software.Journal.md"
"swgui"      = "$vaultPath//note_software//GUI.Software.Journal.md"
"swt"        = "$vaultPath//note_software//TUI.Terminal.Software.Journal.md"
"taobao"     = "$vaultPath//note_Items//TaobaoJournal.md"
"task"       = "$vaultPath//note_Business//WorkJournal.md"
"tele"       = "$vaultPath//note_entertainment//Device.Journal.md"
"three"      = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
"til"        = "$vaultPath//note_Knowledge//TIL.Knowledge.Journal.md"
"tip"        = "$vaultPath//note_Knowledge//TIL.Knowledge.Journal.md"
"tlm"        = "$vaultPath//note_entertainment//Device.Journal.md"
"triv"       = "$vaultPath//note_Knowledge//Trivia.Knowledge.Journal.md"
"tu"         = "$vaultPath//note_software//TUI.Terminal.Software.Journal.md"
"tui"        = "$vaultPath//note_software//TUI.Terminal.Software.Journal.md"
"ui"         = "$vaultPath//note_os_web//UIJournal.md"
"uiweb"      = "$vaultPath//note_os_web//Web.UI.Journal.md"
"vc"         = "$vaultPath//note_Knowledge//VocabJournal.md"
"viap"       = "$vaultPath//note_Embedded//PCBJournal.md"
"vid"        = "$vaultPath//note_entertainment//VideoJournal.md"
"video"      = "$vaultPath//note_entertainment//VideoJournal.md"
"vk"         = "$vaultPath//note_algo_lang//GraphicUIJournal.md"
"vocab"      = "$vaultPath//note_Knowledge//VocabJournal.md"
"vul"        = "$vaultPath//note_algo_lang//GraphicUIJournal.md"
"wapi"       = "$vaultPath//note_os_web//WebAPIJournal.md"
"wasm"       = "$vaultPath//note_os_web//WebProgJournal.md"
"web"        = "$vaultPath//note_software//WebJournal.md"
"webui"      = "$vaultPath//note_os_web//Web.UI.Journal.md"
"wf"         = "$vaultPath//note_Business//WorkflowJournal.md"
"wfr"        = "$vaultPath//note_os_web//SDK-Framework.Web.Journal.md"
"wfw"        = "$vaultPath//note_os_web//SDK-Framework.Web.Journal.md"
"windows"    = "$vaultPath//note_software//OSJournal.md"
"wire"       = "$vaultPath//note_Embedded//ProtocolJournal.md"
"wlib"       = "$vaultPath//note_os_web//WebAPIJournal.md"
"work"       = "$vaultPath//note_Business//WorkJournal.md"
"workflow"   = "$vaultPath//note_Business//WorkflowJournal.md"
"wpro"       = "$vaultPath//note_os_web//WebProgJournal.md"
"wprog"      = "$vaultPath//note_os_web//WebProgJournal.md"
"wsdk"       = "$vaultPath//note_os_web//SDK-Framework.Web.Journal.md"
"wui"        = "$vaultPath//note_os_web//Web.UI.Journal.md"
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
