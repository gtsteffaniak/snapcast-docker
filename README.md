# Snapcast docker info

Multi-Room audio bundled into docker with a few extras to make it work a little better. Includes spotify librespot by default.

## Included resources

 * [Snapcast Server](snapserver/README.md)
   * Cleanup job to remove old clients. (see docker-compose.yml)
   * MPD server (for external audio sources. eg: tts, music, notifications)
   * librespot (for spotify integration, provided by default)
     * spotify app on same network should see a "Snapcast" device to play to
   * snapweb controller - for volume control and speaker grouping.

 * [Snapcast Client](snapclient/README.md)
   * multiple arch files
     * arm64 / arm32 / amd64
     * or build your own
   * bluetooth support
     * Requires compatible hardware
     * Requires host to be running working bluez firmware (see more on this below)
   * pulseaudio 15.99.1 (using latest gtstef/snapclient)
   * bluez 5.64    (using latest gtstef/snapclient)

## About

 * [Required] Snapserver runs the server
 * Snapclient sets up audio node that can output audio to linux device connected to a wired audio output OR bluetooth speaker.
 * Using bluetooth speaker is a single command that includes a docker container which automatically pairs to the bluetooth device and sets up the client and config.

## How to use

You can either start the snapcast server separately from clients - useful for
multi device configurations. Or to use server and client on same device, you can
run the all-in-one docker-compose.yml file to start server and client devices
running on the same device.

Note: You may need to terminate pulseaudio daemon on the host in order to use the container. This can be done via `pulseaudio -k`

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

## Roadmap
 * Remove snapbase and build client for simpler images
 * slimmer alpine snapclient image (WIP)
 * Using latest pulseaudio or pipewire
 * Add more streams than just spotify/tts/notifications
 * Ability to add streams via env variable to server
