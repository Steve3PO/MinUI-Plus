#!/bin/sh

DIR="$(dirname "$0")"
cd "$DIR"
{
mkdir -p "$USERDATA_PATH/.wifi"

if [ ! -f /mnt/SDCARD/.system/miyoomini/paks/WiFi.pak/8188fu.ko ]; then

	./bin/say "WiFi driver is missing!"$'\n'"Please reinstall DotUI."
	./bin/confirm any
	exit 0
fi

WIFI_ON=0
if [ -e "$USERDATA_PATH/.wifi/wifi_on.txt" ]; then
	if [ -f /appconfigs/wpa_supplicant.conf ]; then
		WIFI_ON=1
	else
		LD_PRELOAD= ./wifioff.sh > /dev/null 2>&1 &
	fi
fi

_WIFI_ON=$WIFI_ON
while :; do
	if [ ! -f /appconfigs/wpa_supplicant.conf ]; then
		show.elf ./wifi2.png
		./bin/say "WiFi: Not configured"$'\n'$'\n'"Please configure your WiFi network"$'\n'"by pressing SELECT."
	else
		if [ $WIFI_ON -eq 1 ]; then
			echo "WiFi: Enabled"
			serverAdr="8.8.8.8"
			ping -c 1 $serverAdr > /dev/null 2>&1
					
			if [ $? -ne 0 ]; then
				show.elf confirm.png
				./bin/say "WiFi Enabled"$'\n'$'\n'"Connecting..."
				./bin/confirm any 
				exit 0
			else
				show.elf ./wifi.png
				echo "$(date): Connected - ${serverAdr}";
				IP=$(ip route get 255.255.255.255 | awk '{print $NF;exit}')
				./bin/say "Local IP: '$IP'"$'\n'$'\n'"Press A to disable"$'\n'"Or B to exit"
			fi
		else
			show.elf ./wifi.png
			./bin/say "WiFi: Disabled"$'\n'$'\n'"Press A to enable"$'\n'"Or B to exit"
		fi
	fi
	while :; do
	
    	KeyPressed=$(./bin/getkey)
    	sleep 0.15  # Little debounce
    	echo "====== Key pressed : $KeyPressed"
		
		if [ "$KeyPressed" = "A" ]; then
			if [ -f /appconfigs/wpa_supplicant.conf ]; then
				WIFI_ON=$(( ! WIFI_ON ))
				./bin/blank
				if [ $WIFI_ON -eq 1 ] && [ $_WIFI_ON -eq 0 ]; then
					_WIFI_ON=1
					LD_PRELOAD= ./wifion.sh > /dev/null 2>&1 &
				elif [ $WIFI_ON -eq 0 ] && [ $_WIFI_ON -eq 1 ] && [ -e "$USERDATA_PATH/.wifi/wifi_on.txt" ]; then
					./bin/say "Disabling WiFi.."
					echo "disabling wifi.."
					LD_PRELOAD= ./wifioff.sh > /dev/null 2>&1 &
					echo "wifi should be off"
					while [ ! -z "$IP" ]
					do
						IP=$(ip route get 255.255.255.255 | awk '{print $NF;exit}')
					done
					sleep 1
				fi
				break
			fi
		elif [ "$KeyPressed" = "select" ]; then
			./wifisetup.sh
			break
		elif [ "$KeyPressed" = "B" ] || [ "$KeyPressed" = "menu" ]; then
			echo " Exiting..."
			exit 0
		fi
	done
done
} &> ./launch_log.txt