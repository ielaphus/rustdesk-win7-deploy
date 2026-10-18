@echo off
rem start-rustdesk.cmd - start RustDesk minimized (no Telegram notify), then hide the window
setlocal
set "ROOT=%~dp0.."
set "LOG=%ROOT%\last.log"
set "EXE="
for %%F in ("%ROOT%\rustdesk*.exe") do set "EXE=%%~fF"
if not defined EXE set "EXE=%LOCALAPPDATA%\rustdesk\rustdesk.exe"
>> "%LOG%" echo === start-rustdesk %DATE% %TIME%
>> "%LOG%" echo exe: %EXE%
if not exist "%EXE%" goto no_exe
start "" /min /d "%ROOT%" "%EXE%"
>> "%LOG%" echo start rc=%errorlevel%
ping -n 12 127.0.0.1 >nul
if exist "%ROOT%\hide.ps1" powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%ROOT%\hide.ps1"
tasklist /fi "imagename eq rustdesk.exe" | find /i "rustdesk.exe" >nul
if errorlevel 1 (>> "%LOG%" echo process: NOT RUNNING) else (>> "%LOG%" echo process: RUNNING)
goto end
:no_exe
>> "%LOG%" echo ERROR: rustdesk exe not found, put rustdesk-*-x86_64.exe into "%ROOT%"
echo RustDesk exe not found in "%ROOT%"
:end
>> "%LOG%" echo === end
echo.
pause
