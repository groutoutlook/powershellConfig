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
    "probe"       = "$vaultPath//note_Embedded//HDK.Hardware.Journal.md"
    "buildsystem" = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
    "embed"       = "$vaultPath//note_Embedded//FirmwareJournal.md"
    "prt"         = "$vaultPath//note_Embedded//ProtocolJournal.md"
    ":3"          = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "work"        = "$vaultPath//note_Business//WorkJournal.md"
    "soe"         = "$vaultPath//note_Knowledge//Culture.Journal.md"
    "wf"          = "$vaultPath//note_Business//WorkflowJournal.md"
    "snip"        = "$vaultPath//note_Knowledge//Rad-Script.Journal.md"
    "stem"        = "$vaultPath//note_algo_lang//STEMJournal.md"
    "diary"       = "$vaultPath//note_entertainment//Diary.Journal.md"
    "stip"        = "$vaultPath//note_Knowledge//Personal.Idea.Journal.md"
    "phrase"      = "$vaultPath//note_Knowledge//PhraseJournal.md"
    "opin"        = "$vaultPath//note_Knowledge//Opinion.Journal.md"
    "acro"        = "$vaultPath//note_Knowledge//AcronymJournal.md"
    "oic"         = "$vaultPath//note_Embedded//Others.IC.Journal.md"
    "pger"        = "$vaultPath//note_Business//ConnectionJournal.md"
    "inst"        = "$vaultPath//note_os_web//SDK-Framework.Firmware.Journal.md"
    "evk"         = "$vaultPath//note_Embedded//HDK.Hardware.Journal.md"
    "interest"    = "$vaultPath//note_entertainment//PersonalJournal.md"
    "ety"         = "$vaultPath//note_Knowledge//PhraseJournal.md"
    "diss"        = "$vaultPath//note_Knowledge//Discussion.Topic.Journal.md"
    "mental"      = "$vaultPath//note_Knowledge//Personal.Psychology.Journal.md"
    "thought"     = "$vaultPath//note_Knowledge//Personal.Psychology.Journal.md"
    "econ"        = "$vaultPath//note_Knowledge//EconomyJournal.md"
    "swgui"       = "$vaultPath//note_software//GUI.Software.Journal.md"
    "comp"        = "$vaultPath//note_Embedded//ComponentJournal.md"
    "phil"        = "$vaultPath//note_Knowledge//Psychology.Journal.md"
    "acc"         = "$vaultPath//note_Knowledge//secret//AccountJournal.md"
    "pass"        = "$vaultPath//note_Embedded//Passive.IC.Journal.md"
    "module"      = "$vaultPath//note_Embedded//ChipsetJournal.md"
    "three"       = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "vid"         = "$vaultPath//note_entertainment//VideoJournal.md"
    "fm"          = "$vaultPath//note_IDEAndTools//File-Format.Journal.md"
    "demob"       = "$vaultPath//note_Embedded//EVB.Hardware.Journal.md"
    "stm"         = "$vaultPath//note_Embedded//FirmwareJournal.md"
    "img"         = "$vaultPath//note_IDEAndTools//Multimedia.Journal.md"
    "media"       = "$vaultPath//note_Knowledge//NewsJournal.md"
    "ee"          = "$vaultPath//note_Embedded//Electric.Journal.md"
    "social"      = "$vaultPath//note_Business//ConnectionJournal.md"
    "fiw"         = "$vaultPath//note_Embedded//FirmwareJournal.md"
    "shape"       = "$vaultPath//note_algo_lang//Math.Journal.md"
    "cli"         = "$vaultPath//note_software//CLI.Terminal.Software.Journal.md"
    "task"        = "$vaultPath//note_Business//WorkJournal.md"
    "hack"        = "$vaultPath//note_Knowledge//LifeHackJournal.md"
    "chem"        = "$vaultPath//note_algo_lang//Chemistry.Journal.md"
    "vul"         = "$vaultPath//note_algo_lang//GraphicUIJournal.md"
    "peak"        = "$vaultPath//note_Knowledge//Personal.Idea.Journal.md"
    "lhack"       = "$vaultPath//note_Knowledge//LifeHackJournal.md"
    "fsdk"        = "$vaultPath//note_os_web//SDK-Framework.Firmware.Journal.md"
    "tele"        = "$vaultPath//note_entertainment//Device.Journal.md"
    "gsw"         = "$vaultPath//note_software//GUI.Software.Journal.md"
    "res"         = "$vaultPath//note_Embedded//Passive.IC.Journal.md"
    "human"       = "$vaultPath//note_Knowledge//Psychology.Journal.md"
    "cash"        = "$vaultPath//note_Business//MoneyJournal.md"
    "design"      = "$vaultPath//note_os_web//UX.Design.Journal.md"
    "hard"        = "$vaultPath//note_Embedded//HardwareJournal.md"
    "script"      = "$vaultPath//note_Knowledge//Rad-Script.Journal.md"
    "ss"          = "$vaultPath//note_Knowledge//Rad-Script.Journal.md"
    "emb"         = "$vaultPath//note_Embedded//FirmwareJournal.md"
    "ps"          = "$vaultPath//note_IDEAndTools//Multimedia.Journal.md"
    "technologia" = "$vaultPath//note_Knowledge//Trivia.Technologia.Journal.md"
    "blog"        = "$vaultPath//note_Knowledge//ReadAndListenJournal.md"
    "tech"        = "$vaultPath//note_Knowledge//Trivia.Technologia.Journal.md"
    "vd"          = "$vaultPath//note_IDEAndTools//Multimedia.Journal.md"
    "std"         = "$vaultPath//note_algo_lang//LangJournal.md"
    "gra"         = "$vaultPath//note_algo_lang//GraphicUIJournal.md"
    "bb"          = "$vaultPath//note_Embedded//HDK.Hardware.Journal.md"
    "lib"         = "$vaultPath//note_algo_lang//LibraryJournal.md"
    "wsdk"        = "$vaultPath//note_os_web//SDK-Framework.Web.Journal.md"
    "wlib"        = "$vaultPath//note_os_web//WebAPIJournal.md"
    "gpu"         = "$vaultPath//note_algo_lang//GraphicUIJournal.md"
    "lang"        = "$vaultPath//note_algo_lang//LangJournal.md"
    "al"          = "$vaultPath//note_algo_lang//Algorithm.Journal.md"
    "soc"         = "$vaultPath//note_Embedded//ChipsetJournal.md"
    "new"         = "$vaultPath//note_Knowledge//NewsJournal.md"
    "mcu"         = "$vaultPath//note_Embedded//MCU.IC.Journal.md"
    "cul"         = "$vaultPath//note_Knowledge//Culture.Journal.md"
    "asset"       = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "people"      = "$vaultPath//note_Business//ConnectionJournal.md"
    "ietf"        = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "sdk"         = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
    "cpld"        = "$vaultPath//note_Embedded//FPGA-CPLD.IC.Journal.md"
    "qt"          = "$vaultPath//note_Knowledge//QuoteJournal.md"
    "pcom"        = "$vaultPath//note_Embedded//Passive.IC.Journal.md"
    "laugh"       = "$vaultPath//note_Knowledge//WholesomeJournal.md"
    "model"       = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "pw"          = "$vaultPath//note_Knowledge//secret//AccountJournal.md"
    "style"       = "$vaultPath//note_Business//WorkflowJournal.md"
    "file"        = "$vaultPath//note_IDEAndTools//File-Format.Journal.md"
    "math"        = "$vaultPath//note_algo_lang//Math.Journal.md"
    "para"        = "$vaultPath//note_entertainment//Device.Journal.md"
    "alge"        = "$vaultPath//note_algo_lang//Algebra.Math.Journal.md"
    "board"       = "$vaultPath//note_Embedded//EVB.Hardware.Journal.md"
    "anim"        = "$vaultPath//note_Knowledge//Biology.Science.Journal.md"
    "mech"        = "$vaultPath//note_algo_lang//Mechanic.Journal.md"
    "med"         = "$vaultPath//note_Knowledge//Medical.Knowledge.Journal.md"
    "pcb"         = "$vaultPath//note_Embedded//PCBJournal.md"
    "hist"        = "$vaultPath//note_Knowledge//History.Event.Journal.md"
    "webui"       = "$vaultPath//note_os_web//Web.UI.Journal.md"
    "art"         = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "physic"      = "$vaultPath//note_algo_lang//STEMJournal.md"
    "ocom"        = "$vaultPath//note_Embedded//Others.IC.Journal.md"
    "ev"          = "$vaultPath//note_Knowledge//EventJournal.md"
    "myrule"      = "$vaultPath//note_Business//WorkflowJournal.md"
    "vc"          = "$vaultPath//note_Knowledge//VocabJournal.md"
    "money"       = "$vaultPath//note_Business//MoneyJournal.md"
    "freecad"     = "$vaultPath//note_IDEAndTools//CADJournal.md"
    "swt"         = "$vaultPath//note_software//TUI.Terminal.Software.Journal.md"
    "num"         = "$vaultPath//note_algo_lang//Math.Journal.md"
    "trit"        = "$vaultPath//note_Knowledge//Trivia.Technologia.Journal.md"
    "past"        = "$vaultPath//note_Knowledge//Personal.Past.Event.Journal.md"
    "olds"        = "$vaultPath//note_Knowledge//History.Event.Journal.md"
    "triv"        = "$vaultPath//note_Knowledge//Trivia.Knowledge.Journal.md"
    "cve"         = "$vaultPath//note_algo_lang//Info.Security.Journal.md"
    "ali"         = "$vaultPath//note_Items//1688Journal.md"
    "swc"         = "$vaultPath//note_software//CLI.Terminal.Software.Journal.md"
    "pcba"        = "$vaultPath//note_Embedded//PCBJournal.md"
    "list"        = "$vaultPath//note_Knowledge//Meta.Journal.md"
    "rf"          = "$vaultPath//note_Embedded//RF-Wireless.Journal.md"
    "video"       = "$vaultPath//note_entertainment//VideoJournal.md"
    "ms"          = "$vaultPath//note_entertainment//MusicJournal.md"
    "kicad"       = "$vaultPath//note_Embedded//EDAJournal.md"
    "proto"       = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "music"       = "$vaultPath//note_entertainment//MusicJournal.md"
    "draw"        = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "fi"          = "$vaultPath//note_Embedded//FirmwareJournal.md"
    "pp"          = "$vaultPath//note_Business//ConnectionJournal.md"
    "life"        = "$vaultPath//note_Knowledge//LifeJournal.md"
    "cult"        = "$vaultPath//note_Knowledge//Culture.Journal.md"
    "wpro"        = "$vaultPath//note_os_web//WebProgJournal.md"
    "busy"        = "$vaultPath//note_Business//WorkJournal.md"
    "graph"       = "$vaultPath//note_algo_lang//GraphicUIJournal.md"
    "sw"          = "$vaultPath//note_software//SoftwareJournal.md"
    "frame"       = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
    "cs"          = "$vaultPath//note_algo_lang//CompSciJournal.md"
    "linux"       = "$vaultPath//note_software//OSJournal.md"
    "sv"          = "$vaultPath//note_os_web//Server.Network.Journal.md"
    "know"        = "$vaultPath//note_Knowledge//Other.Knowledge.Journal.md"
    "csci"        = "$vaultPath//note_algo_lang//CompSciJournal.md"
    "cad"         = "$vaultPath//note_IDEAndTools//CADJournal.md"
    "news"        = "$vaultPath//note_Knowledge//NewsJournal.md"
    "wfw"         = "$vaultPath//note_os_web//SDK-Framework.Web.Journal.md"
    "gui"         = "$vaultPath//note_software//GUI.Software.Journal.md"
    "ana"         = "$vaultPath//note_Knowledge//Medical.Knowledge.Journal.md"
    "workflow"    = "$vaultPath//note_Business//WorkflowJournal.md"
    "ecad"        = "$vaultPath//note_Embedded//EDAJournal.md"
    "tlm"         = "$vaultPath//note_entertainment//Device.Journal.md"
    "netw"        = "$vaultPath//note_algo_lang//Network.Journal.md"
    "rtl"         = "$vaultPath//note_Embedded//FPGA-CPLD.IC.Journal.md"
    "isec"        = "$vaultPath//note_algo_lang//Info.Security.Journal.md"
    "per"         = "$vaultPath//note_entertainment//PersonalJournal.md"
    "society"     = "$vaultPath//note_Knowledge//Culture.Journal.md"
    "ico"         = "$vaultPath//note_Embedded//Others.IC.Journal.md"
    "default"     = "$vaultPath//MainJournal.md"
    ":1"          = "$vaultPath//note_Items//1688Journal.md"
    "meta"        = "$vaultPath//note_Knowledge//Meta.Journal.md"
    "tu"          = "$vaultPath//note_software//TUI.Terminal.Software.Journal.md"
    "fcad"        = "$vaultPath//note_IDEAndTools//CADJournal.md"
    "taobao"      = "$vaultPath//note_Items//TaobaoJournal.md"
    "net"         = "$vaultPath//note_algo_lang//Network.Journal.md"
    "op"          = "$vaultPath//note_Knowledge//Opinion.Journal.md"
    "quote"       = "$vaultPath//note_Knowledge//QuoteJournal.md"
    "pre"         = "$vaultPath//note_Knowledge//Prediction.Event.Journal.md"
    "retro"       = "$vaultPath//note_Knowledge//Personal.Past.Event.Journal.md"
    ":3d"         = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "rfid"        = "$vaultPath//note_Embedded//RF-Wireless.Journal.md"
    "css"         = "$vaultPath//note_os_web//Web.UI.Journal.md"
    "psy"         = "$vaultPath//note_Knowledge//Psychology.Journal.md"
    "build"       = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
    "pol"         = "$vaultPath//note_Knowledge//NewsJournal.md"
    "is"          = "$vaultPath//note_algo_lang//Info.Security.Journal.md"
    "ltip"        = "$vaultPath//note_Knowledge//LifeHackJournal.md"
    "etym"        = "$vaultPath//note_Knowledge//PhraseJournal.md"
    "til"         = "$vaultPath//note_Knowledge//TIL.Knowledge.Journal.md"
    "tui"         = "$vaultPath//note_software//TUI.Terminal.Software.Journal.md"
    "like"        = "$vaultPath//note_entertainment//PersonalJournal.md"
    "motto"       = "$vaultPath//note_Knowledge//Personal.Idea.Journal.md"
    "bus"         = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "matrix"      = "$vaultPath//note_algo_lang//Algebra.Math.Journal.md"
    "krita"       = "$vaultPath//note_IDEAndTools//Multimedia.Journal.md"
    "os"          = "$vaultPath//note_software//OSJournal.md"
    "algo"        = "$vaultPath//note_algo_lang//Algorithm.Journal.md"
    "devb"        = "$vaultPath//note_Embedded//EVB.Hardware.Journal.md"
    "item"        = "$vaultPath//note_Items//OtherItemsJournal.md"
    ":1688"       = "$vaultPath//note_Items//1688Journal.md"
    "fw"          = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
    "geom"        = "$vaultPath//note_algo_lang//Math.Journal.md"
    "mind"        = "$vaultPath//note_Knowledge//Personal.Psychology.Journal.md"
    "trvt"        = "$vaultPath//note_Knowledge//Trivia.Technologia.Journal.md"
    "place"       = "$vaultPath//note_Knowledge//PlacesJournal.md"
    "icother"     = "$vaultPath//note_Embedded//Others.IC.Journal.md"
    "book"        = "$vaultPath//note_Knowledge//ReadAndListenJournal.md"
    "conn"        = "$vaultPath//note_Business//ConnectionJournal.md"
    "rule"        = "$vaultPath//note_Business//WorkflowJournal.md"
    "pers"        = "$vaultPath//note_entertainment//PersonalJournal.md"
    "read"        = "$vaultPath//note_Knowledge//ReadAndListenJournal.md"
    "evb"         = "$vaultPath//note_Embedded//EVB.Hardware.Journal.md"
    "inte"        = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "fe"          = "$vaultPath//note_os_web//UIJournal.md"
    "vk"          = "$vaultPath//note_algo_lang//GraphicUIJournal.md"
    "hw"          = "$vaultPath//note_Embedded//HardwareJournal.md"
    "phr"         = "$vaultPath//note_Knowledge//PhraseJournal.md"
    "html"        = "$vaultPath//note_os_web//Web.UI.Journal.md"
    "prot"        = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "tip"         = "$vaultPath//note_Knowledge//TIL.Knowledge.Journal.md"
    "server"      = "$vaultPath//note_os_web//Server.Network.Journal.md"
    "ic"          = "$vaultPath//note_Embedded//ChipsetJournal.md"
    "slang"       = "$vaultPath//note_Knowledge//PhraseJournal.md"
    "hdk"         = "$vaultPath//note_Embedded//HDK.Hardware.Journal.md"
    "pred"        = "$vaultPath//note_Knowledge//Prediction.Event.Journal.md"
    "cl"          = "$vaultPath//note_software//CLI.Terminal.Software.Journal.md"
    "swg"         = "$vaultPath//note_software//GUI.Software.Journal.md"
    "daily"       = "$vaultPath//note_entertainment//Diary.Journal.md"
    "quo"         = "$vaultPath//note_Knowledge//QuoteJournal.md"
    "peo"         = "$vaultPath//note_Business//ConnectionJournal.md"
    "vocab"       = "$vaultPath//note_Knowledge//VocabJournal.md"
    "dev"         = "$vaultPath//note_entertainment//Device.Journal.md"
    "web"         = "$vaultPath//note_software//WebJournal.md"
    "event"       = "$vaultPath//note_Knowledge//EventJournal.md"
    "ide"         = "$vaultPath//note_IDEAndTools//IDE.Journal.md"
    "arg"         = "$vaultPath//note_Knowledge//Opinion.Journal.md"
    "old"         = "$vaultPath//note_Knowledge//History.Event.Journal.md"
    "elec"        = "$vaultPath//note_Embedded//Electric.Journal.md"
    "nw"          = "$vaultPath//note_algo_lang//Network.Journal.md"
    "chip"        = "$vaultPath//note_Embedded//ChipsetJournal.md"
    "magnum"      = "$vaultPath//note_Knowledge//Personal.Idea.Journal.md"
    "wui"         = "$vaultPath//note_os_web//Web.UI.Journal.md"
    "wprog"       = "$vaultPath//note_os_web//WebProgJournal.md"
    "ui"          = "$vaultPath//note_os_web//UIJournal.md"
    "oth"         = "$vaultPath//note_Knowledge//Other.Knowledge.Journal.md"
    "come"        = "$vaultPath//note_Knowledge//WholesomeJournal.md"
    "pid"         = "$vaultPath//note_Knowledge//Personal.Idea.Journal.md"
    "edit"        = "$vaultPath//note_IDEAndTools//Multimedia.Journal.md"
    "frontend"    = "$vaultPath//note_os_web//UIJournal.md"
    "bld"         = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "be"          = "$vaultPath//note_os_web//Server.Network.Journal.md"
    "blend"       = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "snippet"     = "$vaultPath//note_Knowledge//Rad-Script.Journal.md"
    "wles"        = "$vaultPath//note_Embedded//RF-Wireless.Journal.md"
    "firm"        = "$vaultPath//note_Embedded//FirmwareJournal.md"
    "uiweb"       = "$vaultPath//note_os_web//Web.UI.Journal.md"
    "day"         = "$vaultPath//note_entertainment//Diary.Journal.md"
    "scr"         = "$vaultPath//note_Knowledge//Rad-Script.Journal.md"
    "cap"         = "$vaultPath//note_Embedded//Passive.IC.Journal.md"
    "image"       = "$vaultPath//note_IDEAndTools//Multimedia.Journal.md"
    "fpga"        = "$vaultPath//note_Embedded//FPGA-CPLD.IC.Journal.md"
    "backend"     = "$vaultPath//note_os_web//Server.Network.Journal.md"
    "sdr"         = "$vaultPath//note_Embedded//RF-Wireless.Journal.md"
    "topic"       = "$vaultPath//note_Knowledge//Discussion.Topic.Journal.md"
    "sec"         = "$vaultPath//note_algo_lang//Info.Security.Journal.md"
    "wfr"         = "$vaultPath//note_os_web//SDK-Framework.Web.Journal.md"
    "pic"         = "$vaultPath//note_Embedded//Passive.IC.Journal.md"
    "bio"         = "$vaultPath//note_Knowledge//Biology.Science.Journal.md"
    "fr"          = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
    "phy"         = "$vaultPath//note_algo_lang//STEMJournal.md"
    "windows"     = "$vaultPath//note_software//OSJournal.md"
    "cpp"         = "$vaultPath//note_algo_lang//LangJournal.md"
    "api"         = "$vaultPath//note_algo_lang//LibraryJournal.md"
    "self"        = "$vaultPath//note_entertainment//PersonalJournal.md"
    "other"       = "$vaultPath//note_Knowledge//Other.Knowledge.Journal.md"
    "humor"       = "$vaultPath//note_Knowledge//WholesomeJournal.md"
    "ux"          = "$vaultPath//note_os_web//UX.Design.Journal.md"
    "infosec"     = "$vaultPath//note_algo_lang//Info.Security.Journal.md"
    "idea"        = "$vaultPath//note_Business//IdeaJournal.md"
    "srv"         = "$vaultPath//note_os_web//Server.Network.Journal.md"
    "rad"         = "$vaultPath//note_Knowledge//Rad-Script.Journal.md"
    "prog"        = "$vaultPath//note_algo_lang//ProgrammingJournal.md"
    "soft"        = "$vaultPath//note_software//SoftwareJournal.md"
    "wire"        = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "meme"        = "$vaultPath//note_Knowledge//WholesomeJournal.md"
    "disc"        = "$vaultPath//note_Knowledge//Discussion.Topic.Journal.md"
    "wasm"        = "$vaultPath//note_os_web//WebProgJournal.md"
    "trivt"       = "$vaultPath//note_Knowledge//Trivia.Technologia.Journal.md"
    "agg"         = "$vaultPath//note_Knowledge//Meta.Journal.md"
    "eco"         = "$vaultPath//note_Knowledge//EconomyJournal.md"
    "cad3d"       = "$vaultPath//note_IDEAndTools//CADJournal.md"
    "thes"        = "$vaultPath//note_Knowledge//Personal.Idea.Journal.md"
    "mcad"        = "$vaultPath//note_IDEAndTools//CADJournal.md"
    "misc"        = "$vaultPath//note_Knowledge//Trivia.Knowledge.Journal.md"
    "eda"         = "$vaultPath//note_Embedded//EDAJournal.md"
    "wapi"        = "$vaultPath//note_os_web//WebAPIJournal.md"
    "bs"          = "$vaultPath//note_Business//WorkJournal.md"
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

function jvc {
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
