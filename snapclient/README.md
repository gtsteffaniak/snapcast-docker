# Snapcast Client

This readme describe the various ways to use snapcast client (snapclient).
This requires a running snapcast server (snapserver). View 
[snapserver](../snapserver/README.md) for more information.

## Snapcast Client
* can be started two ways:
   * via bootstrap.sh
   * via docker-compose.yml
* multiple arch files
   * arm64
   * arm32
   * amd64
   * or build your own
* bluetooth support
   * Requires compatible hardware
   * Requires host to be running working firmware
* pulseaudio 15 (using latest gtstef/snapclient)
* bluez 5.60    (using latest gtstef/snapclient)

* Snapclient sets up audio node that can output audio to linux device connected to a wired audio output OR bluetooth speaker.
* Using bluetooth speaker is a single command that includes a docker container which automatically pairs to the bluetooth device and sets up the client and config.

## How to use

You can either use the bootstrap.sh or docker-compose.

Note: you may need to kill pulseaudio on host for this to work, eg run `pulseaudio -k` on host.

1. Using bootstrap.sh (client init):
   * Firstly, get the server running, either of the following options:
      * (preferred) navigate to `./snapserver` and initiate `docker-compose up -d`
      * or use `docker run` by running `docker run -d --net host -v '/var/run/avahi-daemon/socket:/var/run/avahi-daemon/socket' -name snapserver gtstef/snapserver`
   * Run `./bootstrap.sh`, examples
      * `./bootstrap.sh -n my-wireless-speaker -d 14:C1:4E:B3:D0:D9 -h snapserver-ip-or-hostname `
      * `./bootstrap.sh -n local-audio -h localhost `
```
usage: ./bootstrap.sh
   flags:
        -n [name of client speaker]
   optional:
        -d [bluetooth mac]
        -r (specifies to remove/recreate existing container)
        -i (specifies instance/ip... fix ip conflicts)
        -h snapserver ip/hostame manual assignment
        -v version of docker image (leave blank for latest)
        -m disable stereo ( enable for mono bt speaker)

examples:
        # create single client local speaker device (ie: headphone jack speaker)
        ./bootstrap.sh -n my-speaker
        # create bluetooth speaker (will begin pairing process)
        ./bootstrap.sh -n my-wireless-speaker -d 14:C1:4E:B3:D0:D9
```
 1. Using docker-compose:
   * Update docker-compose host to match your environment
   * run `docker-compose up -d` on main directory

```
Use 'docker scan' to run Snyk tests against images to find vulnerabilities and learn how to fix them
[+] Running 5/6
 ⠿ Network snapcast-docker_default            Created                                                                                                                                                         0.0s
 ⠿ Container snapcast-docker-server-1         Healthy                                                                                                                                                        30.8s
 ⠿ Container snapcast-docker-cleanup_agent-1  Started                                                                                                                                                        30.9s
 ⠿ Container kitchen                          started                                                                                                                                                       114.7s
 ⠿ Container tv                               Started                                                                                                                                                        31.0s
 ⠿ Container bedroom                          Created                                                                                                                                                         0.0s
```

Note: docker compose can be stopped simultaneously with `docker-compose down` or individually with `docker-compose down <name>`

```
~/git/snapcast-docker$ docker-compose down
[+] Running 6/6
 ⠿ Container tv                               Removed                                                                                                                                                        10.2s
 ⠿ Container bedroom                          Removed                                                                                                                                                         0.0s
 ⠿ Container snapcast-docker-cleanup_agent-1  Removed                                                                                                                                                        10.1s
 ⠿ Container kitchen                          Removed                                                                                                                                                         2.1s
 ⠿ Container snapcast-docker-server-1         Removed                                                                                                                                                        10.1s
 ⠿ Network snapcast-docker_default            Removed
```


## bluez performance

Linux bluez firmware is essential for running bluetooth on linux. The differences between bluez versions is substantial. Not only is there big differences in features (such as codec support), theres also general stability and quality of A2DP streaming. Here is a table of my experience:

### Raspberry pi 4 (Debian)
| bluez version   | supported # of streams |  runtime stability | crash frequency |
|-----------------|:--------------------:|-------------------:|----------------:|
| 5.55            |  1 stream | ok | low
| 5.56            |  does not pair                 |                    |                 |
| 5.57            |  does not pair                 |                    |                 |
| 5.58            |  does not pair                 |                    |                 |
| 5.59            |  1 stream | poor | high |
| 5.60            |  1 stream | poor | high |
| 5.61            |  does not pair                  |                    |                 |
| 5.62            |  1 stream                 |              ok      |       high          |
| 5.63            |  fails to start bluez                 |                    |                 |
| 5.64            |  fails to start bluez                 |                    |                 |
| 5.65            |  not yet released    |                    |                 |

### Debian with intel ax210
| bluez version   | support for multiple |  runtime stability | crash frequency |
|-----------------|:--------------------:|-------------------:|----------------:|
| 5.55            |  TBD                 |                    |                 |
| 5.56            |  TBD                 |                    |                 |
| 5.57            |  TBD                 |                    |                 |
| 5.58            |  TBD                 |                    |                 |
| 5.59            |  TBD                 |                    |                 |
| 5.60            |  TBD                 |                    |                 |
| 5.61            |  TBD                 |                    |                 |
| 5.62            |  TBD                 |                    |                 |
| 5.63            |  TBD                 |                    |                 |
| 5.64            |  TBD                 |                    |                 |
| 5.65            |  not yet released    |                    |                 |
### How to test bluez versions

Since each bluez firmware and
Simply compile and install new versions to the host with following:
```
version="5.55"
prefix=$(dirname $(dirname $(which bluetoothctl)))
sudo apt install build-essential libglib2.0-dev libdbus-1-dev libudev-dev libical-dev libreadline-dev python3-docutils
wget http://www.kernel.org/pub/linux/bluetooth/bluez-${version}.tar.xz
tar -xvf bluez-${version}.tar.xz
cd bluez-${version}/
./configure --prefix="$prefix"
make -j4
sudo make install
sudo reboot
```
Then, confirm your version with:
`bluetoothctl --version`

Then, start the docker containers configured to use a bluetooth speaker device. Watch the logs for failures.

