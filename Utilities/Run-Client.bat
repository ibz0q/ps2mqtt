@echo off
:Start
cd /d %~dp0
powershell.exe -windowstyle hidden "..\Client.ps1" > ..\Log.txt
TIMEOUT /T 2
GOTO:Start
