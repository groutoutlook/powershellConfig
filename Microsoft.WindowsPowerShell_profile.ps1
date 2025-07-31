Set-Alias pwsh "C:\Program Files\PowerShell\7-preview\pwsh.exe"
Set-Alias -Name r -Value just -Scope Global -Option AllScope
Set-Alias -Name :q -Value exit -Scope Global -Option AllScope
function rr {
    r r
}
function rb {
    r build 
}
function re {
    r -e
}
