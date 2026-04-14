param (
    [string]$Message = "Time to have lunch, Amigo",
    [int]$DurationSeconds = 60
)

Add-Type -AssemblyName PresentationFramework, PresentationCore, System.Windows.Forms

# P/Invoke helper to make overlay click-through
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32Helper {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern int GetWindowLong(IntPtr hWnd, int nIndex);
    [DllImport("user32.dll", SetLastError = true)]
    public static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);
    public const int GWL_EXSTYLE = -20;
    public const int WS_EX_TRANSPARENT = 0x20;
}
"@

$overlayList = New-Object System.Collections.Generic.List[System.Windows.Window]
$ctrlList    = New-Object System.Collections.Generic.List[System.Windows.Window]

function Close-AllWindows {
    foreach ($w in ($overlayList + $ctrlList)) {
        if ($w -and $w.IsVisible) {
            $w.Dispatcher.Invoke([Action]{ $w.Close() })
        }
    }
}

$screens = [System.Windows.Forms.Screen]::AllScreens

foreach ($screen in $screens) {
    # ---- Click-through overlay ----
    $overlay = New-Object System.Windows.Window
    $overlay.WindowStyle = "None"
    $overlay.AllowsTransparency = $true
    $overlay.Background = "#99000000"
    $overlay.Topmost = $true
    $overlay.ShowInTaskbar = $false
    $overlay.ShowActivated = $false

    $overlay.Left = $screen.Bounds.X
    $overlay.Top = $screen.Bounds.Y
    $overlay.Width = $screen.Bounds.Width
    $overlay.Height = $screen.Bounds.Height

    $textBlock = New-Object System.Windows.Controls.TextBlock
    $textBlock.Text = $Message
    $textBlock.FontSize = 100
    $textBlock.Foreground = "White"
    $textBlock.FontWeight = "Bold"
    $textBlock.HorizontalAlignment = "Center"
    $textBlock.VerticalAlignment = "Center"
    $textBlock.TextAlignment = "Center"
    $textBlock.TextWrapping = "Wrap"

    $overlay.Content = $textBlock
    $overlayList.Add($overlay)

    # ---- Close button window (solid, clickable) ----
    $ctrl = New-Object System.Windows.Window
    $ctrl.WindowStyle = "None"
    $ctrl.AllowsTransparency = $false
    $ctrl.Background = "#CCFF4444"
    $ctrl.Topmost = $true
    $ctrl.ShowInTaskbar = $false
    $ctrl.ShowActivated = $false
    $ctrl.ResizeMode = "NoResize"
    $ctrl.Width = 56
    $ctrl.Height = 32
    $ctrl.Left = $screen.Bounds.X + $screen.Bounds.Width - 66
    $ctrl.Top = $screen.Bounds.Y + 10

    $btn = New-Object System.Windows.Controls.Button
    $btn.Content = "X"
    $btn.Width = 56
    $btn.Height = 32
    $btn.Background = "#CCFF4444"
    $btn.Foreground = "White"
    $btn.FontWeight = "Bold"
    $btn.BorderThickness = "0"
    $btn.Add_Click({ Close-AllWindows })

    $ctrl.Content = $btn

    # Fallback: clicking anywhere on the red box also closes
    $ctrl.Add_MouseLeftButtonDown({ Close-AllWindows })

    $ctrlList.Add($ctrl)
}

# Show overlays and make them click-through
foreach ($overlay in $overlayList) {
    $overlay.Show()
    $helper = New-Object System.Windows.Interop.WindowInteropHelper($overlay)
    $hwnd = $helper.Handle
    $exStyle = [Win32Helper]::GetWindowLong($hwnd, [Win32Helper]::GWL_EXSTYLE)
    [Win32Helper]::SetWindowLong($hwnd, [Win32Helper]::GWL_EXSTYLE, $exStyle -bor [Win32Helper]::WS_EX_TRANSPARENT) | Out-Null
}

# Show all control windows except the last one
for ($i = 0; $i -lt $ctrlList.Count - 1; $i++) {
    $ctrlList[$i].Show()
}

# Auto-close timer
if ($DurationSeconds -gt 0) {
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromSeconds($DurationSeconds)
    $timer.Add_Tick({
        Close-AllWindows
        $timer.Stop()
    })
    $timer.Start()
}

# Keep alive with ShowDialog on the last control window
if ($ctrlList.Count -gt 0) {
    $ctrlList[-1].ShowDialog() | Out-Null
}
