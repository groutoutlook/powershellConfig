function Hide-Taskbar {
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
    $appBarData.cbSize = [Runtime.InteropServices.Marshal]::SizeOf([APPBARDATA])
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
