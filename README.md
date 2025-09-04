# docker-stash

[![Docker Hub pulls](https://img.shields.io/docker/pulls/nerethos/stash-jellyfin-ffmpeg.svg?label=Docker%20Hub%20pulls%20(legacy))](https://hub.docker.com/r/nerethos/stash-jellyfin-ffmpeg 'DockerHub')
[![GHCR](https://img.shields.io/badge/GHCR-ghcr.io%2Fnerethos%2Fstash-blue?logo=github)](https://github.com/nerethos/docker-stash/pkgs/container/stash 'GitHub Container Registry')
![Docker Image Size (tag)](https://img.shields.io/docker/image-size/nerethos/stash/latest)
![Docker Image Version (tag)](https://img.shields.io/docker/v/nerethos/stash/latest)
![GitHub Repo stars](https://img.shields.io/github/stars/nerethos/docker-stash)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Enhanced Docker images for [Stash](https://github.com/stashapp/stash) with hardware acceleration support and automatic plugin dependency management.

🚀 **Key Features:**
- **Hardware Acceleration**: GPU transcoding support via jellyfin-ffmpeg
- **Auto Dependencies**: Automatic plugin/scraper dependency installation
- **Multiple Variants**: Full-featured and lightweight Alpine versions
- **Drop-in Replacement**: Compatible with official Stash containers

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
# Basic setup with docker run
docker run -d \
  --name stash \
  -p 9999:9999 \
  -v ./config:/root/.stash \
  -v ./data:/data \
  -v ./metadata:/metadata \
  -v ./cache:/cache \
  -v ./generated:/generated \
  nerethos/stash:latest

# Access Stash at http://localhost:9999
```

Or use the [docker-compose examples](#docker-compose-examples) below for a more complete setup.

## About

This is intended to be a drop-in replacement for the original container image from the Stash maintainers. As such, the container is **not** root-less and uses the same configuration and storage paths.

The regular image replaces ffmpeg with jellyfin-ffmpeg, which offers some improvements over the regular ffmpeg binaries.

There is a *"lite"* image that's based on Alpine Linux for a smaller, more secure container. It has no hardware acceleration support.

Both images include an entrypoint script that parses and installs all required dependencies for your installed plugins/scrapers.

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

This image includes jellyfin-ffmpeg with full hardware acceleration support for transcoding.

### Setup Instructions

1. **Enable in Stash**: Go to Settings > System > Transcoding and enable hardware acceleration
2. **GPU Access**: Ensure your Docker setup has access to your GPU (see examples below)

### Supported Hardware

| GPU Type | Support Level | Notes |
|----------|---------------|--------|
| **NVIDIA** | ✅ Full Support | NVENC/NVDEC for encode/decode |
| **Intel** | ✅ Full Support | Quick Sync Video (QSV) |
| **AMD** | ⚠️ Limited | Not (currently) supported by Stash |

### NVIDIA Example
```yaml
services:
  stash:
    # ... other config
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
```

### Intel Example
```yaml
services:
  stash:
    # ... other config
    devices:
      - /dev/dri:/dev/dri
```

For more details, see the [Jellyfin hardware acceleration guide](https://jellyfin.org/docs/general/administration/hardware-acceleration/).

## Plugin Dependencies

This image automatically installs Python dependencies for your Stash plugins and scrapers.

### How It Works

1. **Detection**: The entrypoint script scans your plugins and scrapers directories
2. **Parsing**: Finds all `requirements.txt` files
3. **Installation**: Combines and installs dependencies in a virtual environment
4. **Automatic**: Runs on every container start

### Requirements

- Your plugins/scrapers must include a `requirements.txt` file
- Dependencies are installed using pip in a Python virtual environment
- Virtual environment is located at `/pip-install/venv` and added to PATH

### Manual Installation

If you need to install additional packages:

```bash
# Enter the container
docker exec -it stash bash

# Activate the virtual environment
source /pip-install/venv/bin/activate

# Install packages
pip install your-package-name
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
      - PUID=1000
      - PGID=1000
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
      - PUID=1000
      - PGID=1000
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
      - PUID=1000
      - PGID=1000
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
      - PUID=1000
      - PGID=1000
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

### Common Issues

#### Permission Problems
```bash
# Fix ownership of mounted volumes
sudo chown -R 1000:1000 ./config ./data ./metadata ./cache ./generated
```

#### GPU Not Detected
- Ensure Docker has GPU support installed
- Verify `/dev/dri` permissions (Intel)

#### Plugin Dependencies Not Installing
- Check that your plugins have `requirements.txt` files
- Restart the container after adding new plugins
- Check container logs: `docker logs stash`
- Verify virtual environment: `docker exec stash ls -la /pip-install/venv/`

### Getting Help

- [Stash Documentation](https://docs.stashapp.cc/)
- [Stash Discord](https://discord.gg/2TsNFKt)
- [Report Issues](https://github.com/nerethos/docker-stash/issues)
- [Stash GitHub Discussions](https://github.com/stashapp/stash/discussions)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This Docker project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**Important**: This MIT license applies to the Docker packaging, build scripts, configuration files, and related automation created for this project. The Stash software itself remains licensed under the [GNU Affero General Public License v3.0 (AGPLv3)](https://github.com/stashapp/stash/blob/develop/LICENSE) as maintained by the original developers.

When using these Docker images, you must comply with both:
- The MIT license for the Docker packaging and scripts (this repository)
- The AGPLv3 license for the Stash software (when applicable)

For the complete Stash license terms, please refer to the [upstream Stash repository](https://github.com/stashapp/stash/blob/develop/LICENSE).
