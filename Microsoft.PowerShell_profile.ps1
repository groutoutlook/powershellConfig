# Avoid scanning every module directory for the first Set-Alias/Join-Path call.
# Use the modules shipped with this PowerShell installation.
Import-Module "$PSHOME/Modules/Microsoft.PowerShell.Utility/Microsoft.PowerShell.Utility.psd1"
Import-Module "$PSHOME/Modules/Microsoft.PowerShell.Management/Microsoft.PowerShell.Management.psd1"

function global:Backup-Environment($Verbose = $null) {
    $ProfilePath = Split-Path $($PROFILE.CurrentUserCurrentHost) -Parent
    Copy-Item "$env:p7settingDir\Microsoft.PowerShell_profile.ps1" $ProfilePath -Force
    Copy-Item "$env:p7settingDir\Microsoft.WindowsPowerShell_profile.ps1" $ProfilePath -Force
    Write-Host "[$(Get-Date)] Move Profile. CurrentUserCurrentHost" -ForegroundColor Green
}

function P7() {
    if ($global:P7Initialized) { return }
    Invoke-Expression (&starship init powershell)
    # function prompt {
    #     prmt --code $LASTEXITCODE '{path:cyan} {git:purple} {python:yellow:m: 🐍} {time:dim}\n{ok:green}{fail:red} '
    # }
    # tv init power-shell 
    $env:_ZO_MAXAGE = 1000000 # default is 10,000
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
    Get-ChildItem Alias:/rd | Out-Null && Remove-Item Alias:rd -ErrorAction SilentlyContinue
    Set-Alias -Name cd -Value z -Scope Global -Option AllScope 
    Set-Alias -Name cdi -Value zi -Scope Global -Option AllScope 
    $global:P7Initialized = $true
}

$global:initialModuleList = @(
    "quickWebAction",
    "quickVimAction",
    "quickPSReadLine",
    "quick.query.psm1",
    "quickPwshUtils.psm1",
    "CLI-Basic"
)

$global:extraModuleList = @(
    "Converter"
    "GUI-Basic"
    "CLI-Extra"
    "quickMathAction"
    "quickGitAction"
    "quickTerminalAction"
    "quickFilePathAction"
)
$global:personalModuleList = $global:initialModuleList + $global:extraModuleList
function initShellApp() {
    $moduleRoot = Join-Path $env:p7settingDir 'modules'
    if ($moduleRoot -notin ($env:PSModulePath -split [IO.Path]::PathSeparator)) {
        $env:PSModulePath = $moduleRoot + [IO.Path]::PathSeparator + $env:PSModulePath
    }
    . (Join-Path $env:p7settingDir 'LazyAliases.ps1')

    # Keep every editing shortcut ready, including Alt+V. Optional utilities
    # remain lazy; built-in PSReadLine resolves without a module-path scan.
    if (-not [Console]::IsInputRedirected -and -not [Console]::IsOutputRedirected) {
        Import-Module "$PSHOME/Modules/PSReadLine/PSReadLine.psd1"
    }
    Import-Module (Join-Path $env:p7settingDir 'quickPSReadLine.psm1') -Scope Global
}

function Restart-ModuleList() {
    param (
        [array]$ModuleList,
        [string]$ModulePath = $pwd,
        [Switch]$preferPsd1
    )
    foreach ($ModuleName in $ModuleList) {
        $moduleFullPath = Join-Path $ModulePath $ModuleName
        $psd1Module = (Test-Path -Path "$moduleFullPath.psd1") ? "$moduleFullPath.psd1" : $moduleFullPath 
        $psm1Module = (Test-Path -Path "$moduleFullPath.psm1") ? "$moduleFullPath.psm1" : $moduleFullPath
        $finalPath = $preferPsd1 ? $psd1Module : $psm1Module
        Remove-Module -Name $moduleFullPath -ErrorAction SilentlyContinue
        Import-Module -Name $moduleFullPath -Force -ErrorAction Stop
        Write-Output "$ModuleName reimported"
    }
}
function global:Restart-Profile($option = "env") {
    if ($option -match "^all") {
        Restart-ModuleList -ModuleList $global:personalModuleList -ModulePath $env:p7settingDir
        . $PROFILE
        Write-Output "Restart profile and All module."
    }
    else {
        . $PROFILE
        Write-Output "Restart pwsh Profile."
    }
}
Set-Alias -Name repro -Value Restart-Profile
function cdcb(
    [Parameter(ValueFromPipeline = $true)]
    $defaultDir = (Get-Clipboard),
    [switch]$outHost
) {
    $copiedPath = ($defaultDir -replace '"')
    $property = Get-Item $copiedPath
    if ($property.PSIsContainer -eq $true) {
        if ($outHost) { Write-Output $copiedPath } else { Set-Location $copiedPath }
    }
    else {
        if ($outHost) { Write-Output $copiedPath } else { Set-Location (Split-Path -Path $copiedPath -Parent) }
    }
}

