#!/usr/bin/env bash
set -e

echo "☕ Plasma Caffeine Widget Uninstaller"
echo "======================================"
echo

PLASMOID_ID="com.github.tesla.plasmacaffeine"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

# --- Stop any running caffeine processes ---
echo "🔄 Stopping running Caffeine processes..."
if [ -f "$RUNTIME_DIR/caffeine-inhibit.pid" ]; then
    INHIBIT_PID=$(cat "$RUNTIME_DIR/caffeine-inhibit.pid")
    if [ -n "$INHIBIT_PID" ] && kill -0 "$INHIBIT_PID" 2>/dev/null; then
        kill "$INHIBIT_PID" >/dev/null 2>&1 || true
    fi
fi
if [ -f "$RUNTIME_DIR/caffeine-listener.pid" ]; then
    LISTENER_PID=$(cat "$RUNTIME_DIR/caffeine-listener.pid")
    if [ -n "$LISTENER_PID" ] && kill -0 "$LISTENER_PID" 2>/dev/null; then
        kill "$LISTENER_PID" >/dev/null 2>&1 || true
    fi
fi

# --- Remove Plasma widget ---
echo "📦 Removing Plasma widget..."
if kpackagetool6 -t Plasma/Applet --list 2>/dev/null | grep -q "$PLASMOID_ID"; then
    kpackagetool6 -t Plasma/Applet --remove "$PLASMOID_ID"
    echo "   ✅ Widget removed"
else
    echo "   ℹ️  Widget was not installed"
fi

# --- Remove scripts ---
echo "📁 Removing scripts from ~/.local/bin/..."
rm -f "$HOME/.local/bin/caffeine-status.sh"
rm -f "$HOME/.local/bin/caffeine-toggle.sh"
rm -f "$HOME/.local/bin/caffeine-lock-listener.sh"

# --- Remove config and runtime files ---
echo "🧹 Cleaning up config and runtime files..."
rm -f "$HOME/.config/caffeine-apps.list"
rm -f "$RUNTIME_DIR/caffeine-inhibit.pid"
rm -f "$RUNTIME_DIR/caffeine-listener.pid"
rm -f "$RUNTIME_DIR/caffeine-paused.state"
rm -f "$RUNTIME_DIR/caffeine-manual.state"

# --- Remove icons from user icon theme ---
echo "🎨 Removing icons from icon theme..."
rm -f "$HOME/.local/share/icons/hicolor/scalable/apps/caffeine-cup-full.svg"
rm -f "$HOME/.local/share/icons/hicolor/scalable/apps/caffeine-cup-empty.svg"
rm -f "$HOME/.local/share/icons/hicolor/scalable/apps/bundledcaffeinecupfull.svg"
rm -f "$HOME/.local/share/icons/hicolor/scalable/apps/bundledcaffeinecupempty.svg"
if command -v gtk-update-icon-cache &>/dev/null; then
    gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
fi

echo
echo "✅ Uninstallation complete!"
echo
echo "Restart Plasma to fully remove the widget from panels:"
echo "   systemctl --user restart plasma-plasmashell.service"
echo
