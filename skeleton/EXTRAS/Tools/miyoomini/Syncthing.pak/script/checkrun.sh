#!/bin/sh

DIR="$(dirname "$0")"
cd "$DIR"
cd ..
DIR="$(pwd)"
{
if ! pgrep "syncthing" > /dev/null; then
	echo "serving.."
    $DIR/bin/syncthing serve --home=$DIR/config/ > $DIR/serve.log 2>&1 &
fi

} &> ./checkrun_log.txt