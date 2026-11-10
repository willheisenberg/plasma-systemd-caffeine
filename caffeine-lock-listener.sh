#!/usr/bin/env bash

RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
PIDFILE="$RUNTIME_DIR/caffeine-inhibit.pid"
LISTENER_PIDFILE="$RUNTIME_DIR/caffeine-listener.pid"
PAUSED_STATE="$RUNTIME_DIR/caffeine-paused.state"
LOCK_PIDFILE="$RUNTIME_DIR/caffeine-lock-inhibit.pid"
LOCKFILE="$RUNTIME_DIR/caffeine-lock-listener.lock"
KEEP_AWAKE_ON_LOCK="$HOME/.config/caffeine-keep-awake-on-lock"

# --- Single instance ---------------------------------------------------
# Two listeners share the same pidfiles: each one overwrites the other's
# LOCK_PIDFILE, so on unlock only the last inhibitor is killed and the
# rest leak. Leaked --mode=block inhibitors make every suspend request
# fail with "Operation denied due to active block inhibitor".
exec 9>"$LOCKFILE" || exit 1
flock -n 9 || exit 0

# We hold the lock, so this pid is authoritative.
echo $$ > "$LISTENER_PIDFILE"

MONITOR_PID=""

# Kill the inhibitor recorded in a pidfile and drop the file.
drop_inhibit() {
    local file="$1" pid
    [ -f "$file" ] || return 0
    pid=$(cat "$file" 2>/dev/null)
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null
    fi
    rm -f "$file"
}

# Kill our inhibitors that no pidfile accounts for any more. Covers
# leftovers from an earlier listener that was killed without cleanup,
# or from a runtime dir wiped while inhibitors kept running.
reap_orphans() {
    local keep pid cmd
    keep=" $(cat "$PIDFILE" 2>/dev/null) $(cat "$LOCK_PIDFILE" 2>/dev/null) "
    for pid in $(pgrep -x -u "$(id -u)" systemd-inhibit 2>/dev/null); do
        case "$keep" in
            *" $pid "*) continue ;;
        esac
        cmd=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null) || continue
        case "$cmd" in
            *"Caffeine:"*) kill "$pid" 2>/dev/null ;;
        esac
    done
}

# A plain `kill` on this script leaves dbus-monitor and the lock-time
# inhibitor behind, so tear both down on any exit path.
cleanup() {
    trap - EXIT INT TERM HUP
    # Verify the pid really is our dbus-monitor before signalling it: on a
    # shell that does not set $! for a process substitution it could be a
    # stale pid belonging to someone else by now.
    if [ -n "$MONITOR_PID" ]; then
        case "$(tr '\0' ' ' < "/proc/$MONITOR_PID/cmdline" 2>/dev/null)" in
            *dbus-monitor*) kill "$MONITOR_PID" 2>/dev/null ;;
        esac
    fi
    drop_inhibit "$LOCK_PIDFILE"
    rm -f "$LISTENER_PIDFILE"
    exit 0
}
trap cleanup EXIT INT TERM HUP

reap_orphans

# Read via process substitution, not a pipeline: it keeps the loop in this
# shell, so the traps and MONITOR_PID stay usable. A pipeline would run the
# loop in a subshell and leave dbus-monitor behind on exit.
exec 3< <(exec dbus-monitor "type='signal',interface='org.freedesktop.ScreenSaver',member='ActiveChanged'")
MONITOR_PID=$!

while read -r line <&3; do
    case "$line" in
        *"boolean true"*)
            # Screen locked -> temporarily remove inhibit if it is running
            [ -f "$PIDFILE" ] || continue
            drop_inhibit "$PIDFILE"
            # Write a paused state file to know we need to resume on unlock
            touch "$PAUSED_STATE"
            # Optionally keep the system awake while locked: block sleep only,
            # so the screens can still turn off
            if [ -f "$KEEP_AWAKE_ON_LOCK" ]; then
                # Replace any previous lock inhibit instead of leaking it
                drop_inhibit "$LOCK_PIDFILE"
                systemd-inhibit \
                    --what=sleep \
                    --why="Caffeine: keeping system awake while locked" \
                    --mode=block \
                    sleep infinity &
                echo $! > "$LOCK_PIDFILE"
            fi
            ;;
        *"boolean false"*)
            # Screen unlocked -> drop the lock-time sleep inhibit if present
            drop_inhibit "$LOCK_PIDFILE"
            # Resume inhibit if it was paused
            if [ -f "$PAUSED_STATE" ]; then
                rm -f "$PAUSED_STATE"
                drop_inhibit "$PIDFILE"
                systemd-inhibit \
                    --what=idle \
                    --why="Caffeine: resumed after screen unlock" \
                    --mode=block \
                    sleep infinity &
                echo $! > "$PIDFILE"
            fi
            ;;
    esac
done
