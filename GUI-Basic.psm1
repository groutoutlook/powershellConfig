function Invoke-HideTaskBar{
param (
    [ValidateSet("Hide", "Show")]
    [string]$Action = "Hide"
)
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern int ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
}
"@

$SW_HIDE = 0
$SW_SHOW = 5
$hWnd = [Win32]::FindWindow("Shell_TrayWnd", $null)
if ($Action -eq "Hide") {
    [Win32]::ShowWindow($hWnd, $SW_HIDE)
}
else {
    [Win32]::ShowWindow($hWnd, $SW_SHOW)
}
}