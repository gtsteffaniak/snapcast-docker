#!/bin/bash
usage()
{
    echo "usage: ./bootstrap.sh
   flags:
   	-n [name of client speaker]
   optional:
   	-d [bluetooth mac]
	-r (specifies to remove/recreate existing container)
	-i (specifies instance/ip... fix ip conflicts)
	-h snapserver ip/hostame manual assignment
	-v version of docker image (leave blank for latest)
	-t enable second stream (for secondary stream - Default:single)
	-m disable stereo ( enable for mono bt speaker)
"
    echo -e "examples:
\t# create single client local speaker device (ie: headphone jack speaker)
\t./bootstrap.sh -n my-speaker
\t# create bluetooth speaker (will begin pairing process)
\t./bootstrap.sh -n my-wireless-speaker -d 14:C1:4E:B3:D0:D9
"
}
while getopts ':n:d:i:v:h:m' opt ; do
  case "${opt}" in 
	n) name=$OPTARG ;; 
	d) device=$OPTARG ;;
	i) sip=$OPTARG ;;
	v) version=$OPTARG ;;
	h) server=$OPTARG ;;
	m) USE_STEREO=false ;;
  esac 
done 
shift $(( OPTIND - 1 ))
echo "[INFO] name      : $name"
echo "       device    : $device"
echo "       IP        : $sip"
echo "       version   : $version"
echo "       server    : $server"
echo "       stereo    : $USE_STEREO"
verify=true
dpkg -s jq &> /dev/null
if [ $? -ne 0 ]; then
	echo "[WARN] JQ not installed, cannot verify server details"
	echo "[WARN] Please install jq (eg: sudo apt install jq)"
	sleep 5
	verify=false
fi

if [ -z "$name"  ];then
	usage
	echo "-- Please enter information (leave blank to skip) --"
	sleep 1
	echo "What Should this speaker be called? (no spaces)"
	sleep 1
	echo -n "(required) Speaker name            : "
	read name
	echo "Do you know the server info?"
	sleep 1
	echo -n "(optional) Snapserver hostname/ip  : "
	read server
	echo "If you are connecting bluetooth speaker, please specify its MAC"
	echo "review documentation for help finding this"
	sleep 1
	echo -n "(optional) Bluetooth MAC           : "
	read device
fi
declare -A cn
declare -A ci
if [ "$verify" == true ];then
	echo "===    Snapserver details     ==="
	if [ -z "$server" ];then
		default_subnet=$(ip route show | grep -i 'default via'| awk '{print $3 }'|awk -F '.' '{print $1 "." $2 "." $3 }')
		echo "Scanning for snapserver... could take up to 5 minutes!"
		echo "Note: specify a host with -h <ip or hostname> to avoid this."
		for i in {2..255};do
			echo -ne " [ scan progress: $(( $i / 2 ))% ]\r"
			nc -vz $default_subnet.$i -w 1 1704 &>/dev/null	
			if [ $? -eq 0 ]; then
				echo " [ scan progress: complete ]"
				server="$default_subnet.$i"
				echo "[OK] Found server: $server"
				break
			fi
		done
		if [ -z "$server" ];then
			echo " [ scan progress: complete ]"
			echo "[WARN] No server found..."
			echo "[WARN] Make sure you have a working snapserver running!"
			sleep 5
		fi
	else
		# make sure you didn't fuck up
		echo "Verifying $server is listening..."
		nc -vz $server -w 1 1704 &>/dev/null
		if [ $? -eq 0 ]; then
			echo "[OK] Server is listening!"
		else
			echo "[WARN] Server does not appear to be online..."
			sleep 5
		fi
	fi
	details=$(curl -s -X POST -H 'Content-Type: application/json' -d '{"id": 1,"jsonrpc":"2.0","method":"Server.GetStatus"}' "http://"$server":1780/jsonrpc")
	clientlist=$(echo $details|jq '.result.server.groups[] .clients[]')
	count=0
	echo "Devices connected to server:"
	output+="| <Name> <Instance> |\n"
	for n in $(echo $clientlist|jq '.host.name');do
		cn[$count]=$n
		count+=1
	done
	count=0
	for instance in $(echo $clientlist|jq '.config.instance');do
		output+="| ${cn[$count]} $instance |\n"
		ci[$count]=$instance
		count+=1
	done

	echo "---------------------------------"
		echo -e "$output"|column -t -s ' '
	echo "---------------------------------"
fi 

echo "===    Starting bootstrap     ==="
netip="172.24.0"
# create network
mynet="bluetooth-snapclient-network"
docker network inspect $mynet &> /dev/null
if [ $? -eq 0 ]; then
	echo "[OK] docker network exists..."
else
	echo adding network for device...
	docker network create --subnet="$netip.0/16" $mynet
	if [ $? -eq 0 ]; then
		echo "[OK] network created... done!"
	else
		echo "[FATAL] could not create docker network... is docker running? conflicting network?"
		echo "exiting..."
		exit
	fi
fi
if [ -z "$sip" ];then

	# verify ip is open
	assignedIP=""
	for ip in "$netip".{2..50} ; do
		temp_instance=$(echo "$ip"|cut -c 10-12)
		case "${ci[@]}" in  *"$temp_instance"*) echo "skipping: $temp_instance";continue ;; esac
		echo trying $ip
		ping -w 1 -c 1 $ip &>/dev/null
		if [ $? -ne 0 ]; then
			echo "[OK] Assigned : $ip "
			sip=$temp_instance
			assignedIP=$ip
			break
		else
			echo "[WARN] $ip exists without matching instance... skipping"
		fi
	done
	if [ -z $assignedIP ] ; then
		echo "[FATAL] no available ip on $netip.0 subnet"
		exit
	fi
else
	case "${ci[@]}" in  *"$sip"*) echo "[FATAL] instance already exists: $sip";exit ;; esac
	assignedIP="$netip.$sip"
	echo "[OK] Assigned : $assignedIP "

fi


if [ -z "$version" ];then
	version="latest"
fi

echo "=== Starting docker container ==="

## Needs a privileged container if you want more than one bluetooth device connected.
startcontainer(){
	echo "starting new container $name..."
	docker run -d --restart on-failure:3 \
	--hostname "$name" \
	--net "$mynet" \
	--ip "$assignedIP" \
	-v /var/run/dbus:/var/run/dbus \
	--device /dev/snd \
	--privileged \
	-e DEVICE="$device" \
	-e instance="$sip" \
	-e server="$server" \
	-e USE_STEREO=$USE_STEREO \
	--name "$name" \
	gtstef/snapclient:$version
	if [ $? == 0 ];then
		echo "[SUCCESS] Container $name is starting."
	else
		echo "[FATAL] Container failed to start... check logs using <docker logs $name>"
	fi
}
# check if container already exists
docker ps -a | grep -q $name &> /dev/null
if [ $? -eq 0 ]; then
	echo "[WARN] This container already exists."
	echo "       Overwriting existing container."
	docker stop $name
	docker rm $name
	startcontainer
else
	echo "[OK] Starting Speaker : $name"
	startcontainer
	echo "[OK] done!"
fi