function Set-LocationWhere(
    [Parameter(
        # Mandatory = $true,
        ValueFromPipeline = $true
    )]
    $files = (Get-Clipboard),
    [switch]$outHost
) {
    # Resolve the requested command first. Scoop's `scoop w` output can be a
    # warning or a shim path, so it must not be used as the primary resolver.
    $commandInfo = @(Get-Command -Name $files -ErrorAction SilentlyContinue | Select-Object -First 1)[0]
    if (-not $commandInfo) {
        $tryWhichCommand = Invoke-Expression "scoop w $files 2>`$null" -ErrorAction SilentlyContinue
        $commandInfo = @(Get-Command -Name $tryWhichCommand -ErrorAction SilentlyContinue | Select-Object -First 1)[0]
    }
    if (-not $commandInfo) {
        Write-Error "Could not resolve command or script '$files'."
        return
    }

    # echo ($commandInfo).PSObject.TypeNames
    if ($commandInfo.PSObject.TypeNames -notcontains "System.Object[]") {
        switch -Exact ($commandInfo.CommandType) {

            "Application" {
                # INFO: We need something to detect executable here. Mostly exe files but there could also be other type as well.
                if (($commandInfo.Extension -match "exe|cmd")) {
                    $scoopOut = Invoke-Expression "$whichBackend $files 2>`$null" -ErrorAction SilentlyContinue
                    if ($scoopOut -and (Test-Path $scoopOut -ErrorAction Ignore)) {
                        $listBinaries = (Resolve-Path $scoopOut).ToString()
                    }
                    else {
                        # scoop failed or broken shim — use what Get-Command already resolved
                        $listBinaries = $commandInfo.Source
                    }
					
                    try {
                        $fileType = (${listBinaries}?.PsObject.TypeNames[0]) 
                    }
                    catch {
                        Write-Host "From local dir not path." -ForegroundColor Blue
                    }

                    if ($fileType -match "String") {
                        $finalBinariesPath = $listBinaries
                    }
                    else {
                        $finalBinariesPath = $files
                    }
                    $targetPath = Split-Path $finalBinariesPath -Parent
                    if ($outHost) { Write-Output $targetPath } else { Set-Location $targetPath }
                }
                else {
                    echo "cdcb now."
                    # other extensions 
                    cdcb -defaultDir $files -outHost:$outHost
                }
                ; break; 
            }

            "Function" {
                $definition = ($commandInfo).Source
                $ModuleInfo = Get-Module $commandInfo.Source
                $ModulePath = $ModuleInfo.Path
                $ScriptFile = $commandInfo.ScriptBlock.File
                $resolvedPath = if ($ScriptFile) { $ScriptFile } else { $ModulePath }
                
                $linkInfo = if (Get-Command Format-Hyperlink -ErrorAction SilentlyContinue) { Format-Hyperlink $commandInfo.Source $resolvedPath } else { $resolvedPath }

                Write-Host "function from $linkInfo module/script." -ForegroundColor Yellow -BackgroundColor DarkBlue
                Write-Host $commandInfo.Definition
                if ($resolvedPath) {
                    $targetPath = Split-Path $resolvedPath -Parent
                    if ($outHost) { Write-Output $targetPath } else { Set-Location $targetPath }
                }
                else {
                    Write-Error "Could not find a valid file path for this function."
                }
            }

            "Alias" {
                $definition = ($commandInfo).Definition
                $ModuleInfo = Get-Module $commandInfo.Source
                $ModulePath = $ModuleInfo.Path
                $linkInfo = if (Get-Command Format-Hyperlink -ErrorAction SilentlyContinue) { Format-Hyperlink $commandInfo.Source $ModulePath } else { $ModulePath }

                Write-Host "alias of $definition , source: $linkInfo" -ForegroundColor Yellow -BackgroundColor Black
                $definitionInfo = Get-Command $definition
                Set-LocationWhere $definitionInfo.Name -outHost:$outHost
            }

            "ExternalScript" {
                $definition = ($commandInfo).Source
                $scriptName = $commandInfo.Name
                Write-Host "Script from $($commandInfo.Source)." -ForegroundColor Yellow -BackgroundColor DarkBlue

                if (-not (Test-Path $definition -ErrorAction Ignore)) {
                    Write-Error "Had tried, still failed on shim."
                    return
                }

                try {
                    $scriptContent = Get-Content -LiteralPath $definition -Raw -ErrorAction Stop
                    Write-Verbose $scriptContent

                    # Scoop shims contain an assignment such as $path = 'C:\\tool\\tool.exe'.
                    $pathMatch = [regex]::Match($scriptContent, '(?m)\$\w+\s*=\s*[''\"](?<path>[^''\"]+)[''\"]')
                    if ($pathMatch.Success) {
                        $extractedPath = $pathMatch.Groups['path'].Value
                        $targetPath = Split-Path -Path $extractedPath -Parent
                        if (Test-Path -LiteralPath $targetPath -PathType Container) {
                            if ($outHost) { Write-Output $targetPath } else { Set-Location -LiteralPath $targetPath }
                        }
                        else {
                            Write-Error "Command target directory not found: $targetPath (from shim '$definition')."
                            return
                        }
                    }
                    else {
                        $targetPath = Split-Path -Path $definition -Parent
                        if ($outHost) { Write-Output $targetPath } else { Set-Location -LiteralPath $targetPath }
                    }
                }
                catch {
                    Write-Error "Had tried, still failed on shim."
                    $targetPath = Split-Path $definition -Parent
                    if ($outHost) { Write-Output $targetPath } else { Set-Location $targetPath }	
                }
            }

            default { 
                Write-Host "what... files?" -ForegroundColor Red -BackgroundColor Yellow
                $fileName = ($files -replace '\.ps1$', '')
                try {
                    Get-Content "$env:LOCALAPPDATA/shims/$fileName.ps1" -ErrorAction Stop |`
                            Select-Object -Index 0 |`
                            Get-PathFromFiles | cdcb -outHost:$outHost
                }
                catch {
                    Write-Error "Had tried, still failed."
                }
            }  # optional
        } 
    }
    else {
        $finalBinariesPath = $commandInfo | % { $_.Source } | fzf
        $targetPath = Split-Path ($finalBinariesPath) -Parent
        if ($outHost) { Write-Output $targetPath } else { Set-Location $targetPath }
    }
}

