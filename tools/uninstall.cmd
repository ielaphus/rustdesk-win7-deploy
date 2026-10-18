@echo off
rem uninstall.cmd - full removal: process, autostart, configs, unpacked payload
setlocal
echo Removing RustDesk...
taskkill /f /im rustdesk.exe >nul 2>&1
cscript //nologo "%~dp0watch-stop.vbs" >nul 2>&1
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
if exist "%STARTUP%\rustdesk-silent.lnk" del /f /q "%STARTUP%\rustdesk-silent.lnk"
if exist "%STARTUP%\win7-rust-notify.lnk" del /f /q "%STARTUP%\win7-rust-notify.lnk"
if exist "%STARTUP%\win7-rust-notify.cmd" del /f /q "%STARTUP%\win7-rust-notify.cmd"
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v RustDesk /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v RustDesk /f >nul 2>&1
if exist "%APPDATA%\RustDesk" rd /s /q "%APPDATA%\RustDesk"
if exist "%LOCALAPPDATA%\rustdesk" rd /s /q "%LOCALAPPDATA%\rustdesk"
if exist "%ProgramData%\RustDesk" rd /s /q "%ProgramData%\RustDesk"
echo Done. The folder itself is left for you to delete.
echo.
pause
