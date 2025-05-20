function global:Backup-Environment($Verbose = $null)
{
	$ProfilePath = Split-Path $($PROFILE.CurrentUserCurrentHost) -Parent
	Copy-Item "$env:p7settingDir\Microsoft.PowerShell_profile.ps1" $ProfilePath -Force
	Copy-Item "$env:p7settingDir\Microsoft.WindowsPowerShell_profile.ps1" $ProfilePath -Force
	Write-Host "[$(Get-Date)] Move Profile. CurrentUserCurrentHost" -ForegroundColor Green
}

function AppendPrompt
{
	function global:prompt
	{
		if ($null -ne $__zoxide_prompt_old)
		{
			& $__zoxide_prompt_old
		}
		$null = __zoxide_hook
	}
}

function P7()
{
	Invoke-Expression (&starship init powershell)
	# oh-my-posh init pwsh | Invoke-Expression
	Invoke-Expression (& { (zoxide init powershell | Out-String) })
	Set-Alias -Name cd -Value z -Scope Global -Option AllScope 
	Set-Alias -Name cdi -Value zi -Scope Global -Option AllScope 
	AppendPrompt
}

$global:initialModuleList=@(
	"quickWebAction",
	"quickVimAction",
	"quickPSReadLine",
	"quickPwshUtils.psm1",
	"CLI-Basic"
)

$global:extraModuleList = @(
	"CLI-Extra",
	"quickMathAction",
	"quickGitAction",
	"quickTerminalAction",
	"quickFilePathAction"
)
$global:personalModuleList = $global:initialModuleList + $global:extraModuleList
function MoreTerminalModule
{
	Import-Module -Name PSFzf -Scope Global 
	Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r' -TabExpansion -AltCCommand $null
	Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }
	# $env:CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense' # optional
	# Set-PSReadLineOption -Colors @{ "Selection" = "`e[7m" }
	# Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
	# carapace _carapace | Out-String | Invoke-Expression
	
	Invoke-Expression (&sfsu hook)
	# Import-Module -Name VirtualDesktop -Scope Global -Verbose
	foreach($module in $global:extraModuleList)
	{
		Import-Module -Name (Join-Path $env:p7settingDir $module) -Scope Global
	}
}
Set-Alias -Name p7mod -Value MoreTerminalModule
function initShellApp()
{
	foreach($module in $global:initialModuleList) {
		Import-Module -Name (Join-Path $env:p7settingDir $module) -Scope Global 
	}
}
function Restart-ModuleList()
{
	param (
		[array]$ModuleList = $global:personalModuleList,
		[string]$ModulePath = $env:p7settingDir
	)
	foreach($ModuleName in $ModuleList)
	{
		Remove-Module -Name (Join-Path $ModulePath $ModuleName) -ErrorAction SilentlyContinue
		Import-Module -Name (Join-Path $ModulePath $ModuleName) -Force 
		Write-Output "$ModuleName reimported"
	}
}
function global:Restart-Profile($option = "env")
{
	if ($option -match "^all")
	{
		Restart-ModuleList
		. $PROFILE
		Write-Output "Restart profile and All module."
	} else
	{
		. $PROFILE
		Write-Output "Restart pwsh Profile."
	}
}
Set-Alias -Name repro -Value Restart-Profile
function cdcb(
	[Parameter(ValueFromPipeline = $true)]
	$defaultDir = (Get-Clipboard)
)
{
	$copiedPath = ($defaultDir -replace '"')
	$property = Get-Item $copiedPath
	if ($property.PSIsContainer -eq $true)
	{
		Set-Location $copiedPath
	} else
	{
		Set-Location (Split-Path -Path $copiedPath -Parent)
	}
}

