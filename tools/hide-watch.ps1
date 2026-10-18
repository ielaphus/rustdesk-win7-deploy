# hide-watch.ps1 - watch and hide any RustDesk window (session panel, prompts, banners)
# start: powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File hide-watch.ps1
# stop : tools\watch-stop.vbs
#
# Also kills the elevated 'portable service' helper:
#   rustdesk.exe --run-as-system --portable-service-shmem-name=_portable_service_<pid>_<id>
# That helper runs under a different token/window station, so its cursor thread
# (GetCursorInfo) fails with "os error 87" every second -> the remote cursor blinks.
# Without the helper RustDesk reads the cursor in its own process: no errors, no blinking.
$ErrorActionPreference = 'SilentlyContinue'
# single instance guard (mutex, not command-line matching)
$mutex = New-Object System.Threading.Mutex($false, 'Local\rustdesk-hide-watch')
if (-not $mutex.WaitOne(0)) { exit 0 }
Add-Type -Namespace W -Name U -MemberDefinition '[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$killlog = Join-Path $here 'cursor.log'
$tick = 0
while ($true) {
  Get-Process -Name 'rustdesk*' -ErrorAction SilentlyContinue | ForEach-Object {
    if ($_.MainWindowHandle -ne [IntPtr]::Zero) {
      [void][W.U]::ShowWindow($_.MainWindowHandle, 0)
    }
  }
  $tick++
  if ($tick -ge 8) {
    $tick = 0
    foreach ($p in (Get-WmiObject Win32_Process -Filter "Name='rustdesk.exe'" -ErrorAction SilentlyContinue)) {
      if ($p.CommandLine -like '*portable-service-shmem-name*') {
        $id = $p.ProcessId
        Stop-Process -Id $id -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 300
        $alive = @(Get-Process -Id $id -ErrorAction SilentlyContinue).Count
        if ($alive -gt 0) {
          & taskkill /f /pid $id 2>&1 | Out-Null
          Start-Sleep -Milliseconds 200
          $alive = @(Get-Process -Id $id -ErrorAction SilentlyContinue).Count
        }
        ((Get-Date).ToString('yyyy-MM-dd HH:mm:ss') + ' kill portable-service pid=' + $id + ' alive_after=' + $alive) | Out-File -FilePath $killlog -Append -Encoding UTF8
      }
    }
  }
  Start-Sleep -Milliseconds 250
}
