shebang := if os() == 'windows' { 'pwsh.exe' } else { '/usr/bin/env pwsh' }
set shell := ["pwsh", "-c"]
set windows-shell := ["pwsh.exe", "-NoLogo", "-Command"]
set dotenv-load := true
# INFO: really dont want to meddle with the .env, direnv is also related to this.
# WARN: should have get them in .gitignore.
set dotenv-filename	:= ".env"
set unstable
set fallback
# set dotenv-required := true
export JUST_ENV := "just_env" # WARN: this is also a method to export env var. 
_default:
    @just --choose

alias fmt := format
format args="nothing":
    Import-Module ./Formatter.psm1 -Force && gci *.psm1,*.ps1 | % { Format-PowerShellFile $_ }

alias d := deploy
deploy *args="cif":
    git {{args}}