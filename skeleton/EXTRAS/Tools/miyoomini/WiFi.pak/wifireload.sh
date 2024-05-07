#!/bin/sh
{
killall telnetd > /dev/null 2>&1 &
killall ftpd > /dev/null 2>&1 &
killall tcpsvd > /dev/null 2>&1 &
killall dropbear > /dev/null 2>&1 &
killall wpa_supplicant > /dev/null 2>&1
killall udhcpc > /dev/null 2>&1
ifconfig wlan0 down

ifconfig lo up
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
} &> ./wifi_reload_log.txt