$ErrorActionPreference = 'Stop'
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'CLI-Basic.psm1') -Force

function global:jrnl {
    $global:LASTEXITCODE = 0
    '{"journals":{"tui":{"journal":"C:/journals/tui.md"},"tuix":{"journal":"C:/journals/tuix.md"},"home":{"journal":"~/notes/home.md"}}}'
}
function global:zoxide { 'C:/vault' }
function global:ig { $global:JournalTestArgs = @($args) }
function global:rg { $global:JournalTestArgs = @($args) }
function Assert([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

igj ascii '[tui]'
Assert ((@($global:JournalTestArgs) -join '|') -eq '--context-viewer=horizontal|-S|--|ascii|C:/journals/tui.md') 'Bracket selector or exact alias matching failed'
igj ascii --journal tui
Assert ($global:JournalTestArgs[-1] -eq 'C:/journals/tui.md') 'Long journal selector failed'
igj ascii -j tui
Assert ($global:JournalTestArgs[-1] -eq 'C:/journals/tui.md') 'Short journal selector failed'
igj ascii '@home'
Assert ($global:JournalTestArgs[-1] -eq (Join-Path $HOME 'notes/home.md')) 'Home expansion failed'
igj ascii art '[tui]' -i
Assert ($global:JournalTestArgs[-2] -eq 'ascii.{0,30}?art') 'Selector leaked into the pattern'
Assert ($global:JournalTestArgs -contains '-i') 'Search option was lost'
Assert ($global:JournalTestArgs -cnotcontains '-S') 'Explicit case option was overridden'
igj step model
Assert ($global:JournalTestArgs -ccontains '-S') 'Lowercase search did not request smart-case'
Assert ($global:JournalTestArgs[-2] -eq 'step.{0,30}?model') 'Multiword search pattern changed'
igj ascii
Assert (($global:JournalTestArgs -join '|') -eq '--context-viewer=horizontal|-S|-g|*Journal.md|--|ascii|C:/vault') 'Default vault search changed'
rgj ascii '[tui]'
Assert (($global:JournalTestArgs -join '|') -eq '-M|400|-A3|--|ascii|C:/journals/tui.md') 'rgj selected-journal search changed'
rgj ascii
Assert ($global:JournalTestArgs -contains '*Journal.md') 'rgj default glob changed'
foreach ($selector in @('[tu]', '[missing]')) {
    $failed = $false
    try { igj ascii $selector } catch { $failed = $true }
    Assert $failed "Invalid selector $selector did not fail"
}
$failed = $false
try { igj ascii --journal } catch { $failed = $true }
Assert $failed 'Missing journal abbreviation did not fail'
Remove-Variable JournalTestArgs -Scope Global
'igj/rgj selectors, patterns, options, defaults, and errors: PASS'
