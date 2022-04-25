
Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

# Your script here


$Config = Import-PowerShellDataFile ..\Config\Client.psd1
Write-Host "Configuration loaded"

$ClientParent = (get-item $PSScriptRoot ).parent.FullName  
$ClientPath = $ClientParent + "\Client.ps1"
$Powershell = (Get-Command powershell).Source

@"
:main

cd $ClientParent
start /b /wait cmd /c $Powershell -windowstyle hidden -File "$ClientPath" > Log.txt
timeout /t 1

goto :main

"@ | Out-File -FilePath Run-Continued.bat -Encoding ascii