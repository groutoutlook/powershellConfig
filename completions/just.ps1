using namespace System.Management.Automation
using namespace System.Management.Automation.Language
# HACK: just command name
$justCommandName = "r"
Register-ArgumentCompleter -Native -CommandName '$justCommandName' -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)

    $commandElements = $commandAst.CommandElements
    $command = @(
        '$justCommandName'
        for ($i = 1; $i -lt $commandElements.Count; $i++) {
            $element = $commandElements[$i]
            if ($element -isnot [StringConstantExpressionAst] -or
                $element.StringConstantType -ne [StringConstantType]::BareWord -or
                $element.Value.StartsWith('-') -or
                $element.Value -eq $wordToComplete) {
                break
        }
        $element.Value
    }) -join ';'

    $completions = @(switch ($command) {
        '$justCommandName' {
            [CompletionResult]::new('--alias-style', '--alias-style', [CompletionResultType]::ParameterName, 'Set list command alias display style')
            [CompletionResult]::new('--chooser', '--chooser', [CompletionResultType]::ParameterName, 'Override binary invoked by `--choose`')
            [CompletionResult]::new('--color', '--color', [CompletionResultType]::ParameterName, 'Print colorful output')
            [CompletionResult]::new('--command-color', '--command-color', [CompletionResultType]::ParameterName, 'Echo recipe lines in <COMMAND-COLOR>')
            [CompletionResult]::new('--dotenv-filename', '--dotenv-filename', [CompletionResultType]::ParameterName, 'Search for environment file named <DOTENV-FILENAME> instead of `.env`')
            [CompletionResult]::new('-E', '-E ', [CompletionResultType]::ParameterName, 'Load <DOTENV-PATH> as environment file instead of searching for one')
            [CompletionResult]::new('--dotenv-path', '--dotenv-path', [CompletionResultType]::ParameterName, 'Load <DOTENV-PATH> as environment file instead of searching for one')
            [CompletionResult]::new('--dump-format', '--dump-format', [CompletionResultType]::ParameterName, 'Dump justfile as <FORMAT>')
            [CompletionResult]::new('-f', '-f', [CompletionResultType]::ParameterName, 'Use <JUSTFILE> as justfile')
            [CompletionResult]::new('--justfile', '--justfile', [CompletionResultType]::ParameterName, 'Use <JUSTFILE> as justfile')
            [CompletionResult]::new('--list-heading', '--list-heading', [CompletionResultType]::ParameterName, 'Print <TEXT> before list')
            [CompletionResult]::new('--list-prefix', '--list-prefix', [CompletionResultType]::ParameterName, 'Print <TEXT> before each list item')
            [CompletionResult]::new('--set', '--set', [CompletionResultType]::ParameterName, 'Override <VARIABLE> with <VALUE>')
            [CompletionResult]::new('--shell', '--shell', [CompletionResultType]::ParameterName, 'Invoke <SHELL> to run recipes')
            [CompletionResult]::new('--shell-arg', '--shell-arg', [CompletionResultType]::ParameterName, 'Invoke shell with <SHELL-ARG> as an argument')
            [CompletionResult]::new('--timestamp-format', '--timestamp-format', [CompletionResultType]::ParameterName, 'Timestamp format string')
            [CompletionResult]::new('-d', '-d', [CompletionResultType]::ParameterName, 'Use <WORKING-DIRECTORY> as working directory. --justfile must also be set')
            [CompletionResult]::new('--working-directory', '--working-directory', [CompletionResultType]::ParameterName, 'Use <WORKING-DIRECTORY> as working directory. --justfile must also be set')
            [CompletionResult]::new('-c', '-c', [CompletionResultType]::ParameterName, 'Run an arbitrary command with the working directory, `.env`, overrides, and exports set')
            [CompletionResult]::new('--command', '--command', [CompletionResultType]::ParameterName, 'Run an arbitrary command with the working directory, `.env`, overrides, and exports set')
            [CompletionResult]::new('--completions', '--completions', [CompletionResultType]::ParameterName, 'Print shell completion script for <SHELL>')
            [CompletionResult]::new('-l', '-l', [CompletionResultType]::ParameterName, 'List available recipes in <MODULE> or root if omitted')
            [CompletionResult]::new('--list', '--list', [CompletionResultType]::ParameterName, 'List available recipes in <MODULE> or root if omitted')
            [CompletionResult]::new('--request', '--request', [CompletionResultType]::ParameterName, 'Execute <REQUEST>. For internal testing purposes only. May be changed or removed at any time.')
            [CompletionResult]::new('-s', '-s', [CompletionResultType]::ParameterName, 'Show recipe at <PATH>')
            [CompletionResult]::new('--show', '--show', [CompletionResultType]::ParameterName, 'Show recipe at <PATH>')
            [CompletionResult]::new('--check', '--check', [CompletionResultType]::ParameterName, 'Run `--fmt` in ''check'' mode. Exits with 0 if justfile is formatted correctly. Exits with 1 and prints a diff if formatting is required.')
            [CompletionResult]::new('--clear-shell-args', '--clear-shell-args', [CompletionResultType]::ParameterName, 'Clear shell arguments')
            [CompletionResult]::new('-n', '-n', [CompletionResultType]::ParameterName, 'Print what just would do without doing it')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Print what just would do without doing it')
            [CompletionResult]::new('--explain', '--explain', [CompletionResultType]::ParameterName, 'Print recipe doc comment before running it')
            [CompletionResult]::new('-g', '-g', [CompletionResultType]::ParameterName, 'Use global justfile')
            [CompletionResult]::new('--global-justfile', '--global-justfile', [CompletionResultType]::ParameterName, 'Use global justfile')
            [CompletionResult]::new('--highlight', '--highlight', [CompletionResultType]::ParameterName, 'Highlight echoed recipe lines in bold')
            [CompletionResult]::new('--list-submodules', '--list-submodules', [CompletionResultType]::ParameterName, 'List recipes in submodules')
            [CompletionResult]::new('--no-aliases', '--no-aliases', [CompletionResultType]::ParameterName, 'Don''t show aliases in list')
            [CompletionResult]::new('--no-deps', '--no-deps', [CompletionResultType]::ParameterName, 'Don''t run recipe dependencies')
            [CompletionResult]::new('--no-dotenv', '--no-dotenv', [CompletionResultType]::ParameterName, 'Don''t load `.env` file')
            [CompletionResult]::new('--no-highlight', '--no-highlight', [CompletionResultType]::ParameterName, 'Don''t highlight echoed recipe lines in bold')
            [CompletionResult]::new('--one', '--one', [CompletionResultType]::ParameterName, 'Forbid multiple recipes from being invoked on the command line')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Suppress all output')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Suppress all output')
            [CompletionResult]::new('--allow-missing', '--allow-missing', [CompletionResultType]::ParameterName, 'Ignore missing recipe and module errors')
            [CompletionResult]::new('--shell-command', '--shell-command', [CompletionResultType]::ParameterName, 'Invoke <COMMAND> with the shell used to run recipe lines and backticks')
            [CompletionResult]::new('--timestamp', '--timestamp', [CompletionResultType]::ParameterName, 'Print recipe command timestamps')
            [CompletionResult]::new('-u', '-u', [CompletionResultType]::ParameterName, 'Return list and summary entries in source order')
            [CompletionResult]::new('--unsorted', '--unsorted', [CompletionResultType]::ParameterName, 'Return list and summary entries in source order')
            [CompletionResult]::new('--unstable', '--unstable', [CompletionResultType]::ParameterName, 'Enable unstable features')
            [CompletionResult]::new('-v', '-v', [CompletionResultType]::ParameterName, 'Use verbose output')
            [CompletionResult]::new('--verbose', '--verbose', [CompletionResultType]::ParameterName, 'Use verbose output')
            [CompletionResult]::new('--yes', '--yes', [CompletionResultType]::ParameterName, 'Automatically confirm all recipes.')
            [CompletionResult]::new('--changelog', '--changelog', [CompletionResultType]::ParameterName, 'Print changelog')
            [CompletionResult]::new('--choose', '--choose', [CompletionResultType]::ParameterName, 'Select one or more recipes to run using a binary chooser. If `--chooser` is not passed the chooser defaults to the value of $JUST_CHOOSER, falling back to `fzf`')
            [CompletionResult]::new('--dump', '--dump', [CompletionResultType]::ParameterName, 'Print justfile')
            [CompletionResult]::new('-e', '-e', [CompletionResultType]::ParameterName, 'Edit justfile with editor given by $VISUAL or $EDITOR, falling back to `vim`')
            [CompletionResult]::new('--edit', '--edit', [CompletionResultType]::ParameterName, 'Edit justfile with editor given by $VISUAL or $EDITOR, falling back to `vim`')
            [CompletionResult]::new('--evaluate', '--evaluate', [CompletionResultType]::ParameterName, 'Evaluate and print all variables. If a variable name is given as an argument, only print that variable''s value.')
            [CompletionResult]::new('--fmt', '--fmt', [CompletionResultType]::ParameterName, 'Format and overwrite justfile')
            [CompletionResult]::new('--groups', '--groups', [CompletionResultType]::ParameterName, 'List recipe groups')
            [CompletionResult]::new('--init', '--init', [CompletionResultType]::ParameterName, 'Initialize new justfile in project root')
            [CompletionResult]::new('--man', '--man', [CompletionResultType]::ParameterName, 'Print man page')
            [CompletionResult]::new('--summary', '--summary', [CompletionResultType]::ParameterName, 'List names of available recipes')
            [CompletionResult]::new('--variables', '--variables', [CompletionResultType]::ParameterName, 'List names of variables')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('-V', '-V ', [CompletionResultType]::ParameterName, 'Print version')
            [CompletionResult]::new('--version', '--version', [CompletionResultType]::ParameterName, 'Print version')
            break
        }
    })

    function Get-JustFileRecipes([string[]]$CommandElements) {
        $justFileIndex = $commandElements.IndexOf("--justfile");

        if ($justFileIndex -ne -1 -and $justFileIndex + 1 -le $commandElements.Length) {
            $justFileLocation = $commandElements[$justFileIndex + 1]
        }

        $justArgs = @("--summary")

        if (Test-Path $justFileLocation) {
            $justArgs += @("--justfile", $justFileLocation)
        }

        $recipes = $(just @justArgs) -split ' '
        return $recipes | ForEach-Object { [CompletionResult]::new($_) }
    }

    $elementValues = $commandElements | Select-Object -ExpandProperty Value
    $recipes = Get-JustFileRecipes -CommandElements $elementValues
    $completions += $recipes
    $completions.Where{ $_.CompletionText -like "$wordToComplete*" } |
        Sort-Object -Property ListItemText
}
