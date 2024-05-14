#!/bin/sh

DIR="$(dirname "$0")"
cd "$DIR"
cd ..
DIR="$(pwd)"
{
export sysdir="/mnt/SDCARD/.tmp_update"
export miyoodir="/mnt/SDCARD/.system/miyoomini"
export LD_LIBRARY_PATH="$DIR/lib:/lib:/config/lib"
export ZDOTDIR=share/zsh
export TERM=vt102
export TERMINFO=share/terminfo/
$DIR/bin/zsh $DIR/script/wifitools.sh
} &> ./launch_env_log.txt