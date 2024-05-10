#!/bin/sh

DIR=$(dirname "$0")
cd "$DIR"
if $IS_PLUS; then
	mkdir -p "$USERDATA_PATH/.wifi"

	./bin/show change.png
	if [ -f "$USERDATA_PATH/.wifi/ftp_on.txt" ]; then
		./bin/say "FTP: Enabled"
	else
		./bin/say "FTP: Disabled"
	fi
	
	while ./bin/confirm; do
		./bin/show change.png
		if [ -f "$USERDATA_PATH/.wifi/ftp_on.txt" ]; then
			rm -f "$USERDATA_PATH/.wifi/ftp_on.txt"
			LD_PRELOAD= killall ftpd > /dev/null 2>&1
			LD_PRELOAD= killall tcpsvd > /dev/null 2>&1
			./bin/say "FTP: Disabled"
		else
			touch "$USERDATA_PATH/.wifi/ftp_on.txt"
			if [ -f "$USERDATA_PATH/.wifi/wifi_on.txt" ]; then
				LD_PRELOAD= tcpsvd -E 0.0.0.0 21 ftpd -w /mnt/SDCARD > /dev/null 2>&1 &
				./bin/say "FTP: Enabled"
			fi
		fi
	done
else
	./bin/show confirm.png
	./bin/say "Only supported on Miyoo Mini Plus"$'\n'$'\n'"Press any button to exit"
	./bin/confirm any
	exit 0
fi