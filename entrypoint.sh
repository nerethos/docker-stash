#!/bin/bash
set -euo pipefail
# Path to the config file
config_file="/root/.stash/config.yml"

if [ ! -f "$config_file" ]; then
    echo "Error: Config file not found at $config_file" >&2
    echo "This appears to be a fresh install. Please run stash once to generate the config file." >&2
    exit 1
fi

# Extract the plugins_path from the config file
plugins_path=$(grep -E '^plugins_path:' "$config_file" | sed 's/plugins_path:[ ]*//')

# Extract the scrapers_path from the config file
scrapers_path=$(grep -E '^scrapers_path:' "$config_file" | sed 's/scrapers_path:[ ]*//')

# Initialize an empty variable to store the contents
all_requirements=""

# Check if plugins_path was found
if [ -z "$plugins_path" ]; then
    echo "Warning: plugins_path not found in $config_file"
else
    echo "Parsing plugin dependencies"
    # Find all requirements.txt files in plugins_path and process them
    while IFS= read -r -d '' file; do
        # Append the contents of the file to the variable
        all_requirements+="$(cat "$file")"$'\n'
    done < <(find "$plugins_path" -type f -name "requirements.txt" -print0)
fi

# Check if scrapers_path was found
if [ -z "$scrapers_path" ]; then
    echo "Warning: scrapers_path not found in $config_file"
else
    echo "Parsing scraper dependencies"
    # Find all requirements.txt files in scrapers_path and process them
    while IFS= read -r -d '' file; do
        # Append the contents of the file to the variable
        all_requirements+="$(cat "$file")"$'\n'
    done < <(find "$scrapers_path" -type f -name "requirements.txt" -print0)
fi

# Check if any requirements were found
if [ -z "$all_requirements" ]; then
    echo "No requirements found in either path."
else
    # Define a temporary file for combined requirements
    temp_requirements_file=$(mktemp)

    # Write the combined requirements to the temporary file
    echo "$all_requirements" >"$temp_requirements_file"

    # Define the output file path
    output_file="/root/.stash/requirements.txt"

    # Ensure the output directory exists
    mkdir -p "$(dirname "$output_file")"

    # Create a virtual environment and activate it
    python3 -m venv ${PY_VENV}
    source ${PY_VENV}/bin/activate

    # Install pip-tools
    pip install pip-tools

    # Use pip-compile to resolve and deduplicate the requirements
    pip-compile "$temp_requirements_file" --output-file "$output_file"

    # Clean up the temporary file
    rm "$temp_requirements_file"

    echo "Deduplicated requirements have been saved to $output_file"
    echo '───────────────────────────────────────

Installing dependencies...

───────────────────────────────────────
    '

    # Install the dependencies from the output file
    pip install -r $output_file
fi

if [ -z "${1:-}" ]; then
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
Starting stash...

───────────────────────────────────────
'
if [ -n "${PUID:-}" ] || [ -n "${PGID:-}" ]; then
    if [ -z "${PUID:-}" ] || [ -z "${PGID:-}" ]; then
        echo "Error: PUID and PGID must both be set" >&2
        exit 1
    fi
    if ! [[ "$PUID" =~ ^[0-9]+$ ]] || ! [[ "$PGID" =~ ^[0-9]+$ ]]; then
        echo "Error: PUID and PGID must be positive integers" >&2
        exit 1
    fi
    if [ "$PUID" -eq 0 ] || [ "$PGID" -eq 0 ]; then
        echo "Error: PUID/PGID cannot be 0" >&2
        exit 1
    fi
    groupmod -o -g "$PGID" stash
    usermod -o -u "$PUID" stash
    echo "UID:${PUID} GID:${PGID}"

    # Warn if PUID doesn't match the actual owner of the config dir
    actual_uid=$(stat -c '%u' /root/.stash 2>/dev/null || echo "")
    if [ -n "$actual_uid" ] && [ "$actual_uid" != "$PUID" ]; then
        echo "Warning: /root/.stash is owned by UID ${actual_uid}, but PUID=${PUID}."
        echo "Stash may fail with 'permission denied'. Either set PUID=${actual_uid} (and PGID to match),"
        echo "or chown the host bind mount to ${PUID}:${PGID} before starting the container."
    fi

    exec gosu stash "$@"
fi
exec "$@"
