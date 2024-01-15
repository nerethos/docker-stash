# syntax=docker/dockerfile:1

FROM debian:bookworm-slim
# labels
ARG \
  OFFICIAL_BUILD="false" \
  DEBIAN_FRONTEND="noninteractive"

# debian environment variables
ENV HOME="/root" \
  TZ="Etc/UTC" \
  LANG="en_US.UTF-8" \
  LANGUAGE="en_US:en" \
  # stash environment variables
  STASH_CONFIG_FILE="/config/config.yml" \
  USER="stash" \
  # python env
  PY_VENV="/pip-install/venv" \
  PATH="/pip-install/venv/bin:$PATH" \
  # hardware acceleration env
  NVIDIA_DRIVER_CAPABILITIES="compute,video,utility" \
  NVIDIA_VISIBLE_DEVICES="all" \
  # Logging
  LOGGER_LEVEL="1" \
  HWACCEL="Jellyfin-ffmpeg"

COPY stash/root/ /
RUN \
  echo "**** add contrib and non-free to sources ****" && \
    sed -i 's/main/main contrib non-free non-free-firmware/g' /etc/apt/sources.list.d/debian.sources && \
  echo "**** install apt-utils and locales ****" && \
    apt-get update && \
    apt-get install -y \
      apt-utils \
      locales && \
  echo "**** install packages ****" && \
    apt-get install -y \
      --no-install-recommends \
      --no-install-suggests \
      ca-certificates \
      curl \
      gnupg \
      gosu \
      libvips-tools \
      python3 \
      python3-pip \
      python3-venv \
      ruby \
      tzdata \
      wget \
      yq && \
  echo "**** activate python virtual environment ****" && \
    python3 -m venv ${PY_VENV} && \
  echo "**** install ruby gems ****" && \
    gem install \
      faraday && \
  echo "**** link su-exec to gosu ****" && \
    ln -s /usr/sbin/gosu /sbin/su-exec && \
  echo "**** generate locale ****" && \
    locale-gen en_US.UTF-8 && \
  echo "**** create stash user and make our folders ****" && \
    useradd -u 1000 -U -d /config -s /bin/false stash && \
    usermod -G users stash && \
    usermod -G video stash && \
    mkdir -p \
      /config \
      /defaults

RUN \
  echo "*** install hardware acceleration dependencies ***" && \
    wget -O - https://repo.jellyfin.org/jellyfin_team.gpg.key | apt-key add - && \
    echo "deb [arch=$( dpkg --print-architecture )] https://repo.jellyfin.org/$( awk -F'=' '/^ID=/{ print $NF }' /etc/os-release ) $( awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release ) main" | tee /etc/apt/sources.list.d/jellyfin.list && \
    apt-get update && \
    apt-get install --no-install-recommends --no-install-suggests -y \
    jellyfin-ffmpeg6 \
    mesa-va-drivers && \
  echo "**** linking jellyfin ffmpeg ****" && \
    ln -s \
      /usr/lib/jellyfin-ffmpeg/ffmpeg \
      /usr/bin/ffmpeg && \
    ln -s \
      /usr/lib/jellyfin-ffmpeg/ffprobe \
      /usr/bin/ffprobe && \
    ln -s \
      /usr/lib/jellyfin-ffmpeg/vainfo \
      /usr/bin/vainfo && \
  echo "**** cleanup ****" && \
    apt-get autoremove && \
    apt-get clean && \
    rm -rf \
      /tmp/* \
      /var/lib/apt/lists/* \
      /var/tmp/* \
      /var/log/*

RUN \    
  echo "**** install stash ****" && \
    if [ -z ${STASH_RELEASE+x} ]; then \
      STASH_RELEASE=$(curl -sX GET "https://api.github.com/repos/stashapp/stash/releases/latest" \
      | awk '/tag_name/{print $4;exit}' FS='[""]'); \
    fi && \
    curl -o \
      /usr/bin/stash -L \
      "https://github.com/stashapp/stash/releases/download/${STASH_RELEASE}/stash-linux"

RUN chmod +x /usr/bin/stash

VOLUME /pip-install

EXPOSE 9999
CMD ["/bin/bash", "/opt/entrypoint.sh"]