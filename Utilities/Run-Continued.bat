:main

cd C:\Program Files\ps2mqtt
start /b /wait cmd /c C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -windowstyle hidden -File "C:\Program Files\ps2mqtt\Client.ps1" > Log2.txt
timeout /t 1

goto :main

