@{
    MQTT                    = @{ 
        Server          = 'mqtt'
        Username        = $Null
        Password        = $Null
        Topics          = @{
            Publish   = @{
                Will     = "ps2mqtt/status"
                Status   = "ps2mqtt/status"
                Callback = "ps2mqtt/callback"
            }
            Subscribe = @{
                Recipe = "ps2mqtt/recipe/#" 
            }    
        }
        Messages        = @{
            Birth = "online"
            Will  = "disconnected"
        }
        WillRetain      = 0
        WillQoSLevel    = 1
        WillFlag        = 1
        StatusQoS       = 1
        StatusRetain    = 0
        CallbackQoS     = 1
        CallbackRetain  = 0
        CleanSession    = 1
        KeepAlivePeriod = 10
        Publish_State   = $True
    }
    ApplicationName         = "ps2mqtt"
    RecipesPath             = ".\Recipes"
    ApplicationLoopInterval = 100
	ClientDLLPath         = '.\Library\M2Mqtt\M2Mqtt.Net.dll'
    RecipeExecutionType     = "async"
}