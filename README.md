# docker-stash

[![Docker Hub pulls](https://img.shields.io/docker/pulls/nerethos/stash-jellyfin-ffmpeg.svg?label=Hub%20pulls%20(legacy))](https://hub.docker.com/r/nerethos/stash-jellyfin-ffmpeg 'DockerHub')
[![GHCR](https://img.shields.io/badge/GHCR-ghcr.io%2Fnerethos%2Fstash-blue?logo=github)](https://github.com/nerethos/docker-stash/pkgs/container/stash 'GitHub Container Registry')
![Size](https://img.shields.io/docker/image-size/nerethos/stash/latest)
![Version](https://img.shields.io/docker/v/nerethos/stash/latest)
![Stars](https://img.shields.io/github/stars/nerethos/docker-stash)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Unofficial images for [Stash](https://github.com/stashapp/stash). Same layout as upstream, plus jellyfin-ffmpeg for broader HW accel and a helper to install plugin/scraper Python deps automatically.

Main things you get:
* Hardware acceleration (NVIDIA / Intel / VAAPI where supported)
* Optional small Alpine variant (no HW accel)
* Auto collection of scattered `requirements.txt` files into one install
* Tags pinned to upstream releases or latest

## Table of Contents
- [Quick Start](#quick-start)
- [About](#about)
- [Available Tags](#available-tags)
- [Hardware Acceleration](#hardware-acceleration)
- [Plugin Dependencies](#plugin-dependencies)
- [Docker Compose Examples](#docker-compose-examples)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Quick Start

```bash
docker run -d \
  --name stash \
  -p 9999:9999 \
  -v ./config:/root/.stash \
  -v ./data:/data \
  -v ./metadata:/metadata \
  -v ./cache:/cache \
  -v ./generated:/generated \
  nerethos/stash:latest
```

Then open: http://localhost:9999

Need compose? Skip down to [examples](#docker-compose-examples).

## About

This is intended to be a drop-in replacement for the original container image from the Stash maintainers. As such, the container is **not** root-less and uses the same configuration and storage paths.

The regular image replaces ffmpeg with jellyfin-ffmpeg, which offers some improvements over the regular ffmpeg binaries.

There is a *"lite"* image that's based on Alpine Linux for a smaller, more secure container. It has no hardware acceleration support.

Both images include an entrypoint script that parses and installs all required dependencies for your installed plugins/scrapers.

### Environment Variables

The examples in this README use environment variable syntax for user/group IDs:
- `PUID=${PUID:-1000}` - Set to your user ID (defaults to 1000)
- `PGID=${PGID:-1000}` - Set to your group ID (defaults to 1000)

To find your IDs: `id $(whoami)`

## Available Tags
The image originally started at `nerethos/stash-jellyfin-ffmpeg` and will continue to be available. For (mostly my own) convenience, the image is now also available from ghcr.io and `nerethos/stash` with the tags below.

| Tag | Example | Features |
| --- | ------- |--------- |
| latest | `nerethos/stash:latest`<br>`ghcr.io/nerethos/stash:latest` | HW acceleration + entrypoint script. Most up-to-date|
| lite   | `nerethos/stash:lite`<br>`ghcr.io/nerethos/stash:lite` | Entrypoint script (Alpine equivalent of latest) |
| v*.*.* | `nerethos/stash:v0.27.2`<br>`ghcr.io/nerethos/stash:v0.27.2` | latest, but pinned to a specific Stash version |
| lite-v*.*.* | `nerethos/stash:lite-v0.27.2`<br>`ghcr.io/nerethos/stash:lite-v0.27.2` | lite, but pinned to a specific Stash version |

There are also git commit SHA tags for both image types.

## Hardware Acceleration

Bundled `jellyfin-ffmpeg` adds broader GPU support than stock ffmpeg.

### What to do
1. Map your GPU into the container (see compose snippets below).
2. In Stash: Settings → System → Transcoding → enable HW acceleration.
3. Usually no custom args needed; override only if you know why.

### Platforms
| GPU | Status | Tech | Note |
|-----|--------|------|------|
| NVIDIA | Full | NVENC/NVDEC, CUDA | Encode + decode |
| Intel | Full | QSV, VAAPI | Encode + decode |
| AMD | Partial | VAAPI | Not currently supported by Stash, but supported by jellyfin-ffmpeg |

### Examples
NVIDIA (compose):
```yaml
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: 1
          capabilities: [gpu]
```
Intel / VAAPI:
```yaml
devices:
  - /dev/dri:/dev/dri
```

### Verify
```bash
docker exec stash /usr/lib/jellyfin-ffmpeg/ffmpeg -hwaccels
docker exec stash vainfo   # VAAPI details (if installed on host)
```

More background: Jellyfin’s HW accel docs: https://jellyfin.org/docs/general/administration/hardware-acceleration/

## Plugin Dependencies

On startup the entrypoint scans plugin & scraper folders for every `requirements.txt`, merges them, pins/deduplicates, then installs into a venv.

What you need: just make sure each plugin that needs Python deps ships a `requirements.txt`.

Adding a new plugin? Restart the container so it rescans.

Manual tweaks:
```bash
docker exec -it stash bash
source /pip-install/venv/bin/activate
pip install extra-package
```

## Docker Compose Examples

### Basic Setup

```yaml
services:
  stash:
    image: nerethos/stash:latest
    container_name: stash
    restart: unless-stopped
    ports:
      - "9999:9999"
    environment:
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - STASH_STASH=/data/
      - STASH_GENERATED=/generated/
      - STASH_METADATA=/metadata/
      - STASH_CACHE=/cache/
    volumes:
      - ./config:/root/.stash
      - ./data:/data
      - ./metadata:/metadata
      - ./cache:/cache
      - ./generated:/generated
```

### With NVIDIA GPU

```yaml
services:
  stash:
    image: nerethos/stash:latest
    container_name: stash
    restart: unless-stopped
    ports:
      - "9999:9999"
    environment:
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - STASH_STASH=/data/
      - STASH_GENERATED=/generated/
      - STASH_METADATA=/metadata/
      - STASH_CACHE=/cache/
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=compute,video,utility
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    volumes:
      - ./config:/root/.stash
      - ./data:/data
      - ./metadata:/metadata
      - ./cache:/cache
      - ./generated:/generated
```

### With Intel GPU

```yaml
services:
  stash:
    image: nerethos/stash:latest
    container_name: stash
    restart: unless-stopped
    ports:
      - "9999:9999"
    environment:
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - STASH_STASH=/data/
      - STASH_GENERATED=/generated/
      - STASH_METADATA=/metadata/
      - STASH_CACHE=/cache/
    devices:
      - /dev/dri:/dev/dri
    volumes:
      - ./config:/root/.stash
      - ./data:/data
      - ./metadata:/metadata
      - ./cache:/cache
      - ./generated:/generated
```

### Lightweight (Alpine)

```yaml
services:
  stash:
    image: nerethos/stash:lite
    container_name: stash-lite
    restart: unless-stopped
    ports:
      - "9999:9999"
    environment:
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - STASH_STASH=/data/
      - STASH_GENERATED=/generated/
      - STASH_METADATA=/metadata/
      - STASH_CACHE=/cache/
    volumes:
      - ./config:/root/.stash
      - ./data:/data
      - ./metadata:/metadata
      - ./cache:/cache
      - ./generated:/generated
```

## Troubleshooting

**Permissions**

Ensure host permissions are correct for the mounted volumes.

**GPU not detected**
* NVIDIA: driver + runtime present? (`nvidia-smi` on host)
* Intel/AMD: is `/dev/dri` mapped and readable?

**Deps not installing**
* Confirm at least one `requirements.txt`
* Restart container after adding plugins
* Inspect `docker logs stash`

**Check venv contents**
```bash
docker exec stash ls -1 /pip-install/venv/lib*/python*/site-packages | head
```

Links: [Docs](https://docs.stashapp.cc/) • [Discord](https://discord.gg/2TsNFKt) • [Issues](https://github.com/nerethos/docker-stash/issues)

## Contributing

PRs and small fixes welcome. Open an issue first for bigger changes.

## License

Code in this repo (Dockerfiles, scripts, workflow glue) is MIT – see [LICENSE](LICENSE).

The bundled Stash binary remains AGPLv3 (upstream project). Using the image means both apply: MIT for what’s here, AGPLv3 for Stash itself. Upstream license: https://github.com/stashapp/stash/blob/develop/LICENSE
