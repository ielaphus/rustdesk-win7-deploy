@echo off
rem remove-autostart.cmd - delete the Startup shortcut
wscript.exe "%~dp0silent.vbs" remove
echo.
pause
