# syntax=docker/dockerfile:1

FROM --platform=$BUILDPLATFORM ubuntu:24.04
# labels
LABEL \
  org.opencontainers.image.title="Stash" \
  org.opencontainers.image.description="An organizer for your porn, written in Go." \
  org.opencontainers.image.url="https://github.com/nerethos/docker-stash" \
  org.opencontainers.image.documentation="https://docs.stashapp.cc" \
  org.opencontainers.image.source="https://github.com/nerethos/docker-stash" \
  org.opencontainers.image.authors="nerethos"

ARG DEBIAN_FRONTEND="noninteractive"
ARG TARGETPLATFORM
ARG TARGETARCH
ARG TARGETVARIANT

# debian environment variables
ENV \
  HOME="/config" \
  TZ="Etc/UTC" \
  # stash environment variables
  PUID=1000 \
  PGID=1000 \
  STASH_CONFIG_FILE="/config/config.yml" \
  STASH_GENERATED="/config/generated/" \
  STASH_METADATA="/config/metadata/" \
  STASH_CACHE="/config/cache/" \
  STASH_PLUGINS="/config/plugins/" \
  STASH_SCRAPERS="/config/scrapers" \
  # hardware acceleration env
  NVIDIA_DRIVER_CAPABILITIES="compute,video,utility" \
  NVIDIA_VISIBLE_DEVICES="all" \
  PY_VENV="/venv" \
  PATH="/venv/bin:/config/.local:$PATH" 

RUN touch /var/mail/ubuntu && chown ubuntu /var/mail/ubuntu && userdel -r ubuntu

RUN \
  apt-get update && \
  apt-get install -y \
    apt-utils \
    locales && \
    rm -rf \
      /tmp/* \
      /var/lib/apt/lists/* \
      /var/tmp/* \
      /var/log/* && \
  sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
  locale-gen
ENV LANG=en_US.UTF-8  
ENV LANGUAGE=en_US:en  
ENV LC_ALL=en_US.UTF-8    

RUN \
  apt-get update && \
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
  wget -O - https://repo.jellyfin.org/jellyfin_team.gpg.key | apt-key add - && \
  echo "deb [arch=$( dpkg --print-architecture )] https://repo.jellyfin.org/$( awk -F'=' '/^ID=/{ print $NF }' /etc/os-release ) $( awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release ) main" | tee /etc/apt/sources.list.d/jellyfin.list && \
  apt-get update && \
  apt-get install --no-install-recommends --no-install-suggests -y \
    jellyfin-ffmpeg7 && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /var/log/*

RUN \
  set -ex && \
  echo "TARGETPLATFORM=$TARGETPLATFORM" && \
  echo "TARGETARCH=$TARGETARCH" && \
  echo "TARGETVARIANT=$TARGETVARIANT" && \
  case "${TARGETARCH}${TARGETVARIANT}" in \
      "amd64") STASH_ARCH="stash-linux" ;; \
      "armv7") STASH_ARCH="stash-linux-arm32v7" ;; \
      "armv6") STASH_ARCH="stash-linux-arm32v6" ;; \
      "arm64") STASH_ARCH="stash-linux-arm64v8" ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}${TARGETVARIANT}"; exit 1 ;; \
  esac && \
  if [ -z ${STASH_RELEASE+x} ]; then \
    STASH_RELEASE=$(curl -sX GET "https://api.github.com/repos/stashapp/stash/releases/latest" \
    | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  fi && \
  curl -o \
    /usr/bin/stash -L \
    "https://github.com/stashapp/stash/releases/download/${STASH_RELEASE}/${STASH_ARCH}" && \
  chmod +x /usr/bin/stash

RUN \
  mkdir -p /config && \
  useradd -u ${PUID} -U -d /config -s /bin/false stash && \
  usermod -G users stash && \
  usermod -G video stash && \
  chown -R ${PUID} /config

RUN \
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

USER stash
WORKDIR /config
EXPOSE 9999
ENTRYPOINT ["entrypoint.sh"]