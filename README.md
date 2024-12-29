# docker-stash

[![Docker pulls](https://img.shields.io/docker/pulls/nerethos/stash-jellyfin-ffmpeg.svg)](https://hub.docker.com/r/nerethos/stash-jellyfin-ffmpeg 'DockerHub')
![Docker Image Size (tag)](https://img.shields.io/docker/image-size/nerethos/stash-jellyfin-ffmpeg/latest)
![Docker Image Version (tag)](https://img.shields.io/docker/v/nerethos/stash-jellyfin-ffmpeg/latest)
![GitHub Repo stars](https://img.shields.io/github/stars/nerethos/docker-stash)

Unofficial Docker image for https://github.com/stashapp/stash, with extras.

# About

The regular image replaces ffmpeg with jellyfin-ffmpeg and includes a startup script that parses and installs all required dependencies for your installed plugins/scrapers.

jellyfin-ffmpeg contains multiple patches and optimisations to enable full hardware transcoding and is more performant than the current implementation in stash.

There is a "lite" image that's based on Alpine linux based for a smaller, more secure container. It has no hardware acceleration support, but retains the dependency installer script.

# Tags

| Tag | Description |
| --- | ----------- |
| latest | HW acceleration + entrypoint script. Most up-to-date|
| lite   | Entrypoint script (no HW acceleration, Alpine equivalent of latest) |
| v*.*.* | latest, but pinned to a specific Stash version |
| lite-v*.*.* | lite, but pinned to a specific Stash version |

There are also git commit SHA tags for both image types.

# Hardware Acceleration Setup

For live transcoding using HW acceleration ensure that it's enabled in the System>Transcoding settings **IT IS NO LONGER NECESSARY TO ADD ANY ARGS FOR LIVE TRANSCODING**. For general transcoding (generating previews etc.) you need to include the relevant ffmpeg args for your GPU. See the below example args for an Nvidia GPU.

## Nvidia

![nvidia decode example](images/nvidia_decode_args.png)

## Intel Transcoding

Intel CPUs with an iGPU can utilise full hardware transcoding (decode and encode) with `-hwaccel auto`

## AMD

AMD is currently not supported by Stash, however jellyfin-ffmpeg has full support.

# How To Install Plugin/Scraper Dependencies Automatically
*Note: Your plugin must have a requirements file for this to work*

1. Install plugins through the stash interface or manually
2. Restart the container
3. Dependencies will be parsed and installed for all plugins/scrapers in the stash folder
4. ????
5. Profit.

# docker-compose

You must modify the below compose file to pass your GPU through to the docker container. See this helpful guide from Jellyfin for more info. https://jellyfin.org/docs/general/administration/hardware-acceleration/

```yaml
services:
  stash:
    image: nerethos/stash-jellyfin-ffmpeg
    container_name: stash
    restart: unless-stopped
    ## the container's port must be the same with the STASH_PORT in the environment section
    ports:
      - "9999:9999"
    ## If you intend to use stash's DLNA functionality uncomment the below network mode and comment out the above ports section
    # network_mode: host
    logging:
      driver: "json-file"
      options:
        max-file: "10"
        max-size: "2m"
    environment:
      - PUID=1000
      - PGID=1000
      - STASH_STASH=/data/
      - STASH_GENERATED=/generated/
      - STASH_METADATA=/metadata/
      - STASH_CACHE=/cache/
      ## Adjust below to change default port (9999)
      - STASH_PORT=9999
    volumes:
      - /etc/localtime:/etc/localtime:ro
      ## Adjust below paths (the left part) to your liking.
      ## E.g. you can change ./config:/root/.stash to ./stash:/root/.stash
      
      ## Keep configs, scrapers, and plugins here.
      - ./config:/root/.stash
      ## Point this at your collection.
      - ./data:/data
      ## This is where your stash's metadata lives
      - ./metadata:/metadata
      ## Any other cache content.
      - ./cache:/cache
      ## Where to store binary blob data (scene covers, images)
      - ./blobs:/blobs
      ## Where to store generated content (screenshots,previews,transcodes,sprites)
      - ./generated:/generated
```
