#!/usr/bin/env bash
set -e

echo "☕ Plasma Caffeine Widget Installer"
echo "=================================="
echo
echo "This installer sets up a native Caffeine widget for KDE Plasma 6:"
echo "  • systemd-native (Wayland compatible)"
npx_output="  • Auto-pauses on lock screen to allow monitors to sleep"
echo "$npx_output"
echo "  • No Python, no legacy tray hacks, no X11 dependencies"
echo "  • Symmetrical theme-aware vector icons"
echo

# --- Locate script directory ---
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Detect distribution ---
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "❌ Cannot detect Linux distribution."
    exit 1
fi

# --- Install optional dependencies ---
echo "📦 Checking optional dependencies for $DISTRO..."
case "$DISTRO" in
    arch|manjaro|endeavouros)
        sudo pacman -Syu --needed --noconfirm \
            plasma-workspace || true
        ;;
    ubuntu|debian|neon|pop)
        sudo apt update
        sudo apt install -y \
            plasma-workspace || true
        ;;
    fedora)
        sudo dnf install -y \
            plasma-workspace || true
        ;;
    opensuse*|suse)
        sudo zypper install -y \
            plasma6-workspace || true
        ;;
    *)
        echo "⚠️ Unknown distribution: $DISTRO"
        echo "Please ensure KDE Plasma 6 is installed."
        ;;
esac

# --- Prepare install paths ---
INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"

# --- Install scripts ---
echo "📁 Installing scripts to $INSTALL_DIR..."
install -m 755 "$DIR/caffeine-status.sh" "$INSTALL_DIR/caffeine-status.sh"
install -m 755 "$DIR/caffeine-toggle.sh" "$INSTALL_DIR/caffeine-toggle.sh"
install -m 755 "$DIR/caffeine-lock-listener.sh" "$INSTALL_DIR/caffeine-lock-listener.sh"

# --- Install icons into user icon theme ---
ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"
mkdir -p "$ICON_DIR"
echo "🎨 Installing icons to $ICON_DIR..."
install -m 644 "$DIR/package/contents/icons/caffeine-cup-full.svg" "$ICON_DIR/caffeine-cup-full.svg"
install -m 644 "$DIR/package/contents/icons/caffeine-cup-empty.svg" "$ICON_DIR/caffeine-cup-empty.svg"
install -m 644 "$DIR/package/contents/icons/caffeine-cup-full.svg" "$ICON_DIR/bundledcaffeinecupfull.svg"
install -m 644 "$DIR/package/contents/icons/caffeine-cup-empty.svg" "$ICON_DIR/bundledcaffeinecupempty.svg"
# Update icon cache so Plasma picks up the new icons
if command -v gtk-update-icon-cache &>/dev/null; then
    gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
fi

# --- Install Plasma 6 Plasmoid ---
PLASMOID_ID="com.github.tesla.plasmacaffeine"
echo "📁 Installing/updating Plasma 6 Caffeine widget..."

if kpackagetool6 -t Plasma/Applet --list | grep -q "$PLASMOID_ID"; then
    echo "🔄 Upgrading existing widget installation..."
    kpackagetool6 -t Plasma/Applet --upgrade "$DIR/package"
else
    echo "📥 Installing new widget..."
    kpackagetool6 -t Plasma/Applet --install "$DIR/package"
fi

# --- Final instructions ---
echo
echo "✅ Installation complete!"
echo
echo "---------------------------------------"
echo "Plasma setup:"
echo "1️⃣ Right click on your panel and click 'Add Widgets...' (or 'Edit Mode' -> 'Add Widgets')."
echo "2️⃣ Search for 'Caffeine (systemd)' and drag it into your panel."
echo "3️⃣ Click on the coffee cup icon to toggle inhibit on or off."
echo "---------------------------------------"
echo
echo "Optional Plasma restart (if widget is not visible in list yet):"
echo "   systemctl --user restart plasma-plasmashell.service"
echo
