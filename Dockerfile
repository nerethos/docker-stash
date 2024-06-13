# syntax=docker/dockerfile:1

FROM debian:bookworm-slim AS binary
RUN apt-get install -y \
      curl \
      gnupg
RUN \    
  echo "**** install stash ****" && \
    if [ -z ${STASH_RELEASE+x} ]; then \
      STASH_RELEASE=$(curl -sX GET "https://api.github.com/repos/stashapp/stash/releases/latest" \
      | awk '/tag_name/{print $4;exit}' FS='[""]'); \
    fi && \
    curl -o \
      /stash -L \
      "https://github.com/stashapp/stash/releases/download/${STASH_RELEASE}/stash-linux"


FROM debian:bookworm-slim AS app
# labels
ARG DEBIAN_FRONTEND="noninteractive"

# debian environment variables
ENV HOME="/root" \
  TZ="Etc/UTC" \
  LANG="en_US.UTF-8" \
  LANGUAGE="en_US:en" \
  # stash environment variables
  STASH_CONFIG_FILE="/root/.stash/config.yml" \
  # hardware acceleration env
  NVIDIA_DRIVER_CAPABILITIES="compute,video,utility" \
  NVIDIA_VISIBLE_DEVICES="all" \
  PY_VENV="/pip-install/venv" \
  PATH="/pip-install/venv/bin:$PATH" 

RUN \
  echo "**** add contrib and non-free to sources ****" && \
    sed -i 's/main/main contrib non-free non-free-firmware/g' /etc/apt/sources.list.d/debian.sources && \
  echo "**** install locales ****" && \
    apt-get update && \
    apt-get install -y \
      locales && \
  echo "**** install packages ****" && \
    apt-get install -y \
      --no-install-recommends \
      --no-install-suggests \
      ca-certificates \
      libvips-tools \
      python3 \
      python3-pip \
      python3-venv \
      ruby \
      tzdata \
      wget \
      yq && \
  # echo "**** activate python virtual environment ****" && \
  #   python3 -m venv ${PY_VENV} && \
  # echo "**** install plugin deps ****" && \
  #   pip install \
  #     bencoder.pyx \
  #     bs4 \
  #     cloudscraper \
  #     lxml \
  #     mechanicalsoup \
  #     pystashlib \
  #     requests \
  #     requests-toolbelt \
  #     stashapp-tools && \
  #   gem install \
  #     faraday && \
  echo "**** generate locale ****" && \
    locale-gen en_US.UTF-8 && \
  echo "**** create stash user and make our folders ****" && \
    useradd -u 1000 -U -d /config -s /bin/false stash && \
    usermod -G users stash && \
    usermod -G video stash 

RUN \
  echo "*** install hardware acceleration dependencies ***" && \
    wget -O - https://repo.jellyfin.org/jellyfin_team.gpg.key | apt-key add - && \
    echo "deb [arch=$( dpkg --print-architecture )] https://repo.jellyfin.org/$( awk -F'=' '/^ID=/{ print $NF }' /etc/os-release ) $( awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release ) main" | tee /etc/apt/sources.list.d/jellyfin.list && \
    apt-get update && \
    apt-get install --no-install-recommends --no-install-suggests -y \
    jellyfin-ffmpeg5 \
    mesa-va-drivers && \
  echo "**** cleanup ****" && \
    apt-get autoremove && \
    apt-get clean && \
    rm -rf \
      /tmp/* \
      /var/lib/apt/lists/* \
      /var/tmp/* \
      /var/log/*

ENV PATH="${PATH}:/usr/lib/jellyfin-ffmpeg"

COPY --from=binary /stash /usr/bin/stash

COPY entrypoint.sh /usr/local/bin

RUN chmod +x -R /usr/local/bin

RUN chmod +x /usr/bin/stash

EXPOSE 9999
ENTRYPOINT ["entrypoint.sh"]