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
    "humor"       = "$vaultPath//note_Knowledge//WholesomeJournal.md"
    "chip"        = "$vaultPath//note_Embedded//ChipsetJournal.md"
    "frontend"    = "$vaultPath//note_os_web//UIJournal.md"
    "ecad"        = "$vaultPath//note_Embedded//EDAJournal.md"
    "rule"        = "$vaultPath//note_Business//WorkflowJournal.md"
    "hw"          = "$vaultPath//note_Embedded//HardwareJournal.md"
    "vocab"       = "$vaultPath//note_Knowledge//VocabJournal.md"
    "pcba"        = "$vaultPath//note_Embedded//PCBJournal.md"
    "meta"        = "$vaultPath//note_Knowledge//Meta.Journal.md"
    "num"         = "$vaultPath//note_algo_lang//Math.Journal.md"
    "backend"     = "$vaultPath//note_os_web//Server.Network.Journal.md"
    "fe"          = "$vaultPath//note_os_web//UIJournal.md"
    "old"         = "$vaultPath//note_Knowledge//History.Event.Journal.md"
    ":1"          = "$vaultPath//note_Items//1688Journal.md"
    "pic"         = "$vaultPath//note_Embedded//Passive.IC.Journal.md"
    "fiw"         = "$vaultPath//note_Embedded//FirmwareJournal.md"
    "med"         = "$vaultPath//note_Knowledge//Medical.Knowledge.Journal.md"
    "demob"       = "$vaultPath//note_Embedded//EVB.Hardware.Journal.md"
    "conn"        = "$vaultPath//note_Business//ConnectionJournal.md"
    "book"        = "$vaultPath//note_Knowledge//ReadAndListenJournal.md"
    "money"       = "$vaultPath//note_Business//MoneyJournal.md"
    "srv"         = "$vaultPath//note_os_web//Server.Network.Journal.md"
    ":3"          = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "chem"        = "$vaultPath//note_algo_lang//Chemistry.Journal.md"
    "wpro"        = "$vaultPath//note_os_web//WebProgJournal.md"
    "geom"        = "$vaultPath//note_algo_lang//Math.Journal.md"
    "buildsystem" = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
    "ana"         = "$vaultPath//note_Knowledge//Medical.Knowledge.Journal.md"
    ":1688"       = "$vaultPath//note_Items//1688Journal.md"
    "self"        = "$vaultPath//note_entertainment//PersonalJournal.md"
    "matrix"      = "$vaultPath//note_algo_lang//Algebra.Math.Journal.md"
    "peak"        = "$vaultPath//note_Knowledge//Personal.Idea.Journal.md"
    "css"         = "$vaultPath//note_os_web//Web.UI.Journal.md"
    "pcom"        = "$vaultPath//note_Embedded//Passive.IC.Journal.md"
    "hard"        = "$vaultPath//note_Embedded//HardwareJournal.md"
    "std"         = "$vaultPath//note_algo_lang//LangJournal.md"
    "csci"        = "$vaultPath//note_algo_lang//CompSciJournal.md"
    "wles"        = "$vaultPath//note_Embedded//RF-Wireless.Journal.md"
    "cul"         = "$vaultPath//note_Knowledge//Culture.Journal.md"
    "taobao"      = "$vaultPath//note_Items//TaobaoJournal.md"
    "proto"       = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "trivt"       = "$vaultPath//note_Knowledge//Trivia.Technologia.Journal.md"
    "soc"         = "$vaultPath//note_Embedded//ChipsetJournal.md"
    "ling"        = "$vaultPath//note_Knowledge//PhraseJournal.md"
    "pcb"         = "$vaultPath//note_Embedded//PCBJournal.md"
    "gui"         = "$vaultPath//note_software//GUI.Software.Journal.md"
    "uiweb"       = "$vaultPath//note_os_web//Web.UI.Journal.md"
    "file"        = "$vaultPath//note_IDEAndTools//File-Format.Journal.md"
    "ev"          = "$vaultPath//note_Knowledge//EventJournal.md"
    "event"       = "$vaultPath//note_Knowledge//EventJournal.md"
    "blog"        = "$vaultPath//note_Knowledge//ReadAndListenJournal.md"
    "eda"         = "$vaultPath//note_Embedded//EDAJournal.md"
    "technologia" = "$vaultPath//note_Knowledge//Trivia.Technologia.Journal.md"
    "freecad"     = "$vaultPath//note_IDEAndTools//CADJournal.md"
    "trit"        = "$vaultPath//note_Knowledge//Trivia.Technologia.Journal.md"
    "quote"       = "$vaultPath//note_Knowledge//QuoteJournal.md"
    "three"       = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "fm"          = "$vaultPath//note_IDEAndTools//File-Format.Journal.md"
    "emb"         = "$vaultPath//note_Embedded//FirmwareJournal.md"
    "bld"         = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "ide"         = "$vaultPath//note_IDEAndTools//IDE.Journal.md"
    "life"        = "$vaultPath//note_Knowledge//LifeJournal.md"
    "phy"         = "$vaultPath//note_algo_lang//STEMJournal.md"
    "krita"       = "$vaultPath//note_IDEAndTools//Multimedia.Journal.md"
    "tip"         = "$vaultPath//note_Knowledge//TIL.Knowledge.Journal.md"
    "oic"         = "$vaultPath//note_Embedded//Others.IC.Journal.md"
    "graph"       = "$vaultPath//note_algo_lang//GraphicUIJournal.md"
    "misc"        = "$vaultPath//note_Knowledge//Trivia.Knowledge.Journal.md"
    "stip"        = "$vaultPath//note_Knowledge//Personal.Idea.Journal.md"
    "cpld"        = "$vaultPath//note_Embedded//FPGA-CPLD.IC.Journal.md"
    "trvt"        = "$vaultPath//note_Knowledge//Trivia.Technologia.Journal.md"
    "vid"         = "$vaultPath//note_entertainment//VideoJournal.md"
    "math"        = "$vaultPath//note_algo_lang//Math.Journal.md"
    "mind"        = "$vaultPath//note_Knowledge//Personal.Psychology.Journal.md"
    "til"         = "$vaultPath//note_Knowledge//TIL.Knowledge.Journal.md"
    "gsw"         = "$vaultPath//note_software//GUI.Software.Journal.md"
    "oth"         = "$vaultPath//note_Knowledge//Other.Knowledge.Journal.md"
    "swc"         = "$vaultPath//note_software//CLI.Terminal.Software.Journal.md"
    "algo"        = "$vaultPath//note_algo_lang//Algorithm.Journal.md"
    "other"       = "$vaultPath//note_Knowledge//Other.Knowledge.Journal.md"
    "myrule"      = "$vaultPath//note_Business//WorkflowJournal.md"
    "be"          = "$vaultPath//note_os_web//Server.Network.Journal.md"
    "wasm"        = "$vaultPath//note_os_web//WebProgJournal.md"
    "webui"       = "$vaultPath//note_os_web//Web.UI.Journal.md"
    "fsdk"        = "$vaultPath//note_os_web//SDK-Framework.Firmware.Journal.md"
    "know"        = "$vaultPath//note_Knowledge//Other.Knowledge.Journal.md"
    "fcad"        = "$vaultPath//note_IDEAndTools//CADJournal.md"
    "item"        = "$vaultPath//note_Items//OtherItemsJournal.md"
    "model"       = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "lang"        = "$vaultPath//note_algo_lang//LangJournal.md"
    "tech"        = "$vaultPath//note_Knowledge//Trivia.Technologia.Journal.md"
    "sdk"         = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
    "acro"        = "$vaultPath//note_Knowledge//AcronymJournal.md"
    "elec"        = "$vaultPath//note_Embedded//Electric.Journal.md"
    "psy"         = "$vaultPath//note_Knowledge//Psychology.Journal.md"
    "bs"          = "$vaultPath//note_Business//WorkJournal.md"
    "wsdk"        = "$vaultPath//note_os_web//SDK-Framework.Web.Journal.md"
    "linux"       = "$vaultPath//note_software//OSJournal.md"
    "retro"       = "$vaultPath//note_Knowledge//Personal.Past.Event.Journal.md"
    "ietf"        = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "rad"         = "$vaultPath//note_Knowledge//Rad-Script.Journal.md"
    "cli"         = "$vaultPath//note_software//CLI.Terminal.Software.Journal.md"
    "hack"        = "$vaultPath//note_Knowledge//LifeHackJournal.md"
    "video"       = "$vaultPath//note_entertainment//VideoJournal.md"
    "music"       = "$vaultPath//note_entertainment//MusicJournal.md"
    "sec"         = "$vaultPath//note_algo_lang//Info.Security.Journal.md"
    "inst"        = "$vaultPath//note_os_web//SDK-Framework.Firmware.Journal.md"
    "img"         = "$vaultPath//note_IDEAndTools//Multimedia.Journal.md"
    "cash"        = "$vaultPath//note_Business//MoneyJournal.md"
    "quo"         = "$vaultPath//note_Knowledge//QuoteJournal.md"
    "read"        = "$vaultPath//note_Knowledge//ReadAndListenJournal.md"
    "embed"       = "$vaultPath//note_Embedded//FirmwareJournal.md"
    "vk"          = "$vaultPath//note_algo_lang//GraphicUIJournal.md"
    "stat"        = "$vaultPath//note_Knowledge//Statistic.Journal.md"
    "vul"         = "$vaultPath//note_algo_lang//GraphicUIJournal.md"
    "isec"        = "$vaultPath//note_algo_lang//Info.Security.Journal.md"
    "evk"         = "$vaultPath//note_Embedded//HDK.Hardware.Journal.md"
    "mcad"        = "$vaultPath//note_IDEAndTools//CADJournal.md"
    "work"        = "$vaultPath//note_Business//WorkJournal.md"
    "script"      = "$vaultPath//note_Knowledge//Rad-Script.Journal.md"
    "fw"          = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
    "web"         = "$vaultPath//note_software//WebJournal.md"
    "wfw"         = "$vaultPath//note_os_web//SDK-Framework.Web.Journal.md"
    "diss"        = "$vaultPath//note_Knowledge//Discussion.Topic.Journal.md"
    "pre"         = "$vaultPath//note_Knowledge//Prediction.Event.Journal.md"
    "wire"        = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "new"         = "$vaultPath//note_Knowledge//NewsJournal.md"
    "laugh"       = "$vaultPath//note_Knowledge//WholesomeJournal.md"
    "motto"       = "$vaultPath//note_Knowledge//Personal.Idea.Journal.md"
    "prot"        = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "swgui"       = "$vaultPath//note_software//GUI.Software.Journal.md"
    "rtl"         = "$vaultPath//note_Embedded//FPGA-CPLD.IC.Journal.md"
    "op"          = "$vaultPath//note_Knowledge//Opinion.Journal.md"
    "design"      = "$vaultPath//note_os_web//UX.Design.Journal.md"
    "wf"          = "$vaultPath//note_Business//WorkflowJournal.md"
    "thought"     = "$vaultPath//note_Knowledge//Personal.Psychology.Journal.md"
    "interest"    = "$vaultPath//note_entertainment//PersonalJournal.md"
    "devb"        = "$vaultPath//note_Embedded//EVB.Hardware.Journal.md"
    "default"     = "$vaultPath//MainJournal.md"
    "media"       = "$vaultPath//note_Knowledge//NewsJournal.md"
    "triv"        = "$vaultPath//note_Knowledge//Trivia.Knowledge.Journal.md"
    "wfr"         = "$vaultPath//note_os_web//SDK-Framework.Web.Journal.md"
    "soft"        = "$vaultPath//note_software//SoftwareJournal.md"
    "slang"       = "$vaultPath//note_Knowledge//PhraseJournal.md"
    "board"       = "$vaultPath//note_Embedded//EVB.Hardware.Journal.md"
    "rfid"        = "$vaultPath//note_Embedded//RF-Wireless.Journal.md"
    "pers"        = "$vaultPath//note_entertainment//PersonalJournal.md"
    "stem"        = "$vaultPath//note_algo_lang//STEMJournal.md"
    "bio"         = "$vaultPath//note_Knowledge//Biology.Science.Journal.md"
    "image"       = "$vaultPath//note_IDEAndTools//Multimedia.Journal.md"
    "net"         = "$vaultPath//note_algo_lang//Network.Journal.md"
    "snippet"     = "$vaultPath//note_Knowledge//Rad-Script.Journal.md"
    "dev"         = "$vaultPath//note_entertainment//Device.Journal.md"
    "pp"          = "$vaultPath//note_Business//ConnectionJournal.md"
    "mcu"         = "$vaultPath//note_Embedded//MCU.IC.Journal.md"
    "qt"          = "$vaultPath//note_Knowledge//QuoteJournal.md"
    "nw"          = "$vaultPath//note_algo_lang//Network.Journal.md"
    "tu"          = "$vaultPath//note_software//TUI.Terminal.Software.Journal.md"
    "os"          = "$vaultPath//note_software//OSJournal.md"
    "para"        = "$vaultPath//note_entertainment//Device.Journal.md"
    "ss"          = "$vaultPath//note_Knowledge//Rad-Script.Journal.md"
    "diary"       = "$vaultPath//note_entertainment//Diary.Journal.md"
    "scr"         = "$vaultPath//note_Knowledge//Rad-Script.Journal.md"
    "society"     = "$vaultPath//note_Knowledge//Culture.Journal.md"
    "cl"          = "$vaultPath//note_software//CLI.Terminal.Software.Journal.md"
    "tele"        = "$vaultPath//note_entertainment//Device.Journal.md"
    "opin"        = "$vaultPath//note_Knowledge//Opinion.Journal.md"
    "ico"         = "$vaultPath//note_Embedded//Others.IC.Journal.md"
    "asset"       = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "term"        = "$vaultPath//note_Knowledge//Terminology.Journal.md"
    "mate"        = "$vaultPath//note_algo_lang//Material.Journal.md"
    "ltip"        = "$vaultPath//note_Knowledge//LifeHackJournal.md"
    "phrase"      = "$vaultPath//note_Knowledge//PhraseJournal.md"
    "ms"          = "$vaultPath//note_entertainment//MusicJournal.md"
    "snip"        = "$vaultPath//note_Knowledge//Rad-Script.Journal.md"
    "etym"        = "$vaultPath//note_Knowledge//PhraseJournal.md"
    "inte"        = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "rf"          = "$vaultPath//note_Embedded//RF-Wireless.Journal.md"
    "magnum"      = "$vaultPath//note_Knowledge//Personal.Idea.Journal.md"
    "pid"         = "$vaultPath//note_Knowledge//Personal.Idea.Journal.md"
    "kicad"       = "$vaultPath//note_Embedded//EDAJournal.md"
    "netw"        = "$vaultPath//note_algo_lang//Network.Journal.md"
    "cpp"         = "$vaultPath//note_algo_lang//LangJournal.md"
    "day"         = "$vaultPath//note_entertainment//Diary.Journal.md"
    "disc"        = "$vaultPath//note_Knowledge//Discussion.Topic.Journal.md"
    "ali"         = "$vaultPath//note_Items//1688Journal.md"
    "soe"         = "$vaultPath//note_Knowledge//Culture.Journal.md"
    "blend"       = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "html"        = "$vaultPath//note_os_web//Web.UI.Journal.md"
    "cs"          = "$vaultPath//note_algo_lang//CompSciJournal.md"
    "sta"         = "$vaultPath//note_Knowledge//Statistic.Journal.md"
    "windows"     = "$vaultPath//note_software//OSJournal.md"
    "shape"       = "$vaultPath//note_algo_lang//Math.Journal.md"
    "daily"       = "$vaultPath//note_entertainment//Diary.Journal.md"
    "wlib"        = "$vaultPath//note_os_web//WebAPIJournal.md"
    "sdr"         = "$vaultPath//note_Embedded//RF-Wireless.Journal.md"
    "olds"        = "$vaultPath//note_Knowledge//History.Event.Journal.md"
    "sv"          = "$vaultPath//note_os_web//Server.Network.Journal.md"
    "workflow"    = "$vaultPath//note_Business//WorkflowJournal.md"
    "econ"        = "$vaultPath//note_Knowledge//EconomyJournal.md"
    "anim"        = "$vaultPath//note_Knowledge//Biology.Science.Journal.md"
    "bb"          = "$vaultPath//note_Embedded//HDK.Hardware.Journal.md"
    "cad3d"       = "$vaultPath//note_IDEAndTools//CADJournal.md"
    "meme"        = "$vaultPath//note_Knowledge//WholesomeJournal.md"
    "vd"          = "$vaultPath//note_IDEAndTools//Multimedia.Journal.md"
    "people"      = "$vaultPath//note_Business//ConnectionJournal.md"
    "hdk"         = "$vaultPath//note_Embedded//HDK.Hardware.Journal.md"
    "api"         = "$vaultPath//note_algo_lang//LibraryJournal.md"
    "topic"       = "$vaultPath//note_Knowledge//Discussion.Topic.Journal.md"
    "ux"          = "$vaultPath//note_os_web//UX.Design.Journal.md"
    "lhack"       = "$vaultPath//note_Knowledge//LifeHackJournal.md"
    "ui"          = "$vaultPath//note_os_web//UIJournal.md"
    "arg"         = "$vaultPath//note_Knowledge//Opinion.Journal.md"
    "agg"         = "$vaultPath//note_Knowledge//Meta.Journal.md"
    "thes"        = "$vaultPath//note_Knowledge//Personal.Idea.Journal.md"
    "comp"        = "$vaultPath//note_Embedded//ComponentJournal.md"
    "infosec"     = "$vaultPath//note_algo_lang//Info.Security.Journal.md"
    "ps"          = "$vaultPath//note_IDEAndTools//Multimedia.Journal.md"
    "fpga"        = "$vaultPath//note_Embedded//FPGA-CPLD.IC.Journal.md"
    "social"      = "$vaultPath//note_Business//ConnectionJournal.md"
    "lib"         = "$vaultPath//note_algo_lang//LibraryJournal.md"
    "swt"         = "$vaultPath//note_software//TUI.Terminal.Software.Journal.md"
    "phil"        = "$vaultPath//note_Knowledge//Psychology.Journal.md"
    "swg"         = "$vaultPath//note_software//GUI.Software.Journal.md"
    "evb"         = "$vaultPath//note_Embedded//EVB.Hardware.Journal.md"
    "server"      = "$vaultPath//note_os_web//Server.Network.Journal.md"
    "module"      = "$vaultPath//note_Embedded//ChipsetJournal.md"
    "edit"        = "$vaultPath//note_IDEAndTools//Multimedia.Journal.md"
    "ety"         = "$vaultPath//note_Knowledge//PhraseJournal.md"
    "frame"       = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
    "ocom"        = "$vaultPath//note_Embedded//Others.IC.Journal.md"
    "cad"         = "$vaultPath//note_IDEAndTools//CADJournal.md"
    "sw"          = "$vaultPath//note_software//SoftwareJournal.md"
    "tlm"         = "$vaultPath//note_entertainment//Device.Journal.md"
    "vc"          = "$vaultPath//note_Knowledge//VocabJournal.md"
    "ic"          = "$vaultPath//note_Embedded//ChipsetJournal.md"
    "prt"         = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "prog"        = "$vaultPath//note_algo_lang//ProgrammingJournal.md"
    "fi"          = "$vaultPath//note_Embedded//FirmwareJournal.md"
    "tui"         = "$vaultPath//note_software//TUI.Terminal.Software.Journal.md"
    "pger"        = "$vaultPath//note_Business//ConnectionJournal.md"
    "cult"        = "$vaultPath//note_Knowledge//Culture.Journal.md"
    "human"       = "$vaultPath//note_Knowledge//Psychology.Journal.md"
    "mental"      = "$vaultPath//note_Knowledge//Personal.Psychology.Journal.md"
    "pass"        = "$vaultPath//note_Embedded//Passive.IC.Journal.md"
    "place"       = "$vaultPath//note_Knowledge//PlacesJournal.md"
    "fr"          = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
    "come"        = "$vaultPath//note_Knowledge//WholesomeJournal.md"
    "art"         = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "al"          = "$vaultPath//note_algo_lang//Algorithm.Journal.md"
    "news"        = "$vaultPath//note_Knowledge//NewsJournal.md"
    "physic"      = "$vaultPath//note_algo_lang//STEMJournal.md"
    "draw"        = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "like"        = "$vaultPath//note_entertainment//PersonalJournal.md"
    "task"        = "$vaultPath//note_Business//WorkJournal.md"
    "res"         = "$vaultPath//note_Embedded//Passive.IC.Journal.md"
    "hist"        = "$vaultPath//note_Knowledge//History.Event.Journal.md"
    "per"         = "$vaultPath//note_entertainment//PersonalJournal.md"
    "wapi"        = "$vaultPath//note_os_web//WebAPIJournal.md"
    "pw"          = "$vaultPath//note_Knowledge//secret//AccountJournal.md"
    "cve"         = "$vaultPath//note_algo_lang//Info.Security.Journal.md"
    "stm"         = "$vaultPath//note_Embedded//FirmwareJournal.md"
    ":3d"         = "$vaultPath//note_IDEAndTools//ArtToolsJournal.md"
    "pol"         = "$vaultPath//note_Knowledge//NewsJournal.md"
    "ent"         = "$vaultPath//note_entertainment//Entertainment.Journal.md"
    "gpu"         = "$vaultPath//note_algo_lang//GraphicUIJournal.md"
    "style"       = "$vaultPath//note_Business//WorkflowJournal.md"
    "wui"         = "$vaultPath//note_os_web//Web.UI.Journal.md"
    "bus"         = "$vaultPath//note_Embedded//ProtocolJournal.md"
    "eco"         = "$vaultPath//note_Knowledge//EconomyJournal.md"
    "busy"        = "$vaultPath//note_Business//WorkJournal.md"
    "icother"     = "$vaultPath//note_Embedded//Others.IC.Journal.md"
    "list"        = "$vaultPath//note_Knowledge//Meta.Journal.md"
    "phr"         = "$vaultPath//note_Knowledge//PhraseJournal.md"
    "wprog"       = "$vaultPath//note_os_web//WebProgJournal.md"
    "firm"        = "$vaultPath//note_Embedded//FirmwareJournal.md"
    "idea"        = "$vaultPath//note_Business//IdeaJournal.md"
    "acc"         = "$vaultPath//note_Knowledge//secret//AccountJournal.md"
    "ee"          = "$vaultPath//note_Embedded//Electric.Journal.md"
    "mech"        = "$vaultPath//note_algo_lang//Mechanic.Journal.md"
    "peo"         = "$vaultPath//note_Business//ConnectionJournal.md"
    "is"          = "$vaultPath//note_algo_lang//Info.Security.Journal.md"
    "mat"         = "$vaultPath//note_algo_lang//Material.Journal.md"
    "gra"         = "$vaultPath//note_algo_lang//GraphicUIJournal.md"
    "probe"       = "$vaultPath//note_Embedded//HDK.Hardware.Journal.md"
    "alge"        = "$vaultPath//note_algo_lang//Algebra.Math.Journal.md"
    "build"       = "$vaultPath//note_os_web//SDK-Framework.General.Journal.md"
    "cap"         = "$vaultPath//note_Embedded//Passive.IC.Journal.md"
    "past"        = "$vaultPath//note_Knowledge//Personal.Past.Event.Journal.md"
    "pred"        = "$vaultPath//note_Knowledge//Prediction.Event.Journal.md"
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
