#!/bin/sh

USERDATA_PATH="$(dirname "$0")"
{
rm -f "$USERDATA_PATH/.wifi/wifi_on.txt"
echo "wifi_on.txt deleted"
killall ntpd > /dev/null 2>&1 &
killall telnetd > /dev/null 2>&1 &
killall ftpd > /dev/null 2>&1 &
killall tcpsvd > /dev/null 2>&1 &
killall dropbear > /dev/null 2>&1 &
killall wpa_supplicant > /dev/null 2>&1 &
killall udhcpc > /dev/null 2>&1 &
ifconfig wlan0 down
/customer/app/axp_test wifioff
} &> ./wifi_off_log.txt