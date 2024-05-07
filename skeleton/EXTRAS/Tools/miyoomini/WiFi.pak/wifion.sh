#!/bin/sh
USERDATA_PATH="$(dirname "$0")"
{
touch "$USERDATA_PATH/.wifi/wifi_on.txt"
echo "wifi_on.txt should be created"
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

# Telnet
if [ -f "$USERDATA_PATH/.wifi/telnet_on.txt" ] && [ -f "$TOOLS_PATH/Telnet.pak/launch.sh" ]; then
	(cd / && telnetd -l sh)
fi

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
} &> ./wifi_on_log.txt