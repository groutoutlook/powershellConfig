# INFO: it's better to keep stdout/console output.
function clearScrn {
    [Microsoft.PowerShell.PSConsoleReadLine]::ClearScreen()
}
Set-Alias -Name cls -Value clearScrn -Scope Global -Option AllScope
Set-Alias -Name clear -Value clearScrn -Scope Global -Option AllScope

# INFO: All basic function about other external apps better reside here.
function Restart-ForceApp($fileDir) {
    $fileName = (Split-Path $fileDir -Leaf) -replace "\.exe$"
    $currentSearchingProcess = (Get-Process -Name $fileName -ErrorAction Ignore)
    if ($currentSearchingProcess.Id -eq $null) {
        Write-Host "Haven't started the $fileName yet." -ForegroundColor Red
        Start-Process $fileDir
    }
    else {
        Stop-Process -Id $currentSearchingProcess.Id && `
            Start-Sleep -Milliseconds 500 && `
            Start-Process $fileDir
    }
}

# INFO: Show Window based on title.
function Show-Window {
    param(
        [Parameter(Mandatory)]
        [string] $ProcessName
    )
    $ProcessName = $ProcessName -replace '\.exe$'

    $b = (Get-Process -ErrorAction Ignore "*$ProcessName*").Where({ $_.MainWindowTitle })
    $c = $b | % ProcessName | fzf --select-1 --exit-0 --bind one:accept | % { $b | ? Name -EQ $_ }
    $procId = $c.ID
    if (-not $procId) {
        throw "No $ProcessName process with a non-empty window title found." 
        return 1
    }
    return (New-Object -ComObject WScript.Shell).AppActivate($procId)
}

# Load the necessary assembly
Add-Type -AssemblyName System.Windows.Forms

Add-Type @"
using System;
using System.Runtime.InteropServices;

public class User32 {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
}
"@

# INFO: Function to send keys to a specific window
function Send-Key {
    param (
        [string]$windowTitle,
        [string]$keys
    )

    # Find the window handle
    $hWnd = (Get-Process -ErrorAction Ignore "*$windowTitle*" ).Where({ $_.MainWindowTitle }, 'First').MainWindowHandle
    # $hWnd = [User32]::FindWindow([NullString]::Value, $windowTitle)
    if ($hWnd -eq [IntPtr]::Zero) {
        Write-Host "Window not found!"
        return
    }
    # Set the window to the foreground, it's somehow the must.
    [User32]::SetForegroundWindow($hWnd)
    [System.Windows.Forms.SendKeys]::SendWait($keys)
}

# INFO: quick create hashmap.
function buildIndex
( [Object[]]$inputArray, [string]$keyName) {

    $index = @{};
    foreach ($row in $inputArray) {
        $key = $row.($keyName);
        if ($null -eq $key -or $key.Equals([DBNull]::Value) -or $key.Length -eq 0) {
            $key = "<empty>"
        }
        $data = $index[$key];
        if ($data -is [System.Collections.Generic.List[PSObject]]) {
            $data.Add($row)
        }
        elseif ($data) {
            $index[$key] = New-Object -TypeName System.Collections.Generic.List[PSObject]
            $index[$key].Add($data, $row)
        }
        else {
            $index[$key] = $row
        }
    }
    $index
}

# INFO: URI maniulation
function filterURI(
    [Parameter(
        # Mandatory = $true,
        ValueFromPipeline = $true
    )]
    [System.String[]]
    [Alias("s")]
    $strings = (Get-Clipboard),
    [ValidateSet('usual', 'rarely', 'all')]
    $stripUnplay = 'usual'
) {
    $link = $strings
    # Markdown link like [title](url)
    $match = [regex]::Match($link, '\[(?<text>[^\]]+)\]\((?<url>[^)]+)\)')
    if (-not $match.Success) {
        return $null
    }
    $markdownName = $match.Groups['text'].Value
    $processedLink = $match.Groups['url'].Value.Trim()
    if ($processedLink -notmatch '^https?://') {
        Write-Host 'Somehow Invalid' -ForegroundColor Red
        return $null
    }
    $stripPattern = '&dontwanttoplaytoomuchman'
    switch ($stripUnplay) {
        'usual' {
            if ($processedLink -match $stripPattern) {
                return $null
            }
            else {
                return $markdownName + "`n" + $processedLink
            }
        }
        'rarely' {
            if ($processedLink -match $stripPattern) {
                return $markdownName + "`n" + $processedLink -replace $stripPattern, ""
            }
            else {
                return $null
            }
        }
        'all' {
            if ($processedLink -match $stripPattern) {
                return $markdownName + "`n" + $processedLink -replace $stripPattern, ""
            }
            else {
                return $markdownName + "`n" + $processedLink
            }
        }
    }
}
function Restart-Job {
    param (
        [int]$JobId
    )
    $job = Get-Job -Id $JobId
    if ($job) {
        # Assuming the job was created with a script block
        $scriptBlock = [scriptblock]::Create($job.Command)
        # Start a new job with the same script block
        Start-Job -ScriptBlock $scriptBlock
        Write-Host "Job $JobId restarted."
    }
    else {
        Write-Host "Job with ID $JobId not found. Get-Job to check now"
        Get-Job
    }
}

