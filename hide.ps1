# hide.ps1 - hide RustDesk window(s): process + tray stay, no window in taskbar/Start
Add-Type -Namespace W -Name U -MemberDefinition '[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);'
for ($i = 0; $i -lt 5; $i++) {
  Get-Process -Name "rustdesk*" -ErrorAction SilentlyContinue | ForEach-Object {
    if ($_.MainWindowHandle -ne [IntPtr]::Zero) {
      [void][W.U]::ShowWindow($_.MainWindowHandle, 0)
    }
  }
  Start-Sleep -Seconds 2
}
exit 0
