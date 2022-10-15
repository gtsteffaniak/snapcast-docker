#!/bin/bash

if [ -n "$buffer" ]; then
	if [[ "$buffer" -gt 0 ]]; then
		sed -i 's/^buffer =.*/buffer = '$buffer'/g' snapserver.conf
	else
		echo "invalid buffer setting: $buffer"
	fi
fi
if [ -n "$chunk_ms" ]; then
	if [[ "$chunk_ms" -gt 0 ]]; then
		sed -i 's/^chunk_ms =.*/chunk_ms = '$chunk_ms'/g' snapserver.conf
	else
		echo "invalid chunk setting: $chunk_ms"
	fi
fi
if [ -n "$codec" ]; then
	pattern="^flac$|^ogg$|^opus$|^pcm$"
	if [[ $codec =~ $pattern ]]; then
		sed -i 's/^codec =.*/codec = '$codec'/g' snapserver.conf
	else
		echo "unknown codec: $codec"
	fi
fi

mv -f snapserver.conf /etc/

echo "Running with config:"
cat /etc/snapserver.conf | egrep -o "buffer =.*|chunk_ms =.*|codec =.*"

mv mpd.conf /etc/mpd.conf
setcap -r /usr/bin/mpd
mpd --no-daemon --stdout --verbose &
snapserver
