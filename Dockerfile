# syntax=docker/dockerfile:1

FROM debian:bookworm-slim
# labels
ARG DEBIAN_FRONTEND="noninteractive"

# debian environment variables
ENV HOME="/root" \
  TZ="Etc/UTC" \
  # stash environment variables
  STASH_CONFIG_FILE="/root/.stash/config.yml" \
  # hardware acceleration env
  NVIDIA_DRIVER_CAPABILITIES="compute,video,utility" \
  NVIDIA_VISIBLE_DEVICES="all" \
  PY_VENV="/pip-install/venv" \
  PATH="/pip-install/venv/bin:$PATH" 

RUN \
  echo "**** install locales ****" && \
    apt-get update && \
    apt-get install -y \
      apt-utils \
      locales && \
  echo "**** generate locale ****" && \
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8    

RUN \
  apt-get install -y \
    --no-install-recommends \
    --no-install-suggests \
    gnupg \
    ca-certificates \
    libvips-tools \
    python3 \
    python3-pip \
    python3-venv \
    ruby \
    tzdata \
    wget \
    curl \
    yq && \
    rm -rf \
      /tmp/* \
      /var/lib/apt/lists/* \
      /var/tmp/* \
      /var/log/*

RUN \
  echo "*** install jellyfin-ffmpeg ***" && \
    wget -O - https://repo.jellyfin.org/jellyfin_team.gpg.key | apt-key add - && \
    echo "deb [arch=$( dpkg --print-architecture )] https://repo.jellyfin.org/$( awk -F'=' '/^ID=/{ print $NF }' /etc/os-release ) $( awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release ) main" | tee /etc/apt/sources.list.d/jellyfin.list && \
    apt-get update && \
    apt-get install --no-install-recommends --no-install-suggests -y \
    jellyfin-ffmpeg5 && \
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
      "https://github.com/stashapp/stash/releases/download/${STASH_RELEASE}/stash-linux" && \
    chmod +x /usr/bin/stash

RUN \
  echo "**** create stash user and make our folders ****" && \
    useradd -u 1000 -U -d /config -s /bin/false stash && \
    usermod -G users stash && \
    usermod -G video stash 

RUN \
  echo "**** cleanup ****" && \
    apt-get purge -qq wget gnupg curl apt-utils && \
    apt-get autoremove -qq && \
    apt-get clean -qq && \
    rm -rf \
      /tmp/* \
      /var/lib/apt/lists/* \
      /var/tmp/* \
      /var/log/*

ENV PATH="${PATH}:/usr/lib/jellyfin-ffmpeg"

COPY --chmod=755 entrypoint.sh /usr/local/bin

EXPOSE 9999
ENTRYPOINT ["entrypoint.sh"]