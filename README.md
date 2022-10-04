# Snapcast docker info

Multi-Room audio bundled into docker with a few extras to make it work a little better. Includes spotify librespot by default.

## Included resources

 * [Snapcast Server](snapserver/README.md)
   * Can be started two ways:
     * docker run
     * docker-compose.yml
   * Cleanup job to remove old clients. (see docker-compose.yml)
   * MPD server (for external audio sources. eg: tts, music, notifications)
   * librespot (for spotify integration, provided by default)
     * spotify app on same network should see a "Snapcast" device to play to
   * snapweb controller - for volume control and speaker grouping.

 * [Snapcast Client](snapclient/README.md)
   * Can be started two ways:
     * via bootstrap.sh
     * via docker-compose.yml
   * multiple arch files
     * arm64
     * arm32
     * amd64
     * or build your own
   * bluetooth support
     * Requires compatible hardware
     * Requires host to be running working bluez firmware (see more on this below)
   * pulseaudio 15 (using latest gtstef/snapclient)
   * bluez 5.60    (using latest gtstef/snapclient)

## About

 * [Required] Snapserver runs the server
 * Snapclient sets up audio node that can output audio to linux device connected to a wired audio output OR bluetooth speaker.
 * Using bluetooth speaker is a single command that includes a docker container which automatically pairs to the bluetooth device and sets up the client and config.

## How to use

You can either start the snapcast server separately from clients - useful for
multi device configurations. Or to use server and client on same device, you can
run the all-in-one docker-compose.yml file to start server and client devices
running on the same device.

 Using docker-compose:
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
sudo apt install build-essential libglib2.0-dev libdbus-1-dev libudev-dev libical-dev libreadline-dev python3-docutils
wget http://www.kernel.org/pub/linux/bluetooth/bluez-${version}.tar.xz
tar -xvf bluez-${version}.tar.xz
cd bluez-${version}/
./configure --prefix=/usr/local # may be different... find out by doing `which bluetoothctl` on host
make -j4
sudo make install
sudo reboot
```
Then, confirm your version with:
`bluetoothctl --version`

Then, start the docker containers configured to use a bluetooth speaker device. Watch the logs for failures.

## Roadmap

 * Remove snapbase and build client/server with alpine linux (for smaller/simpler images)
 * Pulseaudio 16
 * Better arm32/armv7l support. Currently, requires separate image
 * Improved deployment process, likely bash script to name everything properly without manually editing docker-compose
 * Add more streams than just spotify/tts/notifications
 * Ability to add streams via env variable to server