# INFO: for OSC 8
function Format-Hyperlink($text, $url) {
    $esc = [char]27
    return "$esc]8;;$url$esc\$text$esc]8;;$esc\"
}
function isLink($currentPath = (Get-Location)) {
    $pathProperty = Get-Item $currentPath
    if ($pathProperty.LinkType -eq "SymbolicLink") {
        Write-Host "`$PWD is SymLink"
        Write-Host $pathProperty.Target
    }
    return  $pathProperty.Target
}

function Set-LocationSymLink($currentPath = (Get-Location)) {
    $currentPath = Resolve-Path $currentPath
    if (($targetDir = isLink($currentPath)) -ne $null) {
        $pathProperty = Get-ItemProperty $targetDir
        if ( $pathProperty.Attributes -contains "Directory") {
            Set-Location $targetDir
        }
        else {
            Set-Location (Split-Path $targetDir -Parent)
        }
    }
}

function Remove-FullForce($path ) {
    # [Alias("rmrf")]
    $isPath = Test-Path $path
    if ($isPath) {
        Write-Host "$path gone." -ForegroundColor Magenta
        Remove-Item $path -Recurse -Force
    }
    else {
        Write-Error "$path not a local path" 
    }
}


function Copy-FullForce($path = "$((gcb) -replace '"','')", $destination = "$pwd") {
    # [Alias("cprf")]
    $stripPath = Resolve-Path $path
    $isPathHere = (gci (Split-Path $stripPath -Leaf) -ErrorAction SilentlyContinue) ?? $false
    if ($isPathHere) {
        Write-Host "$path is full force." -ForegroundColor Magenta
        Copy-Item $stripPath $destination -Recurse -Force
    }
    else {
        Write-Host "$path is not here..." -ForegroundColor Yellow
        Copy-Item $stripPath $destination -Recurse -Force
    }
}
function quickSymLink($path = (Get-Clipboard)) {
    if (Test-Path $path) {
        New-Item (Split-Path $path -Leaf) -ItemType SymbolicLink -Value $path -Force 
    }
    else {
        Write-Error "$path not a valid path."
    }
}

function swap_prompt {
    function global:prompt {
        echo "nothing, just PS:"
    }
}

function Resolve-ClipboardPath ($path = (gcb)) {
    rvpa ($path -replace '"') | scb
    return (gcb)
}

function Invoke-ShimClipboardPath {
    shim (rvcb) | tee \\.\CON 
    return (gcb)
}

Set-Alias -Name shcb -Value Invoke-ShimClipboardPath
Set-Alias -Name rvcb -Value Resolve-ClipboardPath
Set-Alias -Name cdsl -Value Set-LocationSymLink	
Set-Alias -Name rsjb -Value Restart-Job
Set-Alias -Name spa -Value Split-Path -Scope Global -Option AllScope
Set-Alias -Name jpa -Value Join-Path -Scope Global -Option AllScope
# HACK: alias `Measure-Command`, it's hyperfine but in dotnet environment.
Set-Alias -Name mcm -Value Measure-Command
Set-Alias -Name rmrf -Value Remove-FullForce 
Set-Alias -Name cprf -Value Copy-FullForce
Set-Alias -Name cpcb -Value Copy-FullForce
# Export-ModuleMember -Function * -Alias *
