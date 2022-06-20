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

## About

 * Snapserver runs the server which is required.
 * Snapclient sets up audio node that can output audio to linux device connected to a wired audio output OR bluetooth speaker.
 * Using bluetooth speaker is a single command that includes a docker container which automatically pairs to the bluetooth device and sets up the client and config.


## How to use

Start by running bootstrap.sh:

`./bootstrap.sh`

```
[INFO] name      :
       device    :
       IP        :
       version   :
       server    : 
       stereo    :
usage: ./bootstrap.sh
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

examples:
        # create single client local speaker device (ie: headphone jack speaker)
        ./bootstrap.sh -n my-speaker
        # create bluetooth speaker (will begin pairing process)
        ./bootstrap.sh -n my-wireless-speaker -d 14:C1:4E:B3:D0:D9
```

## Roadmap

There is a lot of tweaking that needs to be done.
