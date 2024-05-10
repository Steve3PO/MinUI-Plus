#!/bin/sh

DIR=$(dirname "$0")
cd "$DIR"
if $IS_PLUS; then
	mkdir -p "$USERDATA_PATH/.wifi"

	./bin/show change.png
	if [ -f "$USERDATA_PATH/.wifi/telnet_on.txt" ]; then
		./bin/say "Telnet: Enabled"
	else
		./bin/say "Telnet: Disabled"
	fi
	
	while ./bin/confirm; do
		./bin/show change.png
		if [ -f "$USERDATA_PATH/.wifi/telnet_on.txt" ]; then
			rm -f "$USERDATA_PATH/.wifi/telnet_on.txt"
			LD_PRELOAD= killall telnetd > /dev/null 2>&1
			./bin/say "Telnet: Disabled"
		else
			touch "$USERDATA_PATH/.wifi/telnet_on.txt"
			if [ -f "$USERDATA_PATH/.wifi/wifi_on.txt" ]; then
				(cd / && LD_PRELOAD= telnetd -l sh)
				./bin/say "Telnet: Enabled"
			fi
		fi
	done
else
	./bin/show confirm.png
	./bin/say "Only supported on Miyoo Mini Plus"$'\n'$'\n'"Press any button to exit"
	./bin/confirm any
	exit 0
fi
