# PowerShell Settings

## Key-combo search

`quick.query.psm1` translates Kanata-style keybindings for common editors and shells.

```powershell
ConvertTo-KeyComboText 'C-S-p'               # Ctrl+Shift+p (PowerShell style)
ConvertTo-KeyComboText 'c-l m-l'             # Ctrl+l Win+l
ConvertTo-KeyComboText 'c-w c-p' -Pipe       # ctrl+w ctrl+p
ConvertTo-KeyComboText 'C-M-A-S-kp1' -Style Kanata
ConvertTo-KeyComboText 'C-M-A-S-kp1' -Table # translation table
rgj "$(cq 'c-w c-p' -Style Search)"        # regex-safe note search
Search-KeyComboNotes 'c-w c-p'              # same search as a command
Get-KeyComboDictionary | Format-Table
Find-PSReadLineKeyBinding 'Ctrl+h'
Find-PSReadLineKeyBinding 'Ctrl+h' -Exact
```

The default output is PSReadLine-compatible. `Plus`/`Pipe` emits lowercase
`ctrl+meta+alt+shift+...`; `Search` escapes plus signs for `rgj`. Pressing
Ctrl+S on a line beginning with `cq` or `ConvertTo-KeyComboText` expands it
to `rgj "$(... -Style Search)"` as editable command text.




