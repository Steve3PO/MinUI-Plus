#!/bin/sh

DIR="$(dirname "$0")"
cd "$DIR"
cd ..
DIR="$(pwd)"
{
#export sysdir="/mnt/SDCARD/.tmp_update"
#export miyoodir="/mnt/SDCARD/.system/miyoomini"
#export LD_LIBRARY_PATH="$DIR/lib:/lib:/config/lib"

if ! pgrep "syncthing" > /dev/null; then
	echo "serving.."
    $DIR/bin/syncthing serve --home=$DIR/config/ > $DIR/serve.log 2>&1 &
fi
echo "test"
} &> ./checkrun_log.txt