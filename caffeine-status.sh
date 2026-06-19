#!/usr/bin/env bash

RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
PIDFILE="$RUNTIME_DIR/caffeine-inhibit.pid"
LISTENER_PIDFILE="$RUNTIME_DIR/caffeine-listener.pid"
PAUSED_STATE="$RUNTIME_DIR/caffeine-paused.state"
MANUAL_STATE="$RUNTIME_DIR/caffeine-manual.state"
OVERRIDE_STATE="$RUNTIME_DIR/caffeine-override.state"
APPS_CONFIG="$HOME/.config/caffeine-apps.list"

# 1. Check if any app in the auto-inhibit list is running
app_running=false
if [ -f "$APPS_CONFIG" ]; then
    while read -r app || [ -n "$app" ]; do
        # Ignore comments and empty lines
        [[ "$app" =~ ^# ]] && continue
        [[ -z "$app" ]] && continue

        # Check if the process exists
        if pgrep -x "$app" >/dev/null 2>&1; then
            app_running=true
            break
        fi
    done < "$APPS_CONFIG"
fi

# 2. If no auto-inhibit app is running, clear the manual override state
if [ "$app_running" = false ]; then
    rm -f "$OVERRIDE_STATE"
fi

# 3. Determine if caffeine should be active
should_be_active=false
if [ -f "$MANUAL_STATE" ]; then
    should_be_active=true
elif [ -f "$OVERRIDE_STATE" ]; then
    should_be_active=false
elif [ "$app_running" = true ]; then
    should_be_active=true
fi

# 4. Check if inhibit is currently running
inhibit_running=false
if [ -f "$PIDFILE" ]; then
    INHIBIT_PID=$(cat "$PIDFILE")
    if [ -n "$INHIBIT_PID" ] && kill -0 "$INHIBIT_PID" 2>/dev/null; then
        inhibit_running=true
    else
        # Stale PID file — clean up
        rm -f "$PIDFILE"
    fi
fi

# 5. Check if currently paused due to screen lock
is_paused=false
if [ -f "$PAUSED_STATE" ]; then
    is_paused=true
fi

# 6. Maintain background process states dynamically
if [ "$should_be_active" = true ]; then
    if [ "$is_paused" = true ]; then
        echo "paused"
    else
        # Ensure systemd-inhibit is running
        if [ "$inhibit_running" = false ]; then
            systemd-inhibit \
                --what=idle \
                --why="Caffeine: manual or app-triggered inhibit" \
                --mode=block \
                sleep infinity &
            echo $! > "$PIDFILE"

            # Ensure lock-listener is running
            if [ ! -f "$LISTENER_PIDFILE" ] || ! kill -0 "$(cat "$LISTENER_PIDFILE" 2>/dev/null)" 2>/dev/null; then
                LISTENER_BIN="$HOME/.local/bin/caffeine-lock-listener.sh"
                if [ ! -f "$LISTENER_BIN" ]; then
                    LISTENER_BIN="$(dirname "${BASH_SOURCE[0]}")/caffeine-lock-listener.sh"
                fi
                if [ -f "$LISTENER_BIN" ]; then
                    bash "$LISTENER_BIN" &
                    echo $! > "$LISTENER_PIDFILE"
                fi
            fi
        fi
        echo "active"
    fi
else
    # Should not be active -> clean up inhibit
    if [ "$inhibit_running" = true ]; then
        kill "$INHIBIT_PID" >/dev/null 2>&1
        rm -f "$PIDFILE"
    fi
    # Clean up lock-listener
    if [ -f "$LISTENER_PIDFILE" ]; then
        LISTENER_PID=$(cat "$LISTENER_PIDFILE")
        if [ -n "$LISTENER_PID" ] && kill -0 "$LISTENER_PID" 2>/dev/null; then
            kill "$LISTENER_PID" >/dev/null 2>&1
        fi
        rm -f "$LISTENER_PIDFILE"
    fi
    rm -f "$PAUSED_STATE"
    echo "inactive"
fi

