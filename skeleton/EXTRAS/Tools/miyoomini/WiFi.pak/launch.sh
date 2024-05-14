#!/bin/sh

DIR="$(dirname "$0")"
cd "$DIR"
{
if $IS_PLUS; then
#export sysdir="/mnt/SDCARD/.tmp_update"
#export miyoodir="/mnt/SDCARD/.system/miyoomini"
#export LD_LIBRARY_PATH="$DIR/lib:/lib:/config/lib:$miyoodir/lib"
./bin/st -q -e $DIR/script/launchenv.sh
else
	./bin/say "Only supported on Miyoo Mini Plus"$'\n'$'\n'"Press any button to exit"
	./bin/confirm any
	exit 0
fi
} &> ./launch_log.txt
