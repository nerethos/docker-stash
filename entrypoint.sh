#!/bin/bash

# Path to the config file
config_file="/root/.stash/config.yml"

# Extract the plugins_path from the config file
plugins_path=$(grep -E '^plugins_path:' "$config_file" | sed 's/plugins_path:[ ]*//')

# Check if plugins_path was found
if [ -z "$plugins_path" ]; then
    echo "Warning: plugins_path not found in $config_file"
    echo "Skipping python modules installation"
else
    # Initialize an empty variable to store the contents
    all_requirements=""

    # Find all requirements.txt files and process them
    while IFS= read -r -d '' file; do
        # Append the contents of the file to the variable
        all_requirements+="$(cat "$file")"$'\n'
    done < <(find "$plugins_path" -type f -name "requirements.txt" -print0)

    # Deduplicate the requirements
    unique_requirements=$(echo "$all_requirements" | sort | uniq)

    # Define the output file path
    output_file="$plugins_path/requirements.txt"

    # Ensure the output directory exists
    mkdir -p "$(dirname "$output_file")"

    # Write the unique requirements to the output file
    echo "$unique_requirements" >"$output_file"

    echo "Deduplicated requirements have been saved to $output_file"
    echo '───────────────────────────────────────

Installing plugin dependencies...

───────────────────────────────────────
    '
    python3 -m venv ${PY_VENV}
    pip install -r $plugins_path/requirements.txt
fi

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
