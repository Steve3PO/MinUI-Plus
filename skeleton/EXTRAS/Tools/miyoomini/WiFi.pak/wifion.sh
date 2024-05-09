#!/bin/sh

DIR="$(dirname "$0")"
cd "$DIR"
{
touch "$USERDATA_PATH/.wifi/wifi_on.txt"
if ! cat /proc/modules | grep -c 8188fu; then
	insmod /mnt/SDCARD/.system/miyoomini/paks/WiFi.pak/8188fu.ko
fi
ifconfig lo up
/customer/app/axp_test wifion
sleep 2
ifconfig wlan0 up
/customer/app/wpa_supplicant -B -D nl80211 -iwlan0 -c /appconfigs/wpa_supplicant.conf
ln -sf /dev/null /tmp/udhcpc.log
udhcpc -i wlan0 -s /etc/init.d/udhcpc.script > /dev/null 2>&1 &

# NTP
if [ -f "$USERDATA_PATH/.wifi/ntp_on.txt" ]; then
	echo "ntp file exists"
	touch "$USERDATA_PATH/.wifi/ntp_on.txt"
	if [ -f "$USERDATA_PATH/.wifi/wifi_on.txt" ]; then
		echo "syncing clock"
		ntpd -p 216.239.35.0 -S "/sbin/hwclock -w -u" > /dev/null 2>&1 &
		echo "ntpd executed"
	fi
fi

} &> ./wifi_on_log.txt