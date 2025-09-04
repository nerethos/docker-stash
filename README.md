# docker-stash

[![Docker pulls](https://img.shields.io/docker/pulls/nerethos/stash-jellyfin-ffmpeg.svg)](https://hub.docker.com/r/nerethos/stash-jellyfin-ffmpeg 'DockerHub')
![Docker Image Size (tag)](https://img.shields.io/docker/image-size/nerethos/stash-jellyfin-ffmpeg/latest)
![Docker Image Version (tag)](https://img.shields.io/docker/v/nerethos/stash-jellyfin-ffmpeg/latest)
![GitHub Repo stars](https://img.shields.io/github/stars/nerethos/docker-stash)

Unofficial Docker image for https://github.com/stashapp/stash, with extras.

# About

This is intended to be a drop-in replacement for the original container image from the Stash maintainers. As such, the container is **not** root-less and uses the same configuration and storage paths.

The regular image replaces ffmpeg with jellyfin-ffmpeg. jellyfin-ffmpeg contains multiple patches and optimisations to enable full hardware transcoding and is more performant than the regular ffmpeg binaries.

There is a *"lite"* image that's based on Alpine Linux for a smaller, more secure container. It has no hardware acceleration support.

Both images include an entrypoint script that parses and installs all required dependencies for your installed plugins/scrapers.

# Tags
The image originally started at `nerethos/stash-jellyfin-ffmpeg` and will continue to be available. For (mostly my own) convenience, the image is now also available from ghcr.io and `nerethos/stash` with the tags below.

| Tag | Example | Features |
| --- | ------- |--------- |
| latest | `nerethos/stash:latest`<br>`ghcr.io/nerethos/stash:latest` | HW acceleration + entrypoint script. Most up-to-date|
| lite   | `nerethos/stash:lite`<br>`ghcr.io/nerethos/stash:lite` | Entrypoint script (Alpine equivalent of latest) |
| v*.*.* | `nerethos/stash:v0.27.2`<br>`ghcr.io/nerethos/stash:v0.27.2` | latest, but pinned to a specific Stash version |
| lite-v*.*.* | `nerethos/stash:lite-v0.27.2`<br>`ghcr.io/nerethos/stash:lite-v0.27.2` | lite, but pinned to a specific Stash version |

There are also git commit SHA tags for both image types.

# Hardware Acceleration Setup

For live transcoding using HW acceleration ensure that it's enabled in the System>Transcoding settings **IT IS NO LONGER NECESSARY TO ADD ANY ARGS FOR LIVE TRANSCODING**. Generation tasks currently don't support hardware acceleration in stash.

## Nvidia

![nvidia decode example](images/nvidia_decode_args.png)

## Intel Transcoding

Intel CPUs with an iGPU can utilise full hardware transcoding (decode and encode) with `-hwaccel auto`

## AMD

AMD is currently not supported by Stash, however jellyfin-ffmpeg has full support.

# How To Install Plugin/Scraper Dependencies Automatically
*Note: Your plugin must have a requirements file for this to work*

1. Install plugins/scrapers through the stash interface or manually
2. Restart the container
3. Dependencies will be parsed and installed for all plugins/scrapers in the stash folder
4. ????
5. Profit.

# docker-compose

You must modify the below compose file to pass your GPU through to the docker container. See this helpful guide from Jellyfin for more info. https://jellyfin.org/docs/general/administration/hardware-acceleration/

```yaml
services:
  stash:
    image: nerethos/stash
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

# License

This Docker project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**Important**: This MIT license applies to the Docker packaging, build scripts, configuration files, and related automation created for this project. The Stash software itself remains licensed under the [GNU Affero General Public License v3.0 (AGPLv3)](https://github.com/stashapp/stash/blob/develop/LICENSE) as maintained by the original developers.

When using these Docker images, you must comply with both:
- The MIT license for the Docker packaging and scripts (this repository)
- The AGPLv3 license for the Stash software (when applicable)

For the complete Stash license terms, please refer to the [upstream Stash repository](https://github.com/stashapp/stash/blob/develop/LICENSE).
