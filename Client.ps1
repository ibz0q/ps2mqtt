Try {
	
    $ErrorActionPreference = "Stop"
    $Global:AsyncTask = @{}
    $Global:Loop = $True
    $Global:Shared = @()
    $InvocationPath = (Split-Path $script:MyInvocation.MyCommand.Path)

    Set-Location $InvocationPath
    $Global:Config = Import-PowerShellDataFile .\Config\Client.psd1
    Write-Host (Get-Date) "INIT: Configuration loaded"
    
    If ($Loaded -ne $True) {
        Add-Type -Path $Global:Config.ClientDLLPath
        $Loaded = $True # Line Needed For Development Only
        Write-Host (Get-Date) "INIT: Assembly loaded..."
    }

    $Global:MqttClientMain = [uPLibrary.Networking.M2Mqtt.MqttClient]($Global:Config.MQTT.Server);
    
    $Connect = $Global:MqttClientMain.Connect([guid]::NewGuid(), $Global:Config.MQTT.Username, $Global:Config.MQTT.Password, $Global:Config.MQTT.WillRetain, $Global:Config.MQTT.WillQoSLevel, 1, $Global:Config.MQTT.Topics.Publish.Will, $Global:Config.MQTT.Messages.Will, $Global:Config.MQTT.CleanSession, $Global:Config.MQTT.KeepAlivePeriod )
    Write-Host (Get-Date) "INIT: Connected "

    $Sub = $Global:MqttClientMain.Subscribe($Global:Config.MQTT.Topics.Subscribe.Recipe, 0);
    Write-Host (Get-Date) "INIT: Subscribed to main topic..." $Global:Config.MQTT.Topics.Subscribe.Recipe

    $Publish = $Global:MqttClientMain.Publish($Global:Config.MQTT.Topics.Publish.Status, [System.Text.Encoding]::UTF8.GetBytes($Global:Config.MQTT.Messages.Birth), $Global:Config.MQTT.StatusQoS, $Global:Config.MQTT.StatusRetain)
    Write-Host (Get-Date) "INIT: Published birth message"

    # Publish state on any event
    Function Global:GetGuid($maxSize = 10) {
        $g = [guid]::NewGuid()
        $v = [string]$g
        $v = $v.Replace("-", "")
        return $v.substring(0, $maxSize)
    }

    Function Global:MQTTMsgReceived {
        Param(
            [parameter(Mandatory = $true)]$MqttObject
        )

        $CleanedRecipeTopic = $Global:Config.MQTT.Topics.Subscribe.Recipe -replace "#", ""
    
        Try {
            $TopicRaw = $MqttObject.Topic

            Write-Host (Get-Date) "EVENT: Got... " $TopicRaw

            If (($MqttObject.Topic).StartsWith($CleanedRecipeTopic) ) {
                
                $Capture = [regex]::match($TopicRaw, ([regex]"\((.*)\)"))
            
                If ($Capture.Groups.Success -eq $True) {
                    $Parameters = $Capture.Groups[1] -split ","
                    Write-Host (Get-Date) "EVENT: Parameters captured:" $Parameters.Count "..."
                    $CleanedTopic = ($TopicRaw).replace($Capture.Groups[0].Value, "")
                    Write-Host (Get-Date) "EVENT: Topic $CleanedTopic..."
                    $Recipe = ($CleanedTopic -split '/')[-1]
                }
                else {
                    $Recipe = ($TopicRaw -split '/')[-1]
                }
                $MessageDecoded = ([System.Text.Encoding]::UTF8.GetString($MqttObject.Message))
                $RecipePath = $Global:Config.RecipesPath + "\" + $Recipe
                Write-Host (Get-Date) "EVENT: Checking for recipe $RecipePath..."
            
                # Fix security issue, allows for directory traversal 
                If (($Recipe).IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -ne -1 ) {
                    Throw "Exception: The folder name ($Recipe) contains invalid characters"
                }

                If (Test-Path -Path ("$RecipePath\Main.ps1")) {
                
                    $Async = $True
                
                    If ($Global:Config.RecipeExecutionType -eq "sync") {
                        $Async = $False
                    }
 
                    If ($Capture.Groups.Success -eq $True -and $Parameters.Contains("async")) {
                        $Async = $True
                    }
                    elseif ($Capture.Groups.Success -eq $True -and $Parameters.Contains("sync")) {
                        $Async = $False
                    }
                
                    If ($Async -eq $True) {
                        Write-Host (Get-Date) "EVENT: Running recipe async" ($RecipePath + "\Main.ps1" )

                        $JobGuid = Global:GetGuid

                        $Global:AsyncTask[$JobGuid] = [PowerShell]::Create()
                        [void]$Global:AsyncTask[$JobGuid].AddScript( { 
                                Param($Object)
                                $Metadata = & $Object.File -Config $Object.Config -Message $Object.Message -InvocationPath $Object.InvocationPath
                                Return $Metadata
                            }).AddArgument(@{File = ($RecipePath + "\Main.ps1"); Config = $Global:Config ; Topic = $TopicRaw; Message = $MessageDecoded; Parameters = $Parameters; InvocationPath = $InvocationPath })
                        
                        $AsyncNull = $Global:AsyncTask[$JobGuid].BeginInvoke()

                        Register-ObjectEvent -InputObject $Global:AsyncTask[$JobGuid] -MessageData @{"Recipe" = $Recipe; "JobId" = $JobGuid } -EventName InvocationStateChanged  -Action {
                            Write-Host (Get-Date) "EVENT: Async callback received for"$Event.MessageData.Recipe
                            $Global:MqttClientMain.Publish(($Global:Config.MQTT.Topics.Publish.Callback + "/" + $Event.MessageData.Recipe), [System.Text.Encoding]::UTF8.GetBytes("1"), $Global:Config.MQTT.CallbackQoS, $Global:Config.MQTT.CallbackRetain)
                        }
                        
                    }
                    else {
                        Write-Host (Get-Date) "EVENT: Running recipe sync" ($RecipePath + "\Main.ps1" )
                        & ($RecipePath + "\Main.ps1") -Config $Global:Config -Topic $TopicRaw -Message $MessageDecoded -Parameters $Parameters -InvocationPath $InvocationPath
                        $Global:MqttClientMain.Publish(($Global:Config.MQTT.Topics.Publish.Callback + "/" + $Recipe), [System.Text.Encoding]::UTF8.GetBytes("1"), $Global:Config.MQTT.CallbackQoS, $Global:Config.MQTT.CallbackRetain)

                    }

                    Write-Host (Get-Date) "EVENT: Completed job of" ($RecipePath + "\Main.ps1")

                }
                Else {
                    Write-Host (Get-Date) "EVENT: The recipe $RecipePath does not exist"
                }
            }

        }
        Catch {
            Write-Host (Get-Date) "Event Exception Occured"
            Write-Host $_
        }

    }
    Function Global:ConnectionClosed {
        Param(
            [parameter(Mandatory = $true)]$ConnectionClose
        )

        Write-Host (Get-Date) "Connection was closed..."
        $Global:Loop = $False
    }

    Register-ObjectEvent -inputObject $Global:MqttClientMain -EventName ConnectionClosed -Action { ConnectionClosed $($args[1]) } > $Null
    Register-ObjectEvent -inputObject $Global:MqttClientMain -EventName MqttMsgPublishReceived -Action { MQTTMsgReceived $($args[1]) } > $Null
    Write-Host (Get-Date) "INIT: Registered event listeners"

    While ($True) {
        Start-Sleep -Milliseconds $Global:Config.ApplicationLoopInterval
        If ($Global:Loop -ne $True) {
            Throw "Exception: Connection was likely lost..."
        }
    }

}
Catch {
    Write-Error $_
}
Finally {
	
    Try {	
        Write-Host (Get-Date) "Disconnecting from server and exiting..."
        $Global:MqttClientMain.Disconnect()
        Get-EventSubscriber -Force | Unregister-Event 
        Exit 1;
    }
    Catch {
        Write-Host (Get-Date) "Exiting unable to exit gracefully..."
        Exit 1;	
    }

}