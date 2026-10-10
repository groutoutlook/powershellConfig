$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $repositoryRoot 'modules/quickWebAction/quickWebAction.psd1') -Force

function Assert-ParsedId([string]$Url, [string]$Expected) {
    $actual = Get-ParsedId -url $Url
    if ($actual -ne $Expected) {
        throw "Expected '$Expected' for '$Url', got '$actual'."
    }
}

Assert-ParsedId 'https://electronics.stackexchange.com/questions/12345/example-title' '12345'
Assert-ParsedId 'https://math.stackexchange.com/q/98765' '98765'
Assert-ParsedId 'https://superuser.stackexchange.com/a/24680' '24680'
Assert-ParsedId 'https://example.invalid/path' 'example.invalid'
'Web action ID parsing: PASS'
