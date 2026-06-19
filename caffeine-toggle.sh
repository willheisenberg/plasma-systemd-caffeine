#!/usr/bin/env bash

RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
MANUAL_STATE="$RUNTIME_DIR/caffeine-manual.state"
OVERRIDE_STATE="$RUNTIME_DIR/caffeine-override.state"

STATUS_BIN="$HOME/.local/bin/caffeine-status.sh"
if [ ! -f "$STATUS_BIN" ]; then
    STATUS_BIN="$(dirname "${BASH_SOURCE[0]}")/caffeine-status.sh"
fi

# Determine current state by running the status script
CURRENT_STATE="inactive"
if [ -f "$STATUS_BIN" ]; then
    CURRENT_STATE=$(bash "$STATUS_BIN" | tail -n 1)
fi

if [ "$CURRENT_STATE" = "active" ] || [ "$CURRENT_STATE" = "paused" ]; then
    # Currently active/paused -> force deactivate
    rm -f "$MANUAL_STATE"
    touch "$OVERRIDE_STATE"
else
    # Currently inactive -> force activate
    rm -f "$OVERRIDE_STATE"
    touch "$MANUAL_STATE"
fi

# Instantly trigger the status updater to apply changes
if [ -f "$STATUS_BIN" ]; then
    bash "$STATUS_BIN" >/dev/null 2>&1
fi

