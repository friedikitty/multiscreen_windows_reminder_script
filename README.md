# multiscreen_windows_reminder_script

![XmNVzp2YY2](README.assets/XmNVzp2YY2.jpg)

## Brief

- Shows a **full-screen reminder on every monitor** so it is harder to miss than a standard Windows toast in the corner.
- The overlay is **semi-transparent**; mouse input **passes through** to the apps underneath so you can keep working.
- A small **close control** (red **X**) on each screen **does** receive clicks and dismisses **all** overlays.
- Optional **auto-close** after a number of seconds (`-DurationSeconds`).
- Sample **Task Scheduler** XML files run `remine_me.ps1` on a daily schedule (lunch / dinner). Adjust times, messages, and script paths to match your machine.

## Quick Start

* `powershell -ExecutionPolicy Bypass -File "%~dp0remine_me.ps1" -Message "Prepare for launch, Amigo"  -DurationSeconds 3`

## Files

| File | Purpose |
|------|---------|
| `remine_me.ps1` | PowerShell script: WPF windows per display, click-through overlay + close buttons. |
| `manual_test.bat` | Quick local test: runs the script with a short duration. |
| `lunch_reminder.xml` | Task Scheduler export: daily lunch-time example. |
| `dinner_reminder.xml` | Task Scheduler export: daily dinner-time example. |

## Requirements

- Windows with PowerShell.
- Assemblies loaded by the script: `PresentationFramework`, `PresentationCore`, and `System.Windows.Forms` (for `Screen.AllScreens`).

## Usage

### Manual test

Run `manual_test.bat` from this folder (or invoke PowerShell yourself):

```bat
powershell -ExecutionPolicy Bypass -File "%~dp0remine_me.ps1" -Message "Your message" -DurationSeconds 3
```

### Scheduled tasks

1. Copy `remine_me.ps1` to a fixed path on your PC (the sample XML uses a path under `C:\Backup\`; change it if you use another location).
2. Open **Task Scheduler** and use **Import Task** on `lunch_reminder.xml` and `dinner_reminder.xml`, or run `schtasks` with the XML as documented by Microsoft.
3. Edit each task’s **Actions** so the `-File` argument points to **your** `remine_me.ps1`, and adjust `-Message` / `-DurationSeconds` as needed.
4. If import fails or the task does not run as your user, open the task, use **Change User or Group**, and pick your account so the **UserId** (SID) matches an interactive logon (`InteractiveToken`).

### Script parameters

- `-Message` — Text shown centered on each screen (large bold label).
- `-DurationSeconds` — If greater than `0`, closes all windows after that many seconds. Use `0` to rely only on the **X** button (the last close window still blocks with `ShowDialog` until you dismiss it).

## Detail[TL:DR]

### How click-through (“mouse penetrate”) works

1. For each entry in `[System.Windows.Forms.Screen]::AllScreens`, the script creates a **borderless, topmost, transparent WPF `Window`** that fills that monitor and shows the message.
2. After `$overlay.Show()`, it uses `WindowInteropHelper` to get the native HWND, then calls `GetWindowLong` / `SetWindowLong` with `GWL_EXSTYLE` and **`WS_EX_TRANSPARENT`** (`0x20`). That extended style tells Windows to **hit-test through** the window: clicks go to whatever is behind it.

### How a non-penetrable (clickable) area is added

The overlay alone would be impossible to close with the mouse if everything were click-through. The script therefore creates a **second, small WPF window** per screen for the **X** button:

- It does **not** apply `WS_EX_TRANSPARENT` to these windows.
- They use a solid background and a `Button` (and a `MouseLeftButtonDown` handler on the window) that calls `Close-AllWindows`.

So: **large area** = pass-through; **small red bar** = normal mouse capture for dismiss.

### Process lifetime and multiple monitors

- All overlay windows are shown first; then all close-button windows **except the last** are shown with `.Show()`.
- The **last** close-button window uses **`ShowDialog()`**, which keeps the PowerShell process alive and runs a message loop until that window closes.
- An optional `DispatcherTimer` calls `Close-AllWindows` when `-DurationSeconds` elapses.

### Privacy / sharing task XML

Exported tasks may contain a **user SID** in `Principals` / `UserId` and paths on disk. Redact or replace those before committing or publishing; re-import or reassign the task principal on each machine as needed.
