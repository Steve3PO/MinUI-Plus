#!/bin/sh
# MiniUI.pak

if [ -z "$LCD_INIT" ]; then
	# an update may have already initilized the LCD
	/mnt/SDCARD/.system/miyoomini/bin/blank.elf

	# init backlight
	echo 0 > /sys/class/pwm/pwmchip0/export
	echo 800 > /sys/class/pwm/pwmchip0/pwm0/period
	echo 6 > /sys/class/pwm/pwmchip0/pwm0/duty_cycle
	echo 1 > /sys/class/pwm/pwmchip0/pwm0/enable

	# init lcd
	cat /proc/ls
	sleep 0.5
fi

# init charger detection
if [ ! -f /sys/devices/gpiochip0/gpio/gpio59/direction ]; then
	echo 59 > /sys/class/gpio/export
	echo in > /sys/devices/gpiochip0/gpio/gpio59/direction
fi


#######################################

if [ -f /customer/app/axp_test ]; then
	IS_PLUS=true
else
	IS_PLUS=false
fi
export IS_PLUS
export PLATFORM="miyoomini"
export SDCARD_PATH="/mnt/SDCARD"
export BIOS_PATH="$SDCARD_PATH/Bios"
export SAVES_PATH="$SDCARD_PATH/Saves"
export SYSTEM_PATH="$SDCARD_PATH/.system/$PLATFORM"
export CORES_PATH="$SYSTEM_PATH/cores"
export USERDATA_PATH="$SDCARD_PATH/.userdata/$PLATFORM"
export SHARED_USERDATA_PATH="$SDCARD_PATH/.userdata/shared"
export LOGS_PATH="$USERDATA_PATH/logs"
export DATETIME_PATH="$SHARED_USERDATA_PATH/datetime.txt" # used by bin/shutdown
export TIMEZONE_PATH="$SHARED_USERDATA_PATH/tz.txt"
export TOOLS_PATH="$SDCARD_PATH/Tools/miyoomini"

mkdir -p "$USERDATA_PATH"
mkdir -p "$LOGS_PATH"
mkdir -p "$SHARED_USERDATA_PATH/.minui"

#######################################

export CPU_SPEED_MENU=504000
export CPU_SPEED_GAME=1296000
export CPU_SPEED_PERF=1488000
echo userspace > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
overclock.elf $CPU_SPEED_PERF

MIYOO_VERSION=`/etc/fw_printenv miyoo_version`
export MIYOO_VERSION=${MIYOO_VERSION#miyoo_version=}

#######################################

# killall tee # NOTE: killing tee is somehow responsible for audioserver crashes
rm -f "$SDCARD_PATH/update.log"

#######################################

export LD_LIBRARY_PATH=$SYSTEM_PATH/lib:$LD_LIBRARY_PATH
export PATH=$SYSTEM_PATH/bin:$PATH

#######################################

lumon.elf & # adjust lcd luma and saturation

if $IS_PLUS; then
	CHARGING=`/customer/app/axp_test | awk -F'[,: {}]+' '{print $7}'`
	if [ "$CHARGING" == "3" ]; then
		batmon.elf # &> /mnt/SDCARD/batmon.txt
	fi
else
	CHARGING=`cat /sys/devices/gpiochip0/gpio/gpio59/value`
	if [ "$CHARGING" == "1" ]; then
		batmon.elf # &> /mnt/SDCARD/batmon.txt
	fi
fi

keymon.elf & # &> /mnt/SDCARD/keymon.txt &

#######################################

# init datetime
if [ -f "$DATETIME_PATH" ]; then
	DATETIME=$(cat "$DATETIME_PATH")
	if [ -n "$DATETIME" ] && [ "$DATETIME" -eq "$DATETIME" ]; then
		if [ ! -f "$USERDATA_PATH/.wifi/ntp_on.txt" ]; then
			DATETIME=$((DATETIME + 6 * 60 * 60))
		fi
		date -u +%s -s "@$DATETIME"
	fi
fi

# Timezone
if [ -f "$USERDATA_PATH/.wifi/tz.txt" ]; then
	tzoffset=$(head -n 1 $USERDATA_PATH/.wifi/tz.txt)
	if [ -z "$tzoffset" ]; then
		tzoffset="-0"
	fi
	export TZ="UTC$tzoffset" #dont care about abrv just need offset
fi
#######################################

# wifi
if $IS_PLUS; then
	if [ -f $SYSTEM_PATH/paks/WiFi.pak/boot.sh ]; then
		LD_PRELOAD= $SYSTEM_PATH/paks/WiFi.pak/boot.sh > /dev/null 2>&1 &
	else
		rm -rf "$USERDATA_PATH/.wifi/wifi_on.txt"
		killall telnetd > /dev/null 2>&1 &
	fi
fi

#######################################

# Auto launch
if $IS_PLUS; then
	if [ -f $TOOLS_PATH/Syncthing.pak/launch.sh ]; then
		sh $TOOLS_PATH/Syncthing.pak/script/checkrun.sh #SYNCTHING INJECTOR #SYNCTHING INJECTOR
	fi
fi
#######################################

AUTO_PATH=$USERDATA_PATH/auto.sh
if [ -f "$AUTO_PATH" ]; then
	"$AUTO_PATH"
fi

cd $(dirname "$0")

#######################################

EXEC_PATH=/tmp/minui_exec
NEXT_PATH="/tmp/next"
touch "$EXEC_PATH"  && sync
while [ -f "$EXEC_PATH" ]; do
	overclock.elf $CPU_SPEED_PERF
	minui.elf &> $LOGS_PATH/minui.txt
	
	date -u +%s > "$DATETIME_PATH"
	sync
	
	if [ -f $NEXT_PATH ]; then
		CMD=`cat $NEXT_PATH`
		eval $CMD
		rm -f $NEXT_PATH
		if [ -f "/tmp/using-swap" ]; then
			swapoff $USERDATA_PATH/swapfile
			rm -f "/tmp/using-swap"
		fi
		
		date -u +%s > "$DATETIME_PATH"
		overclock.elf $CPU_SPEED_PERF
		sync
	fi
done

poweroff # just in case
