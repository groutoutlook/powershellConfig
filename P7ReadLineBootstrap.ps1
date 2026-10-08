# Compatibility for installed copies of the profile that still source this file.
# Keep the complete binding set, including Alt+V, while avoiding module discovery.
Import-Module "$PSHOME/Modules/Microsoft.PowerShell.Utility/Microsoft.PowerShell.Utility.psd1"
Import-Module "$PSHOME/Modules/Microsoft.PowerShell.Management/Microsoft.PowerShell.Management.psd1"
Import-Module "$PSHOME/Modules/PSReadLine/PSReadLine.psd1"
Import-Module "$env:p7settingDir/quickPSReadLine.psm1" -Scope Global