Set-Alias -Name cdw -Value Set-LocationWhere
Set-Alias -Name cdwhere -Value Set-LocationWhere

function addPath { 
    param (# Parameter help description
        [Parameter(
            # Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [Alias("d")]
        $dirList = $pwd,

        [Parameter(Mandatory = $false)]
        [Alias("p")]
        $parent = $null
    )


    foreach ($dir in $dirList) {
        if ($null -ne $parent) {
            $dir = Split-Path $dir -Parent
        }
        else {
            $dir
        }
        $d = Resolve-Path $dir
        $Env:Path += ";" + $d;
    }
}

function global:initProfileEnv { 
    [Console]::InputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
    $PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

    # $Env:ProgramFilesD = "D:\Program Files"
    $Env:ProgramDataD = "D:\ProgramDataD"
    $Env:dotfilesRepo = "$Env:ProgramDataD\dotfiles"

    $Env:p7settingDir = "D:\ProgramDataD\MiscLang\24.01-PowerShell\proj\powershellConfig"
    $Env:pipxLocalDir = "~\.local\bin"
    $Env:usrbinD = "D:\usr\bin"
    # $env:XDG_CONFIG_HOME = $env:HOME # that's sometimes needed.

    $diradd = @(
        $Env:usrbinD
        , $Env:pipxLocalDir
    )
    foreach ($d in $diradd) {
        $Env:Path += ";" + $d;
    }
}

# INFO: cd- and cd--, same logic with cd+ and cd++
function cd-($rep = 1) {
    if ($rep -le 0) { return } # Since I use that in scripts... it can underflow somehow.
    foreach ($i in (1..$rep)) {
        Set-Location -
    }
}
function cd+($rep = 1) {
    if ($rep -le 0) { return } 
    foreach ($i in (1..$rep)) {
        Set-Location +
    }
}
function ..($rep = 1) {
    $furtherParent = $pwd
    foreach ($i in (1..$rep)) {
        $furtherParent = Split-Path -Path $furtherParent -Parent
    }
    Set-Location $furtherParent
}
Set-Alias -Name cd.. -Value .. -Scope Global -Option AllScope 
function cd..2 { .. 2 }
function cd-2 { cd- 2 }
function cd+2 { cd+ 2 }

# INFO: Rescue explorer function.
function Restart-Explorer {
    Stop-Process -Name explorer 
}

initProfileEnv
initShellApp
