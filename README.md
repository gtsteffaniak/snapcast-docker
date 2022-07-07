# snapcast-docker info

Multi-Room audio bundled into docker with a few extras to make it work a little better. Includes spotify librespot by default.

## Included resources

 * Snapcast Server
   * (optional) docker-compose
   * Cleanup job (remove old clients)
   * MPD server
   * librespot
   * snapweb controller
 * Snapcast Client
   * initiated via bootstrap.sh
   * multiple arch files
   * docker-compose WIP
   * bluetooth support
   * pulseaudio 15 (using latest gtstef/snapclient)
   * bluez 5.60    (using latest gtstef/snapclient)

## About

 * Snapserver runs the server which is required.
 * Snapclient sets up audio node that can output audio to linux device connected to a wired audio output OR bluetooth speaker.
 * Using bluetooth speaker is a single command that includes a docker container which automatically pairs to the bluetooth device and sets up the client and config.


## How to use

You can either use the bootstrap.sh or docker-compose.

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
## Roadmap

 * Pulseaudio 16 (currently included with snapbase, but needs to be added to snapclient dockerfile)
 * Better arm32/armv7l support. Currently, librespot does not work.
 * improved deployment process, likely bash script to name everything properly without manually editing docker-compose
 * More pulseaudio configurations via env variables
 * Add more streams than just spotfy/tts/notifications
 * Ability to add streams via env variable to snapserver
 * Include [latest bluez](https://github.com/bluez/bluez) in snapbase and include in snapclient for more updated bluetooth support. `latest bluez = 5.64`

