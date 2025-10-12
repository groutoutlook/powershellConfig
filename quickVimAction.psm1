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
$global:jtb = @{
"three"= "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
"lang"= "$vaultPath//note_algo_lang//LangJournal.md"
"book"= "$vaultPath//note_Knowledge//ReadAndListenJournal.md"
"opin"= "$vaultPath//note_Knowledge//Opinion.Journal.md"
"med"= "$vaultPath//note_Knowledge//Medical.Knowledge.Journal.md"
"wfw"= "$vaultPath//note_os_web//SDK-Framework.Web.Journal.md"
"api"= "$vaultPath//note_algo_lang//LibraryJournal.md"
"wprog"= "$vaultPath//note_os_web//WebProgJournal.md"
"windows"= "$vaultPath//note_software//OSJournal.md"
"hard"= "$vaultPath//note_Embedded//HardwareJournal.md"
"read"= "$vaultPath//note_Knowledge//ReadAndListenJournal.md"
"phr"= "$vaultPath//note_Knowledge//PhraseJournal.md"
"scr"= "$vaultPath//note_Knowledge//Rad-Script.Journal.md"
"prog"= "$vaultPath//note_algo_lang//ProgrammingJournal.md"
"srv"= "$vaultPath//note_os_web//Server.Network.Journal.md"
"style"= "$vaultPath//note_Business//WorkflowJournal.md"
"pp"= "$vaultPath//note_Business//ConnectionJournal.md"
"like"= "$vaultPath//note_entertainment//PersonalJournal.md"
"proto"= "$vaultPath//note_Embedded//ProtocolJournal.md"
"al"= "$vaultPath//note_algo_lang//Algorithm.Journal.md"
"comp"= "$vaultPath//note_Embedded//ComponentJournal.md"
"wf"= "$vaultPath//note_Business//WorkflowJournal.md"
"pw"= "$vaultPath//note_Knowledge//secret//AccountJournal.md"
"taobao"= "$vaultPath//note_Items//TaobaoJournal.md"
"vc"= "$vaultPath//note_Knowledge//VocabJournal.md"
"day"= "$vaultPath//note_entertainment//Diary.Journal.md"
"krita"= "$vaultPath//note_IDEAndTools//Multimedia.Journal.md"
"backend"= "$vaultPath//note_os_web//Server.Network.Journal.md"
"media"= "$vaultPath//note_Knowledge//NewsJournal.md"
"img"= "$vaultPath//note_IDEAndTools//Multimedia.Journal.md"
"ev"= "$vaultPath//note_Knowledge//EventJournal.md"
"sw"= "$vaultPath//note_software//SoftwareJournal.md"
"item"= "$vaultPath//note_Items//OtherItemsJournal.md"
"prt"= "$vaultPath//note_Embedded//ProtocolJournal.md"
"web"= "$vaultPath//note_software//WebJournal.md"
"ui"= "$vaultPath//note_os_web//UIJournal.md"
"wlib"= "$vaultPath//note_os_web//WebAPIJournal.md"
"music"= "$vaultPath//note_entertainment//MusicJournal.md"
"inte"= "$vaultPath//note_Embedded//ProtocolJournal.md"
"hdk"= "$vaultPath//note_Embedded//HDK.Hardware.Journal.md"
"hack"= "$vaultPath//note_Knowledge//LifeHackJournal.md"
"tlm"= "$vaultPath//note_entertainment//Device.Journal.md"
"image"= "$vaultPath//note_IDEAndTools//Multimedia.Journal.md"
"ali"= "$vaultPath//note_Items//1688Journal.md"
"ety"= "$vaultPath//note_Knowledge//PhraseJournal.md"
"gui"= "$vaultPath//note_software//GUI.Software.Journal.md"
":3"= "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
"swgui"= "$vaultPath//note_software//GUI.Software.Journal.md"
"soc"= "$vaultPath//note_Embedded//ChipsetJournal.md"
"blog"= "$vaultPath//note_Knowledge//ReadAndListenJournal.md"
"per"= "$vaultPath//note_entertainment//PersonalJournal.md"
"wfr"= "$vaultPath//note_os_web//SDK-Framework.Web.Journal.md"
"acro"= "$vaultPath//note_Knowledge//AcronymJournal.md"
"idea"= "$vaultPath//note_Business//IdeaJournal.md"
"society"= "$vaultPath//note_Knowledge//Culture.Journal.md"
"qt"= "$vaultPath//note_Knowledge//QuoteJournal.md"
"wire"= "$vaultPath//note_Embedded//ProtocolJournal.md"
"oic"= "$vaultPath//note_Embedded//Others.IC.Journal.md"
"gra"= "$vaultPath//note_algo_lang//GraphicUIJournal.md"
"edit"= "$vaultPath//note_IDEAndTools//Multimedia.Journal.md"
"matrix"= "$vaultPath//note_algo_lang//Algebra.Math.Journal.md"
"script"= "$vaultPath//note_Knowledge//Rad-Script.Journal.md"
"cul"= "$vaultPath//note_Knowledge//Culture.Journal.md"
"be"= "$vaultPath//note_os_web//Server.Network.Journal.md"
"ms"= "$vaultPath//note_entertainment//MusicJournal.md"
"lhack"= "$vaultPath//note_Knowledge//LifeHackJournal.md"
"tu"= "$vaultPath//note_software//TUI.Terminal.Software.Journal.md"
"magnum"= "$vaultPath//note_Knowledge//Personal.Idea.Journal.md"
"buildsystem"= "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
":1"= "$vaultPath//note_Items//1688Journal.md"
"default"= "$vaultPath//MainJournal.md"
"pcba"= "$vaultPath//note_Embedded//PCBJournal.md"
"wapi"= "$vaultPath//note_os_web//WebAPIJournal.md"
"peo"= "$vaultPath//note_Business//ConnectionJournal.md"
"olds"= "$vaultPath//note_Knowledge//History.Event.Journal.md"
"model"= "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
"myrule"= "$vaultPath//note_Business//WorkflowJournal.md"
"pers"= "$vaultPath//note_entertainment//PersonalJournal.md"
"vocab"= "$vaultPath//note_Knowledge//VocabJournal.md"
"cult"= "$vaultPath//note_Knowledge//Culture.Journal.md"
"phil"= "$vaultPath//note_Knowledge//Psychology.Journal.md"
"social"= "$vaultPath//note_Business//ConnectionJournal.md"
"workflow"= "$vaultPath//note_Business//WorkflowJournal.md"
"sv"= "$vaultPath//note_os_web//Server.Network.Journal.md"
"design"= "$vaultPath//note_os_web//UX.Design.Journal.md"
"dev"= "$vaultPath//note_entertainment//Device.Journal.md"
"cve"= "$vaultPath//note_algo_lang//Info.Security.Journal.md"
"interest"= "$vaultPath//note_entertainment//PersonalJournal.md"
"misc"= "$vaultPath//note_Knowledge//Trivia.Knowledge.Journal.md"
"ana"= "$vaultPath//note_Knowledge//Medical.Knowledge.Journal.md"
"life"= "$vaultPath//note_Knowledge//LifeJournal.md"
"past"= "$vaultPath//note_Knowledge//Personal.Past.Event.Journal.md"
"fcad"= "$vaultPath//note_IDEAndTools//CADJournal.md"
"tip"= "$vaultPath//note_Knowledge//TIL.Knowledge.Journal.md"
"list"= "$vaultPath//note_Knowledge//Meta.Journal.md"
"bb"= "$vaultPath//note_Embedded//HDK.Hardware.Journal.md"
"motto"= "$vaultPath//note_Knowledge//Personal.Idea.Journal.md"
"sdk"= "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
"ux"= "$vaultPath//note_os_web//UX.Design.Journal.md"
"wasm"= "$vaultPath//note_os_web//WebProgJournal.md"
"pid"= "$vaultPath//note_Knowledge//Personal.Idea.Journal.md"
"know"= "$vaultPath//note_Knowledge//Other.Knowledge.Journal.md"
"agg"= "$vaultPath//note_Knowledge//Meta.Journal.md"
"peak"= "$vaultPath//note_Knowledge//Personal.Idea.Journal.md"
"pcb"= "$vaultPath//note_Embedded//PCBJournal.md"
"pic"= "$vaultPath//note_Embedded//Passive.IC.Journal.md"
"wsdk"= "$vaultPath//note_os_web//SDK-Framework.Web.Journal.md"
"soe"= "$vaultPath//note_Knowledge//Culture.Journal.md"
"tele"= "$vaultPath//note_entertainment//Device.Journal.md"
"csci"= "$vaultPath//note_algo_lang//CompSciJournal.md"
"hist"= "$vaultPath//note_Knowledge//History.Event.Journal.md"
"news"= "$vaultPath//note_Knowledge//NewsJournal.md"
"quo"= "$vaultPath//note_Knowledge//QuoteJournal.md"
"soft"= "$vaultPath//note_software//SoftwareJournal.md"
"chem"= "$vaultPath//note_algo_lang//Chemistry.Journal.md"
"graph"= "$vaultPath//note_algo_lang//GraphicUIJournal.md"
"old"= "$vaultPath//note_Knowledge//History.Event.Journal.md"
"ic"= "$vaultPath//note_Embedded//ChipsetJournal.md"
"alge"= "$vaultPath//note_algo_lang//Algebra.Math.Journal.md"
"vul"= "$vaultPath//note_algo_lang//GraphicUIJournal.md"
"algo"= "$vaultPath//note_algo_lang//Algorithm.Journal.md"
"cli"= "$vaultPath//note_software//CLI.Terminal.Software.Journal.md"
"fsdk"= "$vaultPath//note_os_web//SDK-Framework.Firmware.Journal.md"
"webui"= "$vaultPath//note_os_web//Web.UI.Journal.md"
"op"= "$vaultPath//note_Knowledge//Opinion.Journal.md"
"swt"= "$vaultPath//note_software//TUI.Terminal.Software.Journal.md"
"phrase"= "$vaultPath//note_Knowledge//PhraseJournal.md"
"server"= "$vaultPath//note_os_web//Server.Network.Journal.md"
"ltip"= "$vaultPath//note_Knowledge//LifeHackJournal.md"
"asset"= "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
"os"= "$vaultPath//note_software//OSJournal.md"
"vk"= "$vaultPath//note_algo_lang//GraphicUIJournal.md"
"linux"= "$vaultPath//note_software//OSJournal.md"
"nw"= "$vaultPath//note_algo_lang//Network.Journal.md"
"diary"= "$vaultPath//note_entertainment//Diary.Journal.md"
"freecad"= "$vaultPath//note_IDEAndTools//CADJournal.md"
"thes"= "$vaultPath//note_Knowledge//Personal.Idea.Journal.md"
"cad3d"= "$vaultPath//note_IDEAndTools//CADJournal.md"
"swg"= "$vaultPath//note_software//GUI.Software.Journal.md"
"pre"= "$vaultPath//note_Knowledge//Prediction.Event.Journal.md"
"pol"= "$vaultPath//note_Knowledge//NewsJournal.md"
"come"= "$vaultPath//note_Knowledge//WholesomeJournal.md"
"place"= "$vaultPath//note_Knowledge//PlacesJournal.md"
"para"= "$vaultPath//note_entertainment//Device.Journal.md"
"fe"= "$vaultPath//note_os_web//UIJournal.md"
"other"= "$vaultPath//note_Knowledge//Other.Knowledge.Journal.md"
"thought"= "$vaultPath//note_Knowledge//Personal.Psychology.Journal.md"
"mcad"= "$vaultPath//note_IDEAndTools//CADJournal.md"
"prot"= "$vaultPath//note_Embedded//ProtocolJournal.md"
"ecad"= "$vaultPath//note_Embedded//EDAJournal.md"
"phy"= "$vaultPath//note_algo_lang//STEMJournal.md"
"cap"= "$vaultPath//note_Embedded//Passive.IC.Journal.md"
"humor"= "$vaultPath//note_Knowledge//WholesomeJournal.md"
"stem"= "$vaultPath//note_algo_lang//STEMJournal.md"
"swc"= "$vaultPath//note_software//CLI.Terminal.Software.Journal.md"
"acc"= "$vaultPath//note_Knowledge//secret//AccountJournal.md"
"std"= "$vaultPath//note_algo_lang//LangJournal.md"
"kicad"= "$vaultPath//note_Embedded//EDAJournal.md"
"anim"= "$vaultPath//note_Knowledge//Biology.Science.Journal.md"
"module"= "$vaultPath//note_Embedded//ChipsetJournal.md"
"geom"= "$vaultPath//note_algo_lang//Math.Journal.md"
"retro"= "$vaultPath//note_Knowledge//Personal.Past.Event.Journal.md"
"uiweb"= "$vaultPath//note_os_web//Web.UI.Journal.md"
"quote"= "$vaultPath//note_Knowledge//QuoteJournal.md"
"laugh"= "$vaultPath//note_Knowledge//WholesomeJournal.md"
"infosec"= "$vaultPath//note_algo_lang//Info.Security.Journal.md"
"wui"= "$vaultPath//note_os_web//Web.UI.Journal.md"
"ide"= "$vaultPath//note_IDEAndTools//IDE.Journal.md"
"tech"= "$vaultPath//note_Knowledge//Trivia.Technologia.Journal.md"
"rule"= "$vaultPath//note_Business//WorkflowJournal.md"
"isec"= "$vaultPath//note_algo_lang//Info.Security.Journal.md"
"mental"= "$vaultPath//note_Knowledge//Personal.Psychology.Journal.md"
"human"= "$vaultPath//note_Knowledge//Psychology.Journal.md"
"net"= "$vaultPath//note_algo_lang//Network.Journal.md"
"ietf"= "$vaultPath//note_Embedded//ProtocolJournal.md"
"econ"= "$vaultPath//note_Knowledge//EconomyJournal.md"
"fw"= "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
"pger"= "$vaultPath//note_Business//ConnectionJournal.md"
"netw"= "$vaultPath//note_algo_lang//Network.Journal.md"
"meta"= "$vaultPath//note_Knowledge//Meta.Journal.md"
"tui"= "$vaultPath//note_software//TUI.Terminal.Software.Journal.md"
"trit"= "$vaultPath//note_Knowledge//Trivia.Technologia.Journal.md"
"cash"= "$vaultPath//note_Business//MoneyJournal.md"
":3d"= "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
"mind"= "$vaultPath//note_Knowledge//Personal.Psychology.Journal.md"
"math"= "$vaultPath//note_algo_lang//Math.Journal.md"
"conn"= "$vaultPath//note_Business//ConnectionJournal.md"
"build"= "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
"mcu"= "$vaultPath//note_Embedded//MCU.IC.Journal.md"
"task"= "$vaultPath//note_Business//WorkJournal.md"
"emb"= "$vaultPath//note_Embedded//FirmwareJournal.md"
"icother"= "$vaultPath//note_Embedded//Others.IC.Journal.md"
"self"= "$vaultPath//note_entertainment//PersonalJournal.md"
"slang"= "$vaultPath//note_Knowledge//PhraseJournal.md"
"fr"= "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
"res"= "$vaultPath//note_Embedded//Passive.IC.Journal.md"
"wpro"= "$vaultPath//note_os_web//WebProgJournal.md"
"cpp"= "$vaultPath//note_algo_lang//LangJournal.md"
"gpu"= "$vaultPath//note_algo_lang//GraphicUIJournal.md"
"arg"= "$vaultPath//note_Knowledge//Opinion.Journal.md"
"ps"= "$vaultPath//note_IDEAndTools//Multimedia.Journal.md"
"etym"= "$vaultPath//note_Knowledge//PhraseJournal.md"
"sec"= "$vaultPath//note_algo_lang//Info.Security.Journal.md"
"mech"= "$vaultPath//note_algo_lang//Mechanic.Journal.md"
"new"= "$vaultPath//note_Knowledge//NewsJournal.md"
"devb"= "$vaultPath//note_Embedded//HDK.Hardware.Journal.md"
"trvt"= "$vaultPath//note_Knowledge//Trivia.Technologia.Journal.md"
"cs"= "$vaultPath//note_algo_lang//CompSciJournal.md"
"cl"= "$vaultPath//note_software//CLI.Terminal.Software.Journal.md"
"triv"= "$vaultPath//note_Knowledge//Trivia.Knowledge.Journal.md"
"vid"= "$vaultPath//note_entertainment//VideoJournal.md"
"ico"= "$vaultPath//note_Embedded//Others.IC.Journal.md"
"gsw"= "$vaultPath//note_software//GUI.Software.Journal.md"
"embed"= "$vaultPath//note_Embedded//FirmwareJournal.md"
"firm"= "$vaultPath//note_Embedded//FirmwareJournal.md"
"trivt"= "$vaultPath//note_Knowledge//Trivia.Technologia.Journal.md"
"video"= "$vaultPath//note_entertainment//VideoJournal.md"
"shape"= "$vaultPath//note_algo_lang//Math.Journal.md"
"fm"= "$vaultPath//note_IDEAndTools//File-Format.Journal.md"
"elec"= "$vaultPath//note_Embedded//Electric.Journal.md"
"bus"= "$vaultPath//note_Embedded//ProtocolJournal.md"
"hw"= "$vaultPath//note_Embedded//HardwareJournal.md"
"event"= "$vaultPath//note_Knowledge//EventJournal.md"
"evb"= "$vaultPath//note_Embedded//HDK.Hardware.Journal.md"
"cad"= "$vaultPath//note_IDEAndTools//CADJournal.md"
"blend"= "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
"ocom"= "$vaultPath//note_Embedded//Others.IC.Journal.md"
"meme"= "$vaultPath//note_Knowledge//WholesomeJournal.md"
"ss"= "$vaultPath//note_Knowledge//Rad-Script.Journal.md"
"ee"= "$vaultPath//note_Embedded//Electric.Journal.md"
"num"= "$vaultPath//note_algo_lang//Math.Journal.md"
"eco"= "$vaultPath//note_Knowledge//EconomyJournal.md"
"pred"= "$vaultPath//note_Knowledge//Prediction.Event.Journal.md"
"bio"= "$vaultPath//note_Knowledge//Biology.Science.Journal.md"
"draw"= "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
"css"= "$vaultPath//note_os_web//Web.UI.Journal.md"
"technologia"= "$vaultPath//note_Knowledge//Trivia.Technologia.Journal.md"
"frontend"= "$vaultPath//note_os_web//UIJournal.md"
"til"= "$vaultPath//note_Knowledge//TIL.Knowledge.Journal.md"
"evk"= "$vaultPath//note_Embedded//HDK.Hardware.Journal.md"
"frame"= "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
"html"= "$vaultPath//note_os_web//Web.UI.Journal.md"
"is"= "$vaultPath//note_algo_lang//Info.Security.Journal.md"
"chip"= "$vaultPath//note_Embedded//ChipsetJournal.md"
"vd"= "$vaultPath//note_IDEAndTools//Multimedia.Journal.md"
"fi"= "$vaultPath//note_Embedded//FirmwareJournal.md"
"money"= "$vaultPath//note_Business//MoneyJournal.md"
"fiw"= "$vaultPath//note_Embedded//FirmwareJournal.md"
"inst"= "$vaultPath//note_os_web//SDK-Framework.Firmware.Journal.md"
"lib"= "$vaultPath//note_algo_lang//LibraryJournal.md"
"file"= "$vaultPath//note_IDEAndTools//File-Format.Journal.md"
"eda"= "$vaultPath//note_Embedded//EDAJournal.md"
"busy"= "$vaultPath//note_Business//WorkJournal.md"
"physic"= "$vaultPath//note_algo_lang//STEMJournal.md"
"pass"= "$vaultPath//note_Embedded//Passive.IC.Journal.md"
"pcom"= "$vaultPath//note_Embedded//Passive.IC.Journal.md"
"oth"= "$vaultPath//note_Knowledge//Other.Knowledge.Journal.md"
"people"= "$vaultPath//note_Business//ConnectionJournal.md"
"daily"= "$vaultPath//note_entertainment//Diary.Journal.md"
"psy"= "$vaultPath//note_Knowledge//Psychology.Journal.md"
"bs"= "$vaultPath//note_Business//WorkJournal.md"
"stip"= "$vaultPath//note_Knowledge//Personal.Idea.Journal.md"
"art"= "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
"stm"= "$vaultPath//note_Embedded//FirmwareJournal.md"
"diss"= "$vaultPath//note_Knowledge//Opinion.Journal.md"
"probe"= "$vaultPath//note_Embedded//HDK.Hardware.Journal.md"
":1688"= "$vaultPath//note_Items//1688Journal.md"
"work"= "$vaultPath//note_Business//WorkJournal.md"
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
        $phrase = $jtb[$inputString]
        if ($phrase -eq $null) {
            # Second chance to match the phrase.
      
            if (($inputString -match "j$") -or ($inputString -match " $")) {
                $clippedPhrase = $inputString -replace " $" -replace "j$" 
                $phrase = $jtb[$clippedPhrase]
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

function jvc{
    j vc 10
}

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
