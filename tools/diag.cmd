@echo off
rem diag.cmd - quick state dump for this folder
setlocal
cd /d "%~dp0.."
echo === processes ===
tasklist /fi "imagename eq rustdesk.exe" 2>nul | findstr /i rustdesk
tasklist /fi "imagename eq powershell.exe" 2>nul | findstr /i powershell
echo.
echo === helper (should be empty, it breaks the cursor on Win7) ===
wmic process where "name='rustdesk.exe'" get processid,commandline 2>nul | findstr /i "portable-service-shmem-name"
echo.
echo === listening port ===
netstat -ano | findstr 21118
echo.
echo === last.log (tail) ===
powershell -NoProfile -ExecutionPolicy Bypass -Command "if (Test-Path last.log) { Get-Content last.log -Tail 15 }"
echo.
echo === cursor log (helper kills) ===
powershell -NoProfile -ExecutionPolicy Bypass -Command "if (Test-Path tools\cursor.log) { Get-Content tools\cursor.log -Tail 10 }"
echo.
echo === autostart shortcut ===
dir "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\rustdesk-silent.lnk" 2>nul
echo.
pause
