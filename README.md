
  

# ps2mqtt (PowerShell 2 MQTT)

  

ps2mqtt (PowerShell 2 MQTT) lets you run PowerShell code based on MQTT events, useful for home automation applications.

  
E.g. A message to topic **ps2mqtt/recipe/open-chrome** will trigger **/Recipe/Open-Chrome/Main.ps1** 

  

Features:

* Written purely in PowerShell and runs with little dependencies  

* Uses open-source .Net MQTT library

* Callback support (know once your script has finished running)

* Asynchronous and synchronous workflows (stacked executions)

* Supports UTF-8 Subscribed messages

* Bi-directional data handling to publish or receive metadata (i.e. back to the topic or get data from a parameter inside a topic)

  

## Why
 
  I wanted to show a Windows Toast on my screen after someone pressed my doorbell, turn on a screen and show a live camera feed of visitors and many other things, with no good projects out there I wrote one.
  
  
## Setup

/Client.ps1 should be run as a background job, I have created Utilities/Run-Client.bat to run this file and keep it running in case of failure. It also captures console output and writes it as a log file ../Log.txt. Use the Client.psd1 file to configure this application, I have tried to expose everything I find useful.

I've included an export of my scheduled task Utilities/ps2mqtt.xml to give you an idea how I have it setup to run automatically on start up.

Lastly you need the M2Mqtt dll which can be downloaded from https://www.nuget.org/packages/M2Mqtt/, place this inside Library/M2Mqtt. It was not included due to licensing. 

Hint: The nuget file is an archive. Choose a DLL appropriate to your arch.

## Usage

"Recipes" directory should contain the code you wish to expose via MQTT. 

**Example of a custom Recipe:**
 

Create a folder inside "Recipes" called EXAMPLE1

  

    Recipes/EXAMPLE1

  

Place your code in a file called 'Main.ps1'
  

    Recipes/EXAMPLE1/Main.ps1

  

Call the topic using MQTT

    ps2mqtt/recipe/EXAMPLE1

Then the script will execute Main.ps1 inside the EXAMPLE1 folder.

### Supported Parameters
You can pass through parameters at the end of the topic such as..

#### Async / Sync

    ps2mqtt/recipe/EXAMPLE1(sync)

Allows you to change the default behaviour to run the script syncronously. It's useful if you have a sequence of tasks that need to be run in order e.g. Open a webpage, then an app, then wait until it's loaded and exit.

### Custom Parameters

You can passthrough any parameters of your choosing seperated by a comma.

    ps2mqtt/recipe/EXAMPLE1(param1,param2,param3)

These will be made available by using the global variable **$Parameters** inside Main.ps1.

### Passthrough data

You can send JSON data to your Main.ps1 script by publishing JSON data to your topic.

This will be made available using the global variable **$Message** inside Main.ps1. Data can be of any type supported by your broker.

###  Callbacks

Once you publish your topic, you may want to know if it has finished running. You can monitor the MQTT->Topics->Publish->Callback topic set inside your config.

When a async or sync task has finished executing a sub topic will be published this topic to indicate the run has finished. 



## Configuration

  
The config is inside:
> \Config\Client.psd1  

#### MQTT Server Settings

Set your MQTT server settings within the MQTT block, this includes Server name (can have port) , Schema names of the topics (You can change **ps2mqtt** to the name of your device, in my case I use **door**  because I use a door PC to show a video stream and various other things ) .


Recommendation: Ensure you use a private trusted MQTT server (Ideally LAN, otherwise use TLS for servers on WAN).. an attacker could run code directly on your machine using this script. 

  

Client DLL path is for the NuGet dependency this project uses.

  
