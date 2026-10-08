using namespace System.Collections.Generic
$CommandNewWt = @{
    "win" = '-f new-tab -p "PowerShell" pwsh -NoExit -Command "p7 && p7mod"; split-pane --size 0.5 -H -p "PowerShell" pwsh -NoExit -Command "p7 && p7mod"'
    "and" = '-f new-tab --suppressApplicationTitle -p "PowerShell"  pwsh -NoExit -Command "p7 && p7mod && anddev"; split-pane --size 0.5 -H -p "PowerShell_HLSL" pwsh -NoExit -Command "p7 && p7mod && anddev"'
    "ssh" = '-f new-tab -p "ssh" split-pane --size 0.5 -V -p "ssh_1" ; split-pane --size 0.5 -V -p "ssh_1" ; move-focus first ; split-pane --size 0.5 -V -p "ssh_1" ; move-focus first ; split-pane --size 0.5 -H -p "ssh_2" ; move-focus right ; split-pane --size 0.5 -H -p "ssh_2" ; move-focus right ; split-pane --size 0.5 -H -p "ssh_2" ; move-focus right ; split-pane --size 0.5 -H -p "ssh_2" pwsh -NoExit -Command "anddev && p7 && p7mod"'
    "lin" = '-f new-tab -p "PowerShell" wsl'
    "obs" = '-f new-tab -p "PowerShell" pwsh -NoExit -Command "p7 && p7mod && Set-Location $env:obsVault && jnl -3"'
}

function term($which = "win") {
    $fetch_command = $CommandNewWt[$which]
    if ($fetch_command -ne $null) {
        Start-Process wt $fetch_command
    }
    else {
        Write-Error "Wrong syntax"
        Write-Output $CommandNewWt
    }
}
Add-Type -AssemblyName System.Windows.Forms

function tapscr($emulator = $global:adbDevices, $index = 0) {
    try {
        $emulatorName = $emulator[$index]
        if (($emulatorName).Length -gt 2) {
            adb -s $emulatorName shell input tap 600 600
        }
        else {
            adb -s $emulator shell input tap 1000 500
        }

    }
    catch [System.Exception] {
        try {

            Write-Host "Import Anddev" -ForegroundColor Cyan
            andDev 
            ADB_getSerialList 
		
            $emulatorName = $emulator[$index]
            if (($emulatorName).Length -gt 2) {
                adb -s $emulatorName shell input tap 600 600
            }
            else {
                adb -s $emulator shell input tap 1000 500
            }	
        }
        catch [ System.Management.Automation.CommandNotFoundException] {
            # Recursive call until it tap.
            tapscr
        }
    }
}
# INFO: A function to switch font, on CLI.
$global:defaultWTProfile = 3
$global:preferFont = "Iosevka Nerd Font Propo"
function fontsw($fontName = $global:preferFont) {
    # HACK: Find tab's profile name then search in that chunk.
    $SettingsPath = (Resolve-Path "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_*\LocalState\settings.json")
    $CurrentFileContent = (Get-Content -Path $SettingsPath | ConvertFrom-Json)
    $TestFont = $CurrentFileContent.profiles.list[$defaultWTProfile].font.face
    echo $TestFont

    # INFO: add a fallback mechanism
    if ($TestFont -match $fontName) {
        $FinalFont = "Cascadia Code NF SemiLight"
    }
    else {
        $FinalFont = $fontName
    }
    $CurrentFileContent.profiles.list[$defaultWTProfile].font.face = "$FinalFont"
    $fileContent = "$(ConvertTo-Json $CurrentFileContent -Depth 10)"

    Set-Content -Value $fileContent -Path $SettingsPath

}

# INFO: Swap shaders, for reloading purpose perhaps.
$global:defaultShaderPath = "D:\ProgramDataD\VS\proj\general_shader\HLSL_Windows_Terminal"
function swapWtShader($fileName = "orig") {
    $SettingsPath = (Resolve-Path "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_*\LocalState\settings.json")
    $CurrentFileContent = (Get-Content -Path $SettingsPath | ConvertFrom-Json)
    $TestShaderPath = $CurrentFileContent.profiles.list[$defaultWTProfile].'experimental.pixelShaderPath'
    # INFO: switch back case.
    if ($fileName -eq "-") {
        if ( $TestShaderPath -match "orig") {
            $fileName = "swap"
        }
        else {
            $fileName = "orig"
        }
    }
    $CurrentFileContent.profiles.list[$defaultWTProfile].'experimental.pixelShaderPath' = "$defaultShaderPath\$fileName.hlsl"
    $fileContent = "$(ConvertTo-Json $CurrentFileContent -Depth 10)"
    # echo $fileContent
    Set-Content -Value $fileContent -Path $SettingsPath
}

# INFO: Copy shaders from the original Terminal app. Could be somewhere else in another JSON files.
function copyWtShader($fileName = "orig") {
    $SettingsPath = (Resolve-Path "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_*\LocalState\settings.json")
    $CurrentFileContent = Get-Content -Path $SettingsPath | ConvertFrom-Json
    $TestShaderPath = $CurrentFileContent.profiles.defaults.'experimental.pixelShaderPath'
    $FinalShaderPath = "$defaultShaderPath\$fileName.hlsl"

    Copy-Item $TestShaderPath $FinalShaderPath
}
