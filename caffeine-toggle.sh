#!/bin/sh

RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
PIDFILE="$RUNTIME_DIR/caffeine-inhibit.pid"

if [ -f "$PIDFILE" ] && ps -p "$(cat "$PIDFILE")" >/dev/null 2>&1; then
  kill "$(cat "$PIDFILE")" >/dev/null 2>&1
  rm -f "$PIDFILE"
else
  systemd-inhibit \
    --what=idle:sleep \
    --why="Manual caffeine" \
    --mode=block \
    sh -c 'echo $$ > "'"$PIDFILE"'"; sleep infinity' &
fi
