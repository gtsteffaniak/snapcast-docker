# Snapcast Server

This contains information related to running snapcast snapserver. For more
information related to running each client instance, view the 
[snapcast client](../snapclient/README.md) section.

### Snapcast Server
* Can be started two ways:
   * docker run
   * docker-compose.yml
* Cleanup job to remove old clients. (see docker-compose.yml)
* MPD server (for external audio sources. eg: tts, music, notifications)
* librespot (for spotify integration, provided by default)
   * spotify app on same network should see a "Snapcast" device to play to
* snapweb controller - for volume control and speaker grouping.

### How To Use

