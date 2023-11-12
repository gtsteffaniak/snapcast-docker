#!/bin/bash
VOLUME="60%"          # intial bell volume
: ${AUDIO_LATENCY:=100}  # default bluetooth latency/buffer ms !important
: ${USE_STEREO:=true} # improves performance on bluetooth when false.
: ${SNAPCAST_SERVER=server} # default host "server" running with docker-compose
ARGS=""
echo "stereo setting: $USE_STEREO"
if [ "$USE_STEREO" == "false" ]; then
	printf "default-sample-channels=1\n" >>/etc/pulse/daemon.conf
fi

function monitor {
	echo "[INFO] monitoring for issues"
	sleep 10
	while true; do
		#check bluetooth device is connected
		getSink
		sleep 1
		if [[ -z "$SINK" ]]; then
			echo "[FATAL] Bluetooth device is no longer connected... exiting container"
			pkill -9 $(pgrep -f snapclient)
			exit
		fi
		# check PID process is not stuck retransmitting (causing high CPU)
		PID=$(pgrep -f snapclient | head -n 1)
		if [ -z "$PID" ]; then
			echo "[WARN] Monitor found snapclient was not running... starting"
			pulseaudio --start
			sleep 1
			start_cmd
			sleep 10
			PID=$(pgrep -f snapclient)
			if [ -z "$PID" ]; then
				echo "[FATAL] Monitor can't get snapclient to start... exiting container"
				exit
			fi
		fi
		cpu_usage=$(ps -p "$PID" -o %cpu | tail -n 1 | awk -F '.' '{print $1}')
		if [[ "$cpu_usage" -gt 80 && "$last_check" -gt 80 ]]; then
			echo "[WARN] CPU usage : $cpu_usage"
			echo "[FATAL] High CPU usage detected.. restarting snapclient"
			pkill -9 $(pgrep -f snapclient)
			exit
		fi
		last_check="$cpu_usage"
		sleep 10
		nc -vz "$SNAPCAST_SERVER" 1704 >/dev/null 2>&1
		serverconnection=$?
		if [[ "$serverconnection" -ne 0 ]]; then
			echo "[WARN] Host $SNAPCAST_SERVER cannot be connected or resolved."
		fi
	done

}
function getSink() {
	if [ -z "$DEVICE" ]; then
		SINK=$(pactl list short sinks | grep -i alsa | head -n 1 | awk '{print $1}')
	else
		SINK=$(pactl list short sinks | grep bluez_sink | head -n 1 | awk '{print $1}')
		CARD=$(pactl list cards short | awk '/bluez/{print $2}')
	fi
	pactl set-sink-volume "$SINK" "$VOLUME"
}

function start_cmd() {
	amixer sset "$defaultDevice" 100%
	getSink
	echo "[INFO] launch command: snapclient $ARGS"
	echo "[INFO] launch volume : $VOLUME"
	echo "[INFO] launch sink: $SINK"
	snapclient $ARGS
}

function noBluetooth() {
	pulseaudio -k
	sleep 1
	pactl load-module module-alsa-sink
	pactl load-module module-alsa-card
	printf "\ndefault-fragments = 10\n" >>/etc/pulse/daemon.conf
	printf "default-fragment-size-msec = 25\n" >>/etc/pulse/daemon.conf
	pulseaudio --start
	VOLUME="125%" # default volume boost
	getSink
	mv -f .asoundrc.aux .asoundrc
	start_cmd
	exit
}

function withBluetooth() {
	pulseaudio --k
	# start with bluetooth device
	# Latency value tries to sync with sound, but may need to be higher or lower
	ARGS="$ARGS --latency=$AUDIO_LATENCY --logsink null"
	#ARGS="$ARGS -s 3"

	printf "\ndefault-fragments = 10\n" >>/etc/pulse/daemon.conf
	printf "default-fragment-size-msec = 25\n" >>/etc/pulse/daemon.conf
	#printf "realtime-scheduling = yes\n" >> /etc/pulse/daemon.conf
	#printf "realtime-priority = 1\n" >> /etc/pulse/daemon.conf
	pulseaudio --start
	sleep 1

	################################################
	# RUN with boosted volume and monitor for issues
	################################################
	eval sudo bluetoothctl remove $DEVICE
	echo "[INFO] Loading required modules..."
	pactl load-module module-bluetooth-policy
	pactl load-module module-bluetooth-discover
	pactl unload-module module-alsa-card
	pactl unload-module module-alsa-sink

	sudo expect -c '
	set timeout 10
	set prompt "#"
	set address '$DEVICE'
	spawn bluetoothctl
	expect -re $prompt
	send "scan on\r"
	send_user "\nWaiting for device.\r"
	expect -re "\\\[NEW\\\] Device $address"
	send_user "\nFound deivce.\r"
	send "connect $address\r"
	expect -re "Confirm passkey" { send "yes\r" }
	send "trust $address\r"
	send "scan off\r"
	send "quit\r"
	expect eof
	'

	sleep 1
	sed -i 's/device ".*/device "'$DEVICE'"/g' .asoundrc

	getSink
	# pactl send-message /card/$CARD/bluez switch-codec '"sbc_xq_552"'
	# force sbc codec... issues occur with other codecs.
	pactl send-message /card/$CARD/bluez switch-codec '"sbc"'
	# for stability
	pactl set-port-latency-offset $CARD headset-output 100000
	aplay long_bel.wav
	VOLUME="125%" # default volume boost
	################################################
	# RUN with normal volume and monitor for issues
	################################################
	start_cmd &
	monitor
	################################################
	################################################

}

function init() {
	# sound ready on default device intro chime
	pulseaudio --start
	sleep 1
	pactl load-module module-alsa-card
	pactl load-module module-alsa-sink
	# set initial volume
	SINK=$(pactl list short sinks | grep -i alsa | head -n 1 | awk '{print $1}')
	defaultDevice=$(amixer scontents | grep Simple | awk -F "\'" '{print $2}' | head -n 1)
	amixer sset "$defaultDevice" "$VOLUME"
	aplay long_bel.wav
	if [ ! -z "$instance" ]; then
		ARGS="$ARGS -i $instance"
		echo "[INFO] assigned instance $instance"
	fi
	if [ ! -z "$SNAPCAST_SERVER" ]; then
		ARGS="$ARGS -h $SNAPCAST_SERVER"
		echo "[INFO] assigned server $SNAPCAST_SERVER"
	fi
}

init
# skip bluetooth if not specified
if [ -z "$DEVICE" ]; then
	noBluetooth
else
	withBluetooth
fi
exit
