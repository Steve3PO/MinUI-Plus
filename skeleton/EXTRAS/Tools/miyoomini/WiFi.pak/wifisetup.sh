#!/bin/sh

USERDATA_PATH="$(dirname "$0")"
cd "$USERDATA_PATH"
{
mkdir -p "$USERDATA_PATH/.wifi"

WIFI_SSID="$(keyboard.elf "Enter WiFi network name:" 32)"

if [ $? -eq 0 ] && [ ! -z "$WIFI_SSID" ]; then
	./bin/say "WiFi network name set:"$'\n'"${WIFI_SSID:0:16}"$'\n'"${WIFI_SSID:17}"
	if ./bin/confirm; then
		WIFI_PASS="$(keyboard.elf "Enter WiFi network pass:" 63)"
		if [ $? -eq 0 ]; then
			if [ ! -z "$WIFI_PASS" ]; then
				./bin/say "WiFi network password set:"$'\n'"${WIFI_PASS:0:16}"$'\n'"${WIFI_PASS:17:16}"$'\n'"${WIFI_PASS:33:16}"$'\n'"${WIFI_PASS:48}"
			else
				./bin/say "WiFi network password set to empty"
			fi
			if ./bin/confirm; then
				echo "ctrl_interface=/var/run/wpa_supplicant" > /appconfigs/wpa_supplicant.conf
				echo "update_config=1" >> /appconfigs/wpa_supplicant.conf
				echo $'\n'"network={" >> /appconfigs/wpa_supplicant.conf
				echo $'\tssid="'"$WIFI_SSID"$'"' >> /appconfigs/wpa_supplicant.conf
				if [ ! -z "$WIFI_PASS" ]; then
					echo $'\tpsk="'"$WIFI_PASS"$'"' >> /appconfigs/wpa_supplicant.conf
				else
					echo $'\t'"key_mgmt=NONE" >> /appconfigs/wpa_supplicant.conf
				fi
				echo "}" >> /appconfigs/wpa_supplicant.conf
				if [ ! -f /appconfigs/wpa_supplicant.conf ]; then
					if [ -f "$USERDATA_PATH/.wifi/wifi_on.txt" ]; then
						LD_PRELOAD= ./wifioff.sh > /dev/null 2>&1 &
					fi
					./bin/say "Error:"$'\n'"Could not save WiFi network settings!"
				else
					if [ -f "$USERDATA_PATH/.wifi/wifi_on.txt" ]; then
						LD_PRELOAD= ./wifireload.sh > /dev/null 2>&1 &
					fi
					./bin/say "WiFi network settings saved."
				fi
				./bin/confirm only
				exit 0
			fi
		fi
	fi
fi

./bin/say "WiFi network settings"$'\n'"were not changed."
./bin/confirm only
} &> ./wifi_setup_log.txt