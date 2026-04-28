function global:Backup-Environment($Verbose = $null) {
    $ProfilePath = Split-Path $($PROFILE.CurrentUserCurrentHost) -Parent
    Copy-Item "$env:p7settingDir\Microsoft.PowerShell_profile.ps1" $ProfilePath -Force
    Copy-Item "$env:p7settingDir\Microsoft.WindowsPowerShell_profile.ps1" $ProfilePath -Force
    Write-Host "[$(Get-Date)] Move Profile. CurrentUserCurrentHost" -ForegroundColor Green
}

function P7() {
    Invoke-Expression (&starship init powershell)
    # function prompt {
    #     prmt --code $LASTEXITCODE '{path:cyan} {git:purple} {python:yellow:m: 🐍} {time:dim}\n{ok:green}{fail:red} '
    # }
    # tv init power-shell 
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
    Get-ChildItem Alias:/rd | Out-Null && Remove-Item Alias:rd -ErrorAction SilentlyContinue
    Set-Alias -Name cd -Value z -Scope Global -Option AllScope 
    Set-Alias -Name cdi -Value zi -Scope Global -Option AllScope 
}

$global:initialModuleList = @(
    "quickWebAction",
    "quickVimAction",
    "quickPSReadLine",
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
    foreach ($module in $global:initialModuleList) {
        Import-Module -Name (Join-Path $env:p7settingDir $module) -Scope Global 
    }
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
    $whichBackend = "scoop w" # INFO: default is `which` that windows provide. but this return a list.
    try {
        $tryWhichCommand = Invoke-Expression "$whichBackend $files" -ErrorAction SilentlyContinue
        # $initialInfo = Get-Command $files 
        $commandInfo = Get-Command $tryWhichCommand -ErrorAction SilentlyContinue
    }
    catch {
        # $initialInfo = $null
        $commandInfo = Get-Command $files -ErrorAction SilentlyContinue
    }

    # echo ($commandInfo).PSObject.TypeNames
    if ($commandInfo.PSObject.TypeNames -notcontains "System.Object[]") {
        switch -Exact ($commandInfo.CommandType) {

            "Application" {
                # INFO: We need something to detect executable here. Mostly exe files but there could also be other type as well.
                if (($commandInfo.Extension -match "exe|cmd")) {
                    $listBinaries = Invoke-Expression "(Resolve-Path ($whichBackend $files)).ToString()"
					
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
                
                $linkInfo = Format-Hyperlink $commandInfo.Source $resolvedPath

                Write-Host "function from $linkInfo module/script." -ForegroundColor Yellow -BackgroundColor DarkBlue
                Write-Host $commandInfo.Definition
                if ($resolvedPath) {
                    $targetPath = Split-Path $resolvedPath -Parent
                    if ($outHost) { Write-Output $targetPath } else { Set-Location $targetPath }
                } else {
                    Write-Error "Could not find a valid file path for this function."
                }
            }

            "Alias" {
                $definition = ($commandInfo).Definition
                $ModuleInfo = Get-Module $commandInfo.Source
                $ModulePath = $ModuleInfo.Path
                $linkInfo = Format-Hyperlink $commandInfo.Source $ModulePath

                Write-Host "alias of $definition , source: $linkInfo" -ForegroundColor Yellow -BackgroundColor Black
                $definitionInfo = Get-Command $definition
                Set-LocationWhere $definitionInfo.Name -outHost:$outHost
            }

            "ExternalScript" {
                $definition = ($commandInfo).Source
                $scriptName = $commandInfo.Name
                $linkInfo = Format-Hyperlink $scriptName $commandInfo.Source
                Write-Host "Script from $linkInfo." -ForegroundColor Yellow -BackgroundColor DarkBlue

                try {
                    $ScriptContent = Get-Content $definition -ErrorAction Stop
                    Write-Host $ScriptContent -BackgroundColor DarkGreen -ForegroundColor White
                    
                    # Try to extract path from variable assignments like $path = '...'
                    $pathLine = $ScriptContent | Where-Object { $_ -match '\$\w+\s*=\s*[''"](.+?)[''"]' }
                    if ($pathLine) {
                        $extractedPath = $Matches[1]
                        Write-Host "Extracted path: $extractedPath" -ForegroundColor Cyan
                        cdcb -defaultDir $extractedPath -outHost:$outHost
                    }
                    else {
                        # Fallback to original method
                        Write-Output $ScriptContent |`
                                Select-Object -Index 0 |`
                                Get-PathFromFiles | cdcb -outHost:$outHost
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

# INFO: Rescue explorer function.
function Restart-Explorer {
    Stop-Process -Name explorer 
}

initProfileEnv
initShellApp
