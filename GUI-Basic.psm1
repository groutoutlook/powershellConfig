function Switch-TaskbarHide {
    param (
        [ValidateSet("Hide", "Show")]
        [string]$Action = "Hide"
    )

    if (-not ('TaskbarNative' -as [Type])) {
        Add-Type @"
using System;
using System.Runtime.InteropServices;

[StructLayout(LayoutKind.Sequential)]
public struct RECT {
    public int left;
    public int top;
    public int right;
    public int bottom;
}

[StructLayout(LayoutKind.Sequential)]
public struct APPBARDATA {
    public int cbSize;
    public IntPtr hWnd;
    public uint uCallbackMessage;
    public uint uEdge;
    public RECT rc;
    public IntPtr lParam;
}

public static class TaskbarNative {
    [DllImport("user32.dll")]
    public static extern int ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

    [DllImport("shell32.dll")]
    public static extern uint SHAppBarMessage(uint dwMessage, ref APPBARDATA pData);

    public const int SW_HIDE = 0;
    public const int SW_SHOW = 5;
    public const uint ABM_SETSTATE = 0x0000000A;
    public const int ABS_AUTOHIDE = 0x1;
    public const int ABS_ALWAYSONTOP = 0x2;
}
"@
    }

    $taskbarHandle = [TaskbarNative]::FindWindow("Shell_TrayWnd", $null)
    if ($taskbarHandle -eq [IntPtr]::Zero) {
        throw "Unable to locate the taskbar window handle."
    }

    $appBarData = [APPBARDATA]::new()
    $appBarData.cbSize = [Runtime.InteropServices.Marshal]::SizeOf([APPBARDATA]::new())
    $appBarData.hWnd = $taskbarHandle

    if ($Action -eq "Hide") {
        $state = [TaskbarNative]::ABS_AUTOHIDE -bor [TaskbarNative]::ABS_ALWAYSONTOP
        $appBarData.lParam = [IntPtr]$state
        [TaskbarNative]::SHAppBarMessage([TaskbarNative]::ABM_SETSTATE, [ref]$appBarData) | Out-Null
        Start-Sleep -Seconds 1 # HACK: mandatory...
        [TaskbarNative]::ShowWindow($taskbarHandle, [TaskbarNative]::SW_HIDE) | Out-Null
    }
    else {
        $state = [TaskbarNative]::ABS_ALWAYSONTOP
        $appBarData.lParam = [IntPtr]$state
        [TaskbarNative]::ShowWindow($taskbarHandle, [TaskbarNative]::SW_SHOW) | Out-Null
        [TaskbarNative]::SHAppBarMessage([TaskbarNative]::ABM_SETSTATE, [ref]$appBarData) | Out-Null
    }
}

function Switch-TaskbarClickThrough {
    param(
        [switch]$Disable
    )
    
    if (-not ('Win32ClickThrough' -as [Type])) {
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class Win32ClickThrough {
    [DllImport("user32.dll")]
    public static extern int GetWindowLong(IntPtr hWnd, int nIndex);
    
    [DllImport("user32.dll")]
    public static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);
    
    [DllImport("user32.dll")]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

    public const int GWL_EXSTYLE = -20;
    public const int WS_EX_LAYERED = 0x80000;
    public const int WS_EX_TRANSPARENT = 0x20;
    public const int WS_EX_TOOLWINDOW = 0x80;
}
"@
    }
    
    $hwnd = [Win32ClickThrough]::FindWindow("Shell_TrayWnd", $null)
    if ($hwnd -eq [IntPtr]::Zero) { 
        Write-Error "Taskbar not found."
        return 
    }
    
    $style = [Win32ClickThrough]::GetWindowLong($hwnd, [Win32ClickThrough]::GWL_EXSTYLE)
    
    if ($Disable) {
        # Remove transparent: Enable clicking
        # But KEEP ToolWindow so it stays hidden from Alt+Tab
        $newStyle = ($style -band (-not [Win32ClickThrough]::WS_EX_TRANSPARENT)) -bor [Win32ClickThrough]::WS_EX_TOOLWINDOW
    } else {
        # Add transparent: Disable clicking (Clickthrough)
        # We ensure Layered is set, as Transparent often requires it.
        # Also enforcing ToolWindow style as requested to keep it hidden from Alt+Tab
        $newStyle = $style -bor [Win32ClickThrough]::WS_EX_TRANSPARENT -bor [Win32ClickThrough]::WS_EX_LAYERED -bor [Win32ClickThrough]::WS_EX_TOOLWINDOW
    }
    
    # Only update if changed
    if ($style -ne $newStyle) {
        [Win32ClickThrough]::SetWindowLong($hwnd, [Win32ClickThrough]::GWL_EXSTYLE, $newStyle) | Out-Null
    }
}

function Find-ExplorerShell {
    <#
    .SYNOPSIS
        Finds the handle of the Windows Taskbar (Shell_TrayWnd).
    .DESCRIPTION
        Returns the hex handle string (e.g. 0x501CC).
    .EXAMPLE
        smartcontextmenu --handle (Find-ExplorerShell) --transparency 60 --clickthrough on
    #>
    if (-not ('Win32ExplorerHelper' -as [Type])) {
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class Win32ExplorerHelper {
    [DllImport("user32.dll")]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
}
"@
    }
    
    $hwnd = [Win32ExplorerHelper]::FindWindow("Shell_TrayWnd", $null)
    
    if ($hwnd -ne [IntPtr]::Zero) {
        return "0x{0:X}" -f $hwnd.ToInt64()
    } else {
        Write-Warning "Shell_TrayWnd not found."
        return $null
    }
}
