' watch-stop.vbs - stop hide-watch.ps1 (kills powershell processes whose command line contains hide-watch)
Option Explicit
Dim wmi, procs, p, n
Set wmi = GetObject("winmgmts:\\.\root\cimv2")
Set procs = wmi.ExecQuery("SELECT ProcessId, CommandLine FROM Win32_Process WHERE Name='powershell.exe'")
n = 0
For Each p In procs
  If Not IsNull(p.CommandLine) Then
    If InStr(LCase(p.CommandLine), "hide-watch") > 0 Then
      p.Terminate 0
      n = n + 1
    End If
  End If
Next
WScript.Echo "watcher stopped: " & n
