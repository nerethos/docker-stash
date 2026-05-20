#!/usr/bin/env bats

SCRIPT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)/entrypoint.sh"

setup() {
    TEST_TMP=$(mktemp -d)
    BIN="$TEST_TMP/bin"
    mkdir -p "$BIN"

    # no-op stubs
    for cmd in groupmod usermod pip pip-compile; do
        printf '#!/bin/sh\nexit 0\n' > "$BIN/$cmd"
        chmod +x "$BIN/$cmd"
    done

    # gosu: drop the user arg and exec the rest
    printf '#!/bin/sh\nshift\nexec "$@"\n' > "$BIN/gosu"
    chmod +x "$BIN/gosu"

    # stash: no-op so gosu stub can exec it
    printf '#!/bin/sh\nexit 0\n' > "$BIN/stash"
    chmod +x "$BIN/stash"

    # python3: handle -m venv by creating a stub activate
    cat > "$BIN/python3" <<'EOF'
#!/bin/sh
if [ "$1" = "-m" ] && [ "$2" = "venv" ]; then
    mkdir -p "${3}/bin"
    printf '#!/bin/sh\n' > "${3}/bin/activate"
fi
exit 0
EOF
    chmod +x "$BIN/python3"

    CONFIG_DIR="$TEST_TMP/.stash"
    mkdir -p "$CONFIG_DIR"

    PY_VENV_DIR="$TEST_TMP/venv"
    mkdir -p "$PY_VENV_DIR/bin"
    printf '#!/bin/sh\n' > "$PY_VENV_DIR/bin/activate"

    export PATH="$BIN:$PATH"
    export STASH_CONFIG_FILE="$CONFIG_DIR/config.yml"
    export PY_VENV="$PY_VENV_DIR"
}

teardown() {
    rm -rf "$TEST_TMP"
}

@test "exits 1 when config file is missing" {
    run bash "$SCRIPT"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Config file not found"* ]]
}

@test "exits 1 when PUID is 0" {
    touch "$STASH_CONFIG_FILE"
    run env PUID=0 bash "$SCRIPT"
    [ "$status" -eq 1 ]
    [[ "$output" == *"PUID/PGID cannot be 0"* ]]
}

@test "exits 1 when PGID is 0" {
    touch "$STASH_CONFIG_FILE"
    run env PGID=0 bash "$SCRIPT"
    [ "$status" -eq 1 ]
    [[ "$output" == *"PUID/PGID cannot be 0"* ]]
}

@test "warns when plugins_path is absent from config" {
    printf 'scrapers_path: %s/scrapers\n' "$TEST_TMP" > "$STASH_CONFIG_FILE"
    mkdir -p "$TEST_TMP/scrapers"
    run bash "$SCRIPT"
    [[ "$output" == *"plugins_path not found"* ]]
}

@test "warns when scrapers_path is absent from config" {
    printf 'plugins_path: %s/plugins\n' "$TEST_TMP" > "$STASH_CONFIG_FILE"
    mkdir -p "$TEST_TMP/plugins"
    run bash "$SCRIPT"
    [[ "$output" == *"scrapers_path not found"* ]]
}

@test "reports no requirements when both paths are absent" {
    touch "$STASH_CONFIG_FILE"
    run bash "$SCRIPT"
    [[ "$output" == *"No requirements found"* ]]
}
