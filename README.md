# A simple Linux configuration to play startup sound
Using sddm scripts for timing sound playing, using [BlueALSA](https://github.com/Arkq/bluez-alsa) to play over Bluetooth device when it is available, and using "aplay" to play audio. 
> Most DMs have their configurations similar to scripts of sddm to achieve this thing

I describe every problem i faced and the solution i found for it. 

---

At first, i decided to create a custome shell script and run it as systemd service but found that script of sddm has better timing. 

## Problem 1
__Got an "aplay: main:850: audio open error: Host is down" error__
### Solution
This is caused by the wrong Alsa configuration _(/etc/asound.conf)_. It was using HDMI as a playback device so i modified it and set my correct sound card. To find yours, issue "aplay -l". 

## Problem 2
__I wanted to play sound via a bluetooth device when it is available__
### Solution 
Because audio servers like Pipewire run with user login, i couldn't use them before user login so i decided to use BlueALSA to communicate bluetooth device with Alsa directly. I created systemd service to check and attempt to connect to bluetooth devices and then configure Alsa to use BlueALSA if it is needed, otherwise use the default physical sound card. _(alsa-config-gen.sh & alsa-config.service)_

Don't forget to enable the service 

## Problem 3
__Bluetooth audio codecs messed up after installing BlueALSA__
### Solution 
Simply added stopping BlueALSA service command after playing sound command
