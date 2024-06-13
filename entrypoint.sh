#!/bin/bash
echo '───────────────────────────────────────

Installing plugin dependencies...

───────────────────────────────────────
'
python3 -m venv ${PY_VENV}
pip install \
    bencoder.pyx \
    cloudscraper \
    lxml \
    requests \
    requests-toolbelt \
    stashapp-tools
gem install \
    faraday

PUID=${PUID:-911}
PGID=${PGID:-911}
if [ -z "${1}" ]; then
    set -- "stash"
fi
echo '
───────────────────────────────────────

This is an unofficial docker image created by nerethos.'
echo '
───────────────────────────────────────'
echo '
To support stash development visit:
https://opencollective.com/stashapp

───────────────────────────────────────'
echo '
Changing to user provided UID & GID...
'

groupmod -o -g "$PGID" stash
usermod -o -u "$PUID" stash
echo '
───────────────────────────────────────
GID/UID
───────────────────────────────────────'
echo "
UID:${PUID}
GID:${PGID}"
echo '
───────────────────────────────────────'
echo '
Starting stash...

───────────────────────────────────────
'
exec "$@"