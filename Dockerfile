# syntax=docker/dockerfile:1

FROM ubuntu:24.04
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
ARG STASH_RELEASE

ENV \
  HOME="/root" \
  TZ="Etc/UTC" \
  LANG=en_US.UTF-8 \
  LANGUAGE=en_US:en \
  LC_ALL=en_US.UTF-8 \
  STASH_CONFIG_FILE="/root/.stash/config.yml" \
  NVIDIA_DRIVER_CAPABILITIES="compute,video,utility" \
  NVIDIA_VISIBLE_DEVICES="all" \
  PY_VENV="/pip-install/venv" \
  PATH="/pip-install/venv/bin:/usr/lib/jellyfin-ffmpeg:$PATH"

RUN touch /var/mail/ubuntu && chown ubuntu /var/mail/ubuntu && userdel -r ubuntu

RUN \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt-get update && \
  apt-get install -y \
    --no-install-recommends \
    --no-install-suggests \
    ca-certificates \
    curl \
    gosu \
    libvips-tools \
    locales \
    python3 \
    python3-pip \
    python3-venv \
    tzdata && \
  sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
  locale-gen && \
  useradd -u 1000 -U -d /config -s /bin/false stash && \
  usermod -G users,video stash && \
  chmod 711 /root

RUN \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt-get update && \
  apt-get install -y --no-install-recommends gpg && \
  curl -fsSL https://repo.jellyfin.org/jellyfin_team.gpg.key | \
    gpg --dearmor -o /usr/share/keyrings/jellyfin.gpg && \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/jellyfin.gpg] https://repo.jellyfin.org/$(awk -F'=' '/^ID=/{print $NF}' /etc/os-release) $(awk -F'=' '/^VERSION_CODENAME=/{print $NF}' /etc/os-release) main" \
    > /etc/apt/sources.list.d/jellyfin.list && \
  apt-get update && \
  apt-get install --no-install-recommends --no-install-suggests -y \
    jellyfin-ffmpeg7 && \
  apt-get purge -y gpg && \
  apt-get autoremove -y

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
  _release="${STASH_RELEASE:-}" && \
  if [ -z "$_release" ]; then \
    _release=$(curl -fsSL "https://api.github.com/repos/stashapp/stash/releases/latest" \
    | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  fi && \
  curl -fsSL -o /usr/bin/stash \
    "https://github.com/stashapp/stash/releases/download/${_release}/${STASH_ARCH}" && \
  chmod +x /usr/bin/stash

COPY --chmod=755 entrypoint.sh /usr/local/bin

EXPOSE 9999
ENTRYPOINT ["entrypoint.sh"]
