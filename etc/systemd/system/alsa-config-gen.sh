#!/bin/bash
#
# /etc/systemd/system/alsa-config-gen.sh
# The path to use script system-wide
#
# This script generates the system-wide ALSA configuration file (/etc/asound.conf)
# Based on the presence and connection status of paired bluetooth devices
#
# 1. Use bluetoothctl to list paired devices
# 2. Check if a paired device is classified as "audio"
# 3. If at least one audio device is connected, set BlueALSA as the default
# 4. Otherwise, fallback to the physical audio card (card 1,device 0)
#
# Ensure this script is executable and run as root
#

ASOUND_CONF="/etc/asound.conf"

# Check for connected bluetooth audio devices using bluetoothctl
find_bluetooth_audio_devices() {
	local paired list device info
	# Get list of paired devices and their MAC addresess
	paired=$(bluetoothctl devices | awk '/Device/ {print $2}')

	for device in $paired;do
		# Get detailed info about the device
		info=$(bluetoothctl info "$device")

		# Check if device is audio-related
		if echo "$info" | grep -qi "UUID: Audio Sink";then
			# Check if it is connected
			if echo "$info" | grep -qi "Connected: yes";then
				echo "Bluetooth audio device connected: $device"
				return 0
			else
				echo "Device $device is not connected. Attempting to connect..."
				# Attempt to connect by issuing the connect command
				bluetoothctl connect "$device" > /dev/null 2>&1 || true
				sleep 5 # Allow a moment for the connection to establish. adjust based on your preference
				# Recheck the connection status
				info=$(bluetoothctl info "$device")
				if echo "$info" | grep -qi "Connected: yes";then
					echo "Successfully connected to device $device"
					return 0
				else
					echo "Failed to connect to device $device"
				fi
			fi
		fi
	done

	return 1 
}

# If any audio bluetooth device status is connected, create BlueALSA base config file for ALSA
if find_bluetooth_audio_devices;then
	echo "Audio device detected. Configuring ALSA to use BlueALSA"
	cat <<EOF > "$ASOUND_CONF"

defaults.bluealsa{
	interface "hci0"
	profile "a2dp"
}

pcm.!default {
	type plug
	slave.pcm "bluealsa"
}

EOF
# If there isn't any available audio bluetooth device, use physical card ALSA config file
else
	echo "No connected bluetooth audio devices detected. Configuring ASLA to use physical audio card"
	cat <<EOF > "$ASOUND_CONF"

pcm.!default{
	type plug
	# Edjust based on your system. here physical card is card1 and device0
	# to find your physical card, issue 'aplay -l'
	slave.pcm "hw:1,0"
} 
EOF
fi

echo "ASLA configuration updated at $ASOUND_CONF"
