# rustdesk-win7-deploy

Silent, autostarting RustDesk on Windows 7 (and any Windows), plus a fix for the blinking
remote cursor that hits Windows 7 hosts.

RustDesk itself runs fine on Windows 7, but the stock experience is noisy: a window on every
boot, no way to learn the peer ID when nobody sits at the PC, and on Win7 the remote pointer
blinks about once a second. This repo is the small wrapper I built and still use on a real
Windows 7 SP1 box that is controlled from an Android tablet.

## What it does

- starts RustDesk hidden on logon (`silent-start.cmd`, Startup shortcut)
- keeps every RustDesk window hidden with a PowerShell watchdog
- sends "PC is up + RustDesk ID + LAN/external IP" to Telegram on every boot
- kills the portable-service helper, which is what makes the cursor blink on Win7
  (see [docs/cursor-fix.md](docs/cursor-fix.md))
- uninstalls cleanly (process, Startup entry, RustDesk config and unpacked payload)

## Verified on

| | |
|---|---|
| Host | Windows 7 SP1 x64, build 7601 |
| RustDesk | 1.4.9 portable, GDI capture (no DXGI on Win7) |
| Client | Android tablet, LAN and over the internet |
| Node | 14.21.3 portable `node.exe`, no install |

## Quick start

1. Put `rustdesk-*-x86_64.exe` into the repo root. Optional: `node.exe` (notifier) and
   `tg.json` (see [docs/telegram.md](docs/telegram.md)).
2. Run `silent-start.cmd` - RustDesk starts minimized, then the window disappears.
3. Run `tools\install-autostart.cmd` - same thing on every logon.

The shortcut points to wherever the folder lies right now, so moving or copying the folder only
requires re-running `tools\install-autostart.cmd`.

## Layout

```
silent-start.cmd          hidden start, the only visible file in the root
tools\silent.vbs          does the work: watchdog, RustDesk, hide, notify
tools\hide-watch.ps1      hides rustdesk windows + kills the cursor-breaking helper
tools\hide.ps1            one-shot window hider
tools\install-autostart.cmd  Startup shortcut (points to the current path)
tools\remove-autostart.cmd   remove that shortcut
tools\start-visible.cmd   start RustDesk with a normal visible window
tools\start-rustdesk.cmd  start RustDesk minimized, no notify
tools\watch-stop.cmd      stop the watchdog
tools\uninstall.cmd       full removal
tools\diag.cmd            quick state dump
notify\idnotify.js        Telegram message with ID and IPs
notify\tg.js              small Telegram helper (updates / send / setchat)
docs\cursor-fix.md        why the Win7 pointer blinks and what exactly fixes it
docs\telegram.md          bot setup, no code changes needed
```

## The cursor fix

RustDesk's `mouse_cursor` service polls every 33 ms, but on Win7 every poll ends with
`Error of mouse_cursor service ... (os error 87)` and the loop sleeps 1 s, so the client gets
cursor updates once per second and the pointer blinks. Cause: the portable build reads the
cursor through the portable-service helper's shared memory, gets `FALSE` when the counter has
no fresh value, turns that into a stale `last_os_error`, and then parks the thread for a full
second. Full write-up with source references: [docs/cursor-fix.md](docs/cursor-fix.md).

Workaround used here: `hide-watch.ps1` kills the helper process every couple of seconds, so
`get_cursor_info()` falls back to a direct `GetCursorInfo()` call in the interactive process.
Cost: the client's elevation (UAC) request stops working.

Upstream report: https://github.com/rustdesk/rustdesk/discussions/16592

## Uninstall

`tools\uninstall.cmd` - kills the process, removes the Startup shortcut and the Run key,
deletes `%APPDATA%\RustDesk`, `%LOCALAPPDATA%\rustdesk` and `%ProgramData%\RustDesk`.
The folder itself is left for you to delete.

## Notes

- `tg.json` holds your bot token; it is in `.gitignore` and never goes to the repo.
- On Windows 10/11 the cursor fix is not needed, the rest works the same.
- The UAC and logon-screen capture needs RustDesk installed as a service; this project
  deliberately stays portable.

## Work with me

Small jobs around Windows and legacy environments: remote access setup, Win7/old hardware
rescue, AutoCAD LISP automation, CNC post-processors, static sites (Netlify), Android APK
inspections. Telegram: @Arsenum

## RU

Тихая установка RustDesk на Windows 7: скрытый автозапуск, окно не мешает, ID приходит в
Telegram, курсор на планшете не мигает. Старт - `silent-start.cmd`, автозагрузка -
`tools\install-autostart.cmd`, удаление - `tools\uninstall.cmd`. Подробности по курсору -
`docs\cursor-fix.md`.

## License

MIT, see [LICENSE](LICENSE).