function Set-LocationWhere(
	[Parameter(
		# Mandatory = $true,
		ValueFromPipeline = $true
	)]
	$files = (Get-Clipboard)
)
{
	$whichBackend = "scoop which" # INFO: default is `which` that windows provide. but this return a list.
	# $whichBackend = "where.exe" 
	try{
		$tryWhichCommand = Invoke-Expression "$whichBackend $files" -ErrorAction SilentlyContinue
		$commandInfo = Get-Command $tryWhichCommand 
	}
	catch {
		$commandInfo = Get-Command $files
	}

	# echo ($commandInfo).PSObject.TypeNames
	# echo ($commandInfo).CommandType
	if ($commandInfo.PSObject.TypeNames -notcontains "System.Object[]")
	{
		switch -Exact ($commandInfo.CommandType)
		{

			"Application"
			{
				# INFO: We need something to detect executable here. Mostly exe files but there could also be other type as well.
				if (($commandInfo.Extension -match "exe|cmd"))
				{
					$listBinaries = Invoke-Expression "(Resolve-Path ($whichBackend $files)).ToString()"
					
					try
					{ $fileType = (${listBinaries}?.PsObject.TypeNames[0]) 
					} catch
					{
						Write-Host "From local dir not path." -ForegroundColor Blue
					}

					if ($fileType -match "String")
					{
						$finalBinariesPath = $listBinaries
					} else
					{
						$finalBinariesPath = $files
					}
					Set-Location (Split-Path $finalBinariesPath -Parent)
				} else
				{
					echo "cdcb now."
					# other extensions 
					cdcb $files
				}
				; break; 
			}

			"Function"
			{
				$definition = ($commandInfo).Source
				$ModuleInfo = Get-Module $commandInfo.Source
				$ModulePath = $ModuleInfo.Path
				$linkInfo = Format-Hyperlink $commandInfo.Source $ModulePath
				Write-Host "function from $linkInfo module." -ForegroundColor Yellow -BackgroundColor DarkBlue
				Set-Location (Split-Path $ModulePath -Parent)	
			}

			"Alias"
			{
				$definition = ($commandInfo).Definition
				$ModuleInfo = Get-Module $commandInfo.Source
				$ModulePath = $ModuleInfo.Path
				$linkInfo = Format-Hyperlink $commandInfo.Source $ModulePath

				Write-Host "alias of $definition , source: $linkInfo" -ForegroundColor Yellow -BackgroundColor Black
				$definitionInfo = Get-Command $definition
				Set-LocationWhere $definitionInfo.Name
			}

			"ExternalScript"
			{
				$definition = ($commandInfo).Source
				$scriptName = $commandInfo.Name
				$linkInfo = Format-Hyperlink $scriptName $commandInfo.Source
				Write-Host "Script from $linkInfo." -ForegroundColor Yellow -BackgroundColor DarkBlue

				$fileName = ($files)
				try
				{
					Get-Content "$env:LOCALAPPDATA/shims/$fileName.ps1" |`
							Select-Object -Index 0 |`
							Get-PathFromFiles | cdcb
				} catch
				{
				 	Write-Error "Had tried, still failed on shim."
					Set-Location (Split-Path $ModulePath -Parent)	
				}
			}

			default 
			{ 
				Write-Host "what... files?" -ForegroundColor Red -BackgroundColor Yellow
				$fileName = ($files)
				try
				{
					Get-Content "$env:LOCALAPPDATA/shims/$fileName.ps1" |`
							Select-Object -Index 0 |`
							Get-PathFromFiles | cdcb
				} catch
				{
				 Write-Error "Had tried, still failed on shim."
				}
			}  # optional
		} 
	}
	else
	{
		$finalBinariesPath = $commandInfo | %{ $_.Source }|fzf
		Set-Location (Split-Path ($finalBinariesPath) -Parent)
	}
}

Set-Alias -Name cdw -Value Set-LocationWhere
Set-Alias -Name cdwhere -Value Set-LocationWhere

function addPath
{ 
	param (# Parameter help description
  [Parameter(
	# Mandatory = $true,
	ValueFromPipeline = $true
)]
  [Alias("d")]
  $dirList = $pwd,

  
  [Parameter(Mandatory=$false)]
  [Alias("p")]
  $parent = $null
	)


	foreach($dir in $dirList)
	{
		if($null -ne $parent) {
			$dir = Split-Path $dir -Parent
		} else {
			$dir
		}
		$d = Resolve-Path $dir
		$Env:Path += ";"+$d;
	}
}

function global:initProfileEnv
{ 
	[Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new()
	$PSDefaultParameterValues['Out-File:Encoding']='utf8'

	$Env:ProgramFilesD = "D:\Program Files"
	$Env:ProgramDataD = "D:\ProgramDataD"
	$Env:dotfilesRepo = "$Env:ProgramDataD\dotfiles"

	$Env:p7settingDir = "D:\ProgramDataD\MiscLang\24.01-PowerShell\proj\powershellConfig"
	$Env:pipxLocalDir = "~\.local\bin"
	$Env:usrbinD="D:\usr\bin"
	
	$diradd = @(
		$Env:usrbinD
		,$Env:PhotoshopDir
		,$Env:pipxLocalDir
	)
	foreach($d in $diradd)
	{
		$Env:Path += ";"+$d;
	}
}

# INFO: cd- and cd--, same logic with cd+ and cd++
function cd-($rep = 1)
{
	foreach($i in (1..$rep))
 {
		Set-Location -
	}
}
function cd+($rep = 1)
{
	foreach($i in (1..$rep))
 {
		Set-Location +
	}
}
function ..($rep = 1)
{
	$furtherParent = $pwd
	foreach($i in (1..$rep))
 {
		$furtherParent = Split-Path -Path $furtherParent -Parent
	}
	Set-Location $furtherParent
}
Set-Alias -Name cd.. -Value .. -Scope Global -Option AllScope 

# INFO: Rescue explorer function.
function Restart-Explorer
{
	Stop-Process -Name explorer 
}

initProfileEnv
initShellApp
