#!/usr/bin/env bash

RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
PIDFILE="$RUNTIME_DIR/caffeine-inhibit.pid"
PAUSED_STATE="$RUNTIME_DIR/caffeine-paused.state"
LOCK_PIDFILE="$RUNTIME_DIR/caffeine-lock-inhibit.pid"
KEEP_AWAKE_ON_LOCK="$HOME/.config/caffeine-keep-awake-on-lock"

# Monitor the ScreenSaver ActiveChanged D-Bus signal
dbus-monitor "type='signal',interface='org.freedesktop.ScreenSaver',member='ActiveChanged'" | while read -r line; do
    if echo "$line" | grep -q "boolean true"; then
        # Screen locked -> temporarily remove inhibit if it is running
        if [ -f "$PIDFILE" ]; then
            INHIBIT_PID=$(cat "$PIDFILE")
            if [ -n "$INHIBIT_PID" ] && kill -0 "$INHIBIT_PID" 2>/dev/null; then
                kill "$INHIBIT_PID" >/dev/null 2>&1
            fi
            rm -f "$PIDFILE"
            # Write a paused state file to know we need to resume on unlock
            touch "$PAUSED_STATE"
            # Optionally keep the system awake while locked: block sleep only,
            # so the screens can still turn off
            if [ -f "$KEEP_AWAKE_ON_LOCK" ]; then
                systemd-inhibit \
                    --what=sleep \
                    --why="Caffeine: keeping system awake while locked" \
                    --mode=block \
                    sleep infinity &
                echo $! > "$LOCK_PIDFILE"
            fi
        fi
    elif echo "$line" | grep -q "boolean false"; then
        # Screen unlocked -> drop the lock-time sleep inhibit if present
        if [ -f "$LOCK_PIDFILE" ]; then
            kill "$(cat "$LOCK_PIDFILE")" >/dev/null 2>&1
            rm -f "$LOCK_PIDFILE"
        fi
        # Resume inhibit if it was paused
        if [ -f "$PAUSED_STATE" ]; then
            rm -f "$PAUSED_STATE"
            # Start systemd-inhibit and write its PID to PIDFILE
            systemd-inhibit \
                --what=idle \
                --why="Caffeine: resumed after screen unlock" \
                --mode=block \
                sleep infinity &
            echo $! > "$PIDFILE"
        fi
    fi
done
