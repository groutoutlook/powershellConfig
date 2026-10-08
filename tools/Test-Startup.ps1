$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path $PSScriptRoot -Parent
. (Join-Path $repositoryRoot 'Microsoft.PowerShell_profile.ps1')

function Assert([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

# Startup must expose names without importing their implementations.
foreach ($name in @('CLI-Basic', 'quickVimAction', 'quickPwshUtils', 'CLI-Extra', 'quickWebAction', 'quick.query')) {
    Assert (-not (Get-Module $name)) "$name was eagerly imported"
}
Assert ([bool](Get-Command :r -CommandType Function)) ':r is unavailable'
Assert ((Get-Alias Track).Definition -eq 'Add-NextTrack') 'Track alias is missing'
Assert ((Get-Alias p7mod).Definition -eq 'Import-MoreModule') 'p7mod alias is missing'
Assert ((Get-Alias p7mod).Options -notmatch 'AllScope') 'p7mod has incompatible alias flags'

# Validate the complete key table without requiring a live interactive buffer.
Import-Module "$PSHOME/Modules/PSReadLine/PSReadLine.psd1"
setAllHandler
foreach ($chord in @('Alt+v', 'Alt+s', 'Alt+a', 'Ctrl+9', 'Ctrl+Oem4', 'Ctrl+r', 'Ctrl+s', 'Ctrl+x,Ctrl+x')) {
    Assert ([bool](Get-PSReadLineKeyHandler -Chord $chord)) "$chord is missing"
}

# Force native autoload through the Track target, then verify its IPC dependency.
$trackCommand = Get-Command Add-NextTrack -CommandType Function
Assert ($trackCommand.Source -eq 'CLI-Basic') 'Track implementation failed to autoload'
$ipcCommand = Get-Command Send-MpvIpcCommand -CommandType Function
Assert ($ipcCommand.Source -eq 'quickPwshUtils') 'Track IPC dependency failed to autoload'

# Capture IPC calls inside the module so the test never contacts a running mpv.
function global:Send-MpvIpcCommand {
    param([string]$Command, [string[]]$Arguments, [switch]$ReturnResponse)
    $global:StartupTestIpc = @($Command) + $Arguments
}
Track 'https://example.invalid/song.mkv'
Assert (($global:StartupTestIpc -join '|') -eq 'loadfile|https://example.invalid/song.mkv|insert-next') 'Track lost its arguments'

# :r retains its original P7 + extended-module behavior; suppress external init.
function global:P7 { $global:StartupTestP7 = $true }
:r
Assert $global:StartupTestP7 ':r did not call P7'
foreach ($name in $global:extraModuleList) {
    Assert ([bool](Get-Module $name)) ":r did not load $name"
}
Assert ([bool](Get-Command Get-Playlistmpv -CommandType Function)) 'Extended commands are unavailable'

# Reloading must retain valid aliases and available keybindings.
. (Join-Path $repositoryRoot 'Microsoft.PowerShell_profile.ps1')
Assert ((Get-Alias p7mod).Options -notmatch 'AllScope') 'Profile reload broke p7mod'
Assert ([bool](Get-PSReadLineKeyHandler -Chord Alt+v)) 'Profile reload removed Alt+V'
Remove-Variable StartupTestIpc, StartupTestP7 -Scope Global
'Startup, bindings, Track, :r, extended modules, and reload: PASS'
