@echo off
rem install-autostart.cmd - put a shortcut to tools\silent.vbs into the Startup folder
rem the shortcut points to THIS folder, so re-run it after moving the folder
wscript.exe "%~dp0silent.vbs" install
echo.
pause
