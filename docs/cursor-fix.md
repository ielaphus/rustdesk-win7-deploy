# Why the remote pointer blinks on a Windows 7 host

RustDesk 1.4.9, Windows 7 SP1 x64 build 7601, portable build, GDI capture, Android client.
The pointer blinks roughly once per second and the host log fills with

```
ERROR [src\server\service.rs:275] Error of mouse_cursor service: The parameter is incorrect. (os error 87)
```

## Cause

`run_cursor()` at `src/server/input_service.rs:395` runs the `mouse_cursor` service every 33 ms
and starts with `crate::get_cursor()?`. Any error is propagated to `src/server/service.rs:275`,
and the loop then sleeps `MAX_ERROR_TIMEOUT`, 1000 ms, before the next attempt.

`crate::get_cursor()` does not call `GetCursorInfo` on the portable build. It goes to
`portable_service::client::get_cursor_info()`, which reads the value from the helper process's
shared memory, filled by `run_get_cursor_info()`. On Windows 7 the helper never produces a
fresh value, `get_cursor_info_()` answers `FALSE`, and `get_cursor()` converts that `FALSE`
into `io::Error::last_os_error()` - a stale code left by some earlier call, 87 on this machine.
So the "os error 87" in the log does not come from `GetCursorInfo` at all, and the cursor
service ends up running at about 1 Hz instead of 30 Hz.

## Ruled out

- `GetCursorInfo` works from a normal process in the same session: 60 of 60 calls OK, stable
  `hCursor`.
- The cursor is not baked into the GDI `BitBlt` output: `SRCCOPY` vs `SRCCOPY|CAPTUREBLT`
  captures differ by zero pixels, so this is not the "CAPTUREBLT makes the cursor blink" effect.

## Fix used here

`tools/hide-watch.ps1` kills the helper process (`rustdesk.exe --run-as-system
--portable-service-shmem-name=...`) every couple of seconds. `portable_service::client::RUNNING`
becomes false, `get_cursor_info()` falls back to a direct `GetCursorInfo()` in the interactive
process, and the blinking stops. The video keeps working: capture moves from the helper into
the main process, the log shows `gdi:true, portable:false`. Cost: the client's elevation (UAC)
request no longer works, which is fine when UAC is off.

```powershell
Get-WmiObject Win32_Process -Filter "Name='rustdesk.exe'" | ForEach-Object {
  if ($_.CommandLine -like '*portable-service-shmem-name*') { Stop-Process -Id $_.ProcessId -Force }
}
```

## What a proper fix would look like

- fall back to `GetCursorInfo()` when the shared memory has no fresh value, "no data yet" is
  not an error
- never build an `io::Error` from `last_os_error()` when no Win32 call failed
- do not apply the 1 s error timeout to the "no fresh data" case
- log the real `GetLastError` inside `run_get_cursor_info()` on the helper side

Upstream report and discussion:
https://github.com/rustdesk/rustdesk/discussions/16592
