@echo off
rem start-visible.cmd - start RustDesk with a normal visible window
rem stops the window hider first, otherwise the window disappears again
setlocal
set "ROOT=%~dp0.."
set "LOG=%ROOT%\last.log"
set "EXE="
for %%F in ("%ROOT%\rustdesk*.exe") do set "EXE=%%~fF"
if not defined EXE set "EXE=%LOCALAPPDATA%\rustdesk\rustdesk.exe"
>> "%LOG%" echo === start-visible %DATE% %TIME%
echo Stopping the window hider...
cscript //nologo "%~dp0watch-stop.vbs"
echo Starting RustDesk with a window...
>> "%LOG%" echo exe: %EXE%
if not exist "%EXE%" goto no_exe
start "" /d "%ROOT%" "%EXE%"
>> "%LOG%" echo start rc=%errorlevel% (window visible)
goto end
:no_exe
>> "%LOG%" echo ERROR: rustdesk exe not found
echo RustDesk exe not found in "%ROOT%"
:end
>> "%LOG%" echo === end
echo.
pause
