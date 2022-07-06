# snapcast-docker info

Multi-Room audio bundled into docker with a few extras to make it work a little better. Includes spotify librespot by default.

## Included resources

 * Snapcast Server
   * (optional) docker-compose
   * Cleanup job (remove old clients)
   * MPD service
   * librespot
   * snapweb controller
 * Snapcast Client
   * initiated via bootstrap.sh or docker-compose
   * multiple arch files (armv7l , arm64 , amd64)
   * bluetooth support

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

Note: you can either use the pre-built images I provide at `gtstef/<image>` or use `build` in the docker-compose file.

```
graham@gworker:~/git/snapcast-docker $ docker-compose up -d
snapcast_server_main is up-to-date
Recreating snapcast_client_kitchen-bt ...
Recreating snapcast_client_kitchen-bt ... done
Recreating snapcast_client_tv         ... done
Creating snapcast_client_bedroom-bt   ... done

graham@gworker:~/git/snapcast-docker $ docker ps
CONTAINER ID   IMAGE                             COMMAND                  CREATED              STATUS                             PORTS                                 NAMES
3937de895247   gtstef/snapclient                 "./snaprun.sh"           48 seconds ago       Up 45 seconds (health: starting)                                         snapcast_client_bedroom-bt
94304a1ba59d   gtstef/snapclient                 "./snaprun.sh"           About a minute ago   Up About a minute (healthy)                                              snapcast_client_tv
42cbbfbed78d   gtstef/snapclient                 "./snaprun.sh"           About a minute ago   Up About a minute (healthy)                                              snapcast_client_kitchen-bt
228fb8ed6c79   gtstef/snapserver-cleanup-agent   "./cleanup.sh"           13 minutes ago       Up 12 minutes                                                            snapcast_server_cleanup_agent
b438aa852470   gtstef/snapserver                 "./run.sh"               13 minutes ago       Up 13 minutes (healthy)                                                  snapcast_server_main


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

## Controlling Snapcast

You can control snapcast using the same method of `snapweb` carried over from [snapcast](https://github.com/badaix/snapcast#webapp)
<img width="542" alt="image" src="https://user-images.githubusercontent.com/42989099/177597063-570a60be-8d73-457f-8d87-777e4922771e.png">

## Homeassistant integration

1. This implementation of Snapserver includes an [MPD service](https://www.musicpd.org/) which you can hook into homeassistant.
```
#####################
### MEDIA PLAYERS ###
#####################
media_player:
  # MPD instance for TTS.
  - platform: mpd
    host: <enter hostname of snapserver>
    port: 6600
```
<img width="368" alt="image" src="https://user-images.githubusercontent.com/42989099/177598035-30db4d41-cd25-4ad2-8508-0c2de905173b.png">

Note: voice plays at full volume! so whatever you are sending to the MPD service should probably be at reduced volume.

For example , I use marytts on homeassistant and can specify the volume :

```
#####################
### Speech TTS    ###
#####################
tts:
  - platform: marytts
    host: "<marytts host here>"
    port: 59125
    codec: "WAVE_FILE"
    voice: "dfki-spike-hsmm"
    language: "en_GB"
    effect:
      Volume: "amount:0.4;"    ## reduced volume!
      Rate: "durScale:1.2;"
  - platform: google_translate
```

## Roadmap

There is a lot of tweaking that needs to be done.
