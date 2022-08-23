
  

# ps2mqtt (PowerShell 2 MQTT)

  

ps2mqtt (or PowerShell 2 MQTT) is small utility that lets you listen and run code based on MQTT events, it's extremely useful for home automation applications.

  
 E.g. A  file (recipe) under **/Recipe/Open-Chrome/Main.ps1** can be triggered through a message to topic **ps2mqtt/recipe/open-chrome**

  

Features:

  
* Uses open-source .Net MQTT library

* Transparent / Less than 200 lines of PowerShell

* Callback support (know once your script has finished running)

* Asynchronous and synchronous workflows (stacked executions)

* Supports UTF-8 Subscribed messages

* Bi-directional data handling to publish or receive metadata (i.e. back to the topic or get data from a parameter inside a topic)

  

## Why

  
I wrote this to run in my old home and it was pretty decent so
I decided to open source this project and share it.

  
  I wanted to show a Windows Toast on my screen after someone pressed my doorbell, turn on a screen and show a live camera feed of visitors and many other things and no project exists at the time to do this.
  
  

## Usage 


The directory "Recipes" should contain the code you wish to expose via MQTT. 

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

### Passthrough JSON data

You can send JSON data to your Main.ps1 script by publishing JSON data to your topic.

This will be made available using the global variable **$Message** inside Main.ps1.

###  Callbacks

Once you publish your topic, you may want to know if it has finished running. You can monitor the MQTT->Topics->Publish->Callback topic set inside your config.

When a async or sync task has finished executing a sub topic will be published this topic to indicate the run has finished. 



## Configuration

  
The script config is available inside:
> \Config\Client.psd1

  
  

#### MQTT Server Settings

Set your MQTT server settings within the MQTT block, this includes Server name (can have port) , Schema names of the topics (You can change **ps2mqtt** to the name of your device, in my case I use **door**  because I use a door PC to show a video stream and various other things ) .

  

  

Client DLL path is for the NuGet dependency this project uses.

  
