Param (
    $Config = $Null, 
    $Message = $Null  
)
Function Set_AudioLevel($audioLevel) { $wshShell = new-object -com wscript.shell; 1..50 | % { $wshShell.SendKeys([char]174) }; $audioLevel = $audioLevel / 2; 1..$audioLevel | % { $wshShell.SendKeys([char]175) } }
Function Get-StringHash { 
    param
    (
        [String] $String,
        $HashName = "MD5"
    )
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($String)
    $algorithm = [System.Security.Cryptography.HashAlgorithm]::Create('MD5')
    $StringBuilder = New-Object System.Text.StringBuilder 
  
    $algorithm.ComputeHash($bytes) | 
    ForEach-Object { 
        $null = $StringBuilder.Append($_.ToString("x2")) 
    } 
  
    $StringBuilder.ToString() 
}

$Object = $Message | ConvertFrom-Json 

$Params = "";

$MediaObject = $Object.URL

If ($Object.File) {
    $MediaObject = $Object.File
}

If ($Object.Download -eq $True) {
    
    $TemporaryFile = $env:TEMP + "\ps2mqtt_" + (Get-StringHash $MediaObject) + ".tmp";
    $MediaObject = $TemporaryFile;

    If ((Test-Path -PathType Leaf -Path $TemporaryFile) -eq $False) {
        $WebClient = New-Object System.Net.WebClient
        "File does not exists... $TemporaryFile"
        If (($Object.Proxy -is [System.Object]) -eq $True) {
            $ProxySetting = "http://" + $Object.Proxy.IP + ":" + $Object.Proxy.Port
            $WebProxy = New-Object System.Net.WebProxy($ProxySetting, $true)
            $WebClient.Proxy = $WebProxy;
        }
        $WebClient.DownloadFile($Object.URL, $TemporaryFile)
    } else {

        "File already exists... $TemporaryFile"

    }
    
}

If ($Object.Hidden -eq $True) {
    $Params += "-I null "
}
    
If ($Object.SystemVolume) {
    Set_AudioLevel $Object.SystemVolume
}

"C:\Program` Files\VideoLAN\VLC\\vlc --fullscreen $MediaObject --volume="+$Object.MediaVolume+" $Params --play-and-exit --fullscreen"
& C:\Program` Files\VideoLAN\VLC\\vlc --fullscreen $MediaObject --volume=$Object.MediaVolume $Params --play-and-exit --fullscreen
