#!/bin/sh
# WiFi.pak

USERDATA_PATH="/mnt/SDCARD/Tools/miyoomini/WiFi.pak"
mkdir -p "$USERDATA_PATH/.wifi"

if [ -f /mnt/SDCARD/.system/miyoomini/paks/WiFi.pak/8188fu.ko ] && [ -f "$USERDATA_PATH/.wifi/wifi_on.txt" ] && [ -f /appconfigs/wpa_supplicant.conf ]; then
	if [ ! -f "$USERDATA_PATH/.wifi/telnet_on.txt" ] || [ ! -f "$TOOLS_PATH/Telnet.pak/launch.sh" ]; then
		killall telnetd > /dev/null 2>&1 &
	fi
	if ! cat /proc/modules | grep -c 8188fu; then
		insmod /mnt/SDCARD/.system/paks/WiFi.pak/8188fu.ko
	fi
	ifconfig lo up
	/customer/app/axp_test wifion
	sleep 2
	ifconfig wlan0 up
	/customer/app/wpa_supplicant -B -D nl80211 -iwlan0 -c /appconfigs/wpa_supplicant.conf
	ln -sf /dev/null /tmp/udhcpc.log
	udhcpc -i wlan0 -s /etc/init.d/udhcpc.script > /dev/null 2>&1 &

	# FTP
	if [ -f "$USERDATA_PATH/.wifi/ftp_on.txt" ] && [ -f "$TOOLS_PATH/FTP.pak/launch.sh" ]; then
		tcpsvd -E 0.0.0.0 21 ftpd -w /mnt/SDCARD > /dev/null 2>&1 &
	fi

	# SSH
	if [ -f "$USERDATA_PATH/.wifi/ssh_on.txt" ] && [ -f "$TOOLS_PATH/SSH.pak/dropbear.sh" ]; then
		"$TOOLS_PATH/SSH.pak/dropbear.sh" > /dev/null 2>&1 &
	fi

	# NTP
	if [ -f "$USERDATA_PATH/.wifi/ntp_on.txt" ]; then
		ntpd -p 216.239.35.12 -S "/sbin/hwclock -w -u" > /dev/null 2>&1 &
	fi
else
	killall telnetd > /dev/null 2>&1 &
fi
